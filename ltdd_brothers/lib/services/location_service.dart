import 'dart:convert';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';

class LocationService {
  // =========================================================================
  // DÁN MAPILLARY TOKEN VÀO ĐÂY ĐỂ CÓ ẢNH THẬT CHO TAB LÂN CẬN.
  // Lấy miễn phí (KHÔNG cần thẻ): đăng nhập mapillary.com -> Settings ->
  // Developers -> Register application -> copy "Client token" (dạng MLY|...).
  // Để trống "" thì Lân cận dùng khung placeholder như hiện tại.
  static const String _mapillaryToken = 'MLY|36946932171558551|742dea52809d4765dc34a848f932d42f';
  // =========================================================================

  // 1. Hàm xin quyền và lấy tọa độ hiện tại
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // 2. Tìm địa điểm THẬT lân cận bằng OpenStreetMap Overpass API
  //    (miễn phí, không cần API key, không cần billing).
  //    'type' nhận: 'lodging' | 'restaurant' | 'tourist_attraction'
  Future<List<LocationModel>> getNearbyPlaces(double lat, double lng, String type) async {
    const int radius = 15000; // 15km

    // Bộ lọc OSM tương ứng từng danh mục
    String filter;
    switch (type) {
      case 'lodging':
        filter = 'node["tourism"~"hotel|hostel|guest_house|motel"]["name"](around:$radius,$lat,$lng);';
        break;
      case 'restaurant':
        filter = 'node["amenity"~"restaurant|cafe|fast_food"]["name"](around:$radius,$lat,$lng);';
        break;
      default: // tourist_attraction
        filter = 'node["tourism"~"attraction|museum|viewpoint|theme_park|zoo|artwork"]["name"](around:$radius,$lat,$lng);';
    }

    final query = '[out:json][timeout:25];($filter);out body 40;';

    // Dùng GET (ổn định hơn POST với Overpass) + User-Agent theo chuẩn OSM.
    // Thử lần lượt máy chủ chính rồi mirror nếu lỗi/bận.
    const servers = [
      'https://overpass-api.de/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
    ];
    const headers = {'User-Agent': 'ltdd_brothers/1.0 (do an mon hoc)'};

    http.Response? response;
    Object? lastError;
    for (final server in servers) {
      try {
        final uri = Uri.parse(server).replace(queryParameters: {'data': query});
        final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
        if (res.statusCode == 200) {
          response = res;
          break;
        }
        lastError = 'mã ${res.statusCode}';
      } catch (e) {
        lastError = e;
      }
    }

    if (response == null) {
      throw Exception('Máy chủ OpenStreetMap đang bận ($lastError). Vui lòng thử lại sau ít giây.');
    }

    final data = json.decode(response.body);
    final List elements = data['elements'] ?? [];

    // Tra ảnh THẬT đúng địa danh theo tên trên Wikipedia (1 lần gọi cho cả danh sách)
    final names = <String>[];
    for (final e in elements) {
      final n = e['tags']?['name'];
      if (n != null && n.toString().trim().isNotEmpty) names.add(n.toString());
    }
    // Tra Wikipedia cho nhóm "Địa danh/Tham quan" (khách sạn/quán ăn gần như không có bài)
    final wikiImages = type == 'tourist_attraction' ? await _fetchWikiImages(names) : <String, String>{};

    final List<LocationModel> places = [];
    for (final e in elements) {
      final tags = e['tags'] as Map<String, dynamic>?;
      if (tags == null) continue;
      final name = tags['name'];
      if (name == null || (name as String).trim().isEmpty) continue;

      final double pLat = (e['lat'] ?? lat).toDouble();
      final double pLng = (e['lon'] ?? lng).toDouble();

      // 1) ảnh trong tag OSM -> 2) ảnh thật đúng tên (Wikipedia)
      String img = _imageFromTags(tags);
      if (img.isEmpty) img = wikiImages[name.toLowerCase()] ?? '';

      places.add(LocationModel(
        id: (e['id'] ?? 0) is int ? e['id'] : 0,
        name: name,
        province: _shortAddress(tags),
        description: _buildDescription(tags, type, name),
        imageUrl: img,
        rating: 0.0,
        category: _viCategory(type),
        latitude: pLat,
        longitude: pLng,
      ));
    }

    // 3) Ảnh Mapillary chụp ngay tại từng địa điểm (cho nơi còn thiếu ảnh) -> 4) placeholder
    await _enrichMapillary(places);

    return places;
  }

  // Tra ảnh thật theo TÊN bằng TÌM KIẾM Wikipedia (không phân biệt hoa/thường),
  // có kiểm tra khớp tên để KHÔNG lấy nhầm ảnh không liên quan (vd ảnh chân dung).
  Future<Map<String, String>> _fetchWikiImages(List<String> names) async {
    final result = <String, String>{};
    final targets = names.toSet().take(20).toList();
    if (targets.isEmpty) return result;

    await Future.wait(targets.map((name) async {
      try {
        final uri = Uri.parse('https://vi.wikipedia.org/w/api.php').replace(queryParameters: {
          'action': 'query',
          'format': 'json',
          'generator': 'search',
          'gsrsearch': name,
          'gsrlimit': '1',
          'gsrnamespace': '0',
          'prop': 'pageimages',
          'piprop': 'thumbnail',
          'pithumbsize': '600',
          'redirects': '1',
        });
        final res = await http
            .get(uri, headers: {'User-Agent': 'ltdd_brothers/1.0 (do an mon hoc)'})
            .timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) return;
        final pages = json.decode(res.body)['query']?['pages'] as Map?;
        if (pages == null) return;
        for (final p in pages.values) {
          final title = (p['title'] ?? '').toString();
          final thumb = p['thumbnail']?['source'];
          if (thumb != null && _nameMatch(name, title)) {
            result[name.toLowerCase()] = thumb.toString();
          }
        }
      } catch (_) {}
    }));
    return result;
  }

  // Chỉ nhận ảnh khi tiêu đề Wikipedia khớp tên (tránh ảnh sai).
  bool _nameMatch(String osmName, String wikiTitle) {
    final a = osmName.trim().toLowerCase();
    final b = wikiTitle.trim().toLowerCase();
    if (a == b) return true;
    if (a.length >= 8 && b.contains(a)) return true; // tiêu đề chứa trọn tên
    return false;
  }

  // Lấy ảnh thật Mapillary cho các địa điểm còn thiếu ảnh (hỏi quanh TỪNG địa điểm).
  Future<void> _enrichMapillary(List<LocationModel> places) async {
    if (_mapillaryToken.isEmpty) return;
    // Giới hạn số lượng để không gọi quá nhiều
    final need = places.where((p) => p.imageUrl.isEmpty).take(24).toList();
    if (need.isEmpty) return;
    await Future.wait(need.map((p) async {
      final url = await _mapillaryNear(p.latitude, p.longitude);
      if (url != null) p.imageUrl = url;
    }));
  }

  // Hỏi Mapillary ảnh trong bán kính nhỏ (~200m) quanh 1 tọa độ, trả ảnh gần nhất.
  Future<String?> _mapillaryNear(double lat, double lng) async {
    try {
      const double d = 0.0018; // ~200m
      final bbox = '${lng - d},${lat - d},${lng + d},${lat + d}';
      final uri = Uri.parse('https://graph.mapillary.com/images').replace(queryParameters: {
        'access_token': _mapillaryToken,
        'fields': 'thumb_1024_url,computed_geometry',
        'bbox': bbox,
        'limit': '10',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final List imgs = json.decode(res.body)['data'] ?? [];
      double best = double.infinity;
      String? url;
      for (final im in imgs) {
        final coords = im['computed_geometry']?['coordinates'];
        final u = im['thumb_1024_url'];
        if (coords is List && coords.length >= 2 && u != null) {
          final dd = _distMeters(lat, lng, (coords[1] as num).toDouble(), (coords[0] as num).toDouble());
          if (dd < best) {
            best = dd;
            url = u.toString();
          }
        }
      }
      return url;
    } catch (_) {
      return null;
    }
  }

  double _distMeters(double lat1, double lon1, double lat2, double lon2) {
    const double m = 111320.0;
    final dLat = (lat2 - lat1) * m;
    final dLon = (lon2 - lon1) * m * math.cos(lat1 * math.pi / 180);
    return math.sqrt(dLat * dLat + dLon * dLon);
  }

  String _viCategory(String type) {
    switch (type) {
      case 'lodging':
        return 'Khách sạn';
      case 'restaurant':
        return 'Ăn uống';
      default:
        return 'Tham quan';
    }
  }

  // Lấy ảnh thật từ tag OSM nếu có (image hoặc wikimedia_commons), ngược lại trả rỗng
  String _imageFromTags(Map<String, dynamic> tags) {
    final img = tags['image'];
    if (img is String && (img.startsWith('http://') || img.startsWith('https://'))) {
      return img;
    }
    final wm = tags['wikimedia_commons'];
    if (wm is String && wm.startsWith('File:')) {
      return 'https://commons.wikimedia.org/wiki/Special:FilePath/${Uri.encodeComponent(wm.substring(5))}?width=600';
    }
    return '';
  }

  // Nhãn loại hình tiếng Việt theo tag OSM
  String _typeLabel(Map<String, dynamic> tags) {
    const map = {
      'hotel': 'Khách sạn', 'hostel': 'Nhà nghỉ (Hostel)', 'guest_house': 'Nhà khách', 'motel': 'Nhà nghỉ',
      'restaurant': 'Nhà hàng', 'cafe': 'Quán cà phê', 'fast_food': 'Đồ ăn nhanh',
      'attraction': 'Điểm tham quan', 'museum': 'Bảo tàng', 'viewpoint': 'Điểm ngắm cảnh',
      'theme_park': 'Công viên giải trí', 'zoo': 'Vườn thú', 'artwork': 'Tác phẩm nghệ thuật',
    };
    final key = tags['tourism'] ?? tags['amenity'];
    return map[key] ?? (key?.toString() ?? 'Địa điểm');
  }

  // Địa chỉ ngắn (đường + quận/thành phố) cho phần tiêu đề
  String _shortAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    final house = tags['addr:housenumber'];
    final street = tags['addr:street'];
    if (street != null) parts.add(house != null ? '$house $street' : street.toString());
    final city = tags['addr:district'] ?? tags['addr:suburb'] ?? tags['addr:city'];
    if (city != null) parts.add(city.toString());
    return parts.isEmpty ? 'Gần vị trí của bạn' : parts.join(', ');
  }

  // Địa chỉ đầy đủ
  String _fullAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    final house = tags['addr:housenumber'];
    final street = tags['addr:street'];
    if (street != null) parts.add(house != null ? '$house $street' : street.toString());
    for (final k in ['addr:suburb', 'addr:district', 'addr:city', 'addr:province']) {
      if (tags[k] != null) parts.add(tags[k].toString());
    }
    return parts.join(', ');
  }

  // Dựng phần "Giới thiệu" từ thông tin thật của địa điểm
  String _buildDescription(Map<String, dynamic> tags, String type, String name) {
    final lines = <String>[];

    // Nếu OSM có sẵn mô tả thì ưu tiên hiển thị
    final desc = tags['description:vi'] ?? tags['description'];
    if (desc != null && desc.toString().trim().isNotEmpty) {
      lines.add(desc.toString().trim());
    } else {
      lines.add('$name là ${_typeLabel(tags).toLowerCase()} nằm gần khu vực của bạn.');
    }

    lines.add('');
    lines.add('• Loại hình: ${_typeLabel(tags)}');

    final addr = _fullAddress(tags);
    if (addr.isNotEmpty) lines.add('• Địa chỉ: $addr');

    final cuisine = tags['cuisine'];
    if (cuisine != null) lines.add('• Ẩm thực: ${cuisine.toString().replaceAll('_', ' ').replaceAll(';', ', ')}');

    final stars = tags['stars'];
    if (stars != null) lines.add('• Hạng sao: $stars sao');

    final hours = tags['opening_hours'];
    if (hours != null) lines.add('• Giờ mở cửa: $hours');

    final phone = tags['phone'] ?? tags['contact:phone'];
    if (phone != null) lines.add('• Điện thoại: $phone');

    final web = tags['website'] ?? tags['contact:website'];
    if (web != null) lines.add('• Website: $web');

    return lines.join('\n');
  }
}
