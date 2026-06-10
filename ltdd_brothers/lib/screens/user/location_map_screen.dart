import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/location_model.dart';
import '../../utils/app_colors.dart';

// Màn hình hiển thị vị trí của một địa danh trên bản đồ
class LocationMapScreen extends StatelessWidget {
  final LocationModel location;

  const LocationMapScreen({Key? key, required this.location}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LatLng pos = LatLng(location.latitude, location.longitude);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.text(context)),
        title: Text(
          location.name,
          style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: pos, zoom: 16),
        markers: {
          Marker(
            markerId: MarkerId(location.id.toString()),
            position: pos,
            infoWindow: InfoWindow(
              title: location.name,
              snippet: location.province,
            ),
          ),
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
      ),
    );
  }
}
