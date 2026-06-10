import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ĐỊA CHỈ BASE URL GỐC CỦA API
  final String _baseUrl = "http://10.0.2.2:5144/api/Users";

  // HÀM ẨN: HỎI MYSQL XEM TÀI KHOẢN CÓ BỊ KHÓA KHÔNG
  Future<bool> _isBannedInMySQL(String uid) async {
    try {
      // Gọi đúng endpoint: http://10.0.2.2:5144/api/Users/{id}
      final response = await http.get(Uri.parse("$_baseUrl/$uid"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isBanned'] ?? false; // Trả về true nếu bị khóa
      }
    } catch (e) {
      print("Lỗi check ban: $e");
    }
    return false;
  }

  // HÀM ẨN: GỌI API ĐỒNG BỘ XUỐNG MYSQL
  Future<void> _syncUserToBackend(String uid, String email, String name) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/sync"), // Gọi đúng endpoint: http://10.0.2.2:5144/api/Users/sync
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": uid,
          "email": email,
          "fullName": name,
        }),
      );
      print("Trạng thái đồng bộ MySQL: ${response.statusCode}");
    } catch (e) {
      print("Lỗi kết nối đến Backend: $e");
    }
  }

  // 1. HÀM ĐĂNG KÝ TÀI KHOẢN MỚI
  Future<User?> registerWithEmail(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Thành công Firebase -> Đồng bộ ngay xuống MySQL
      if (userCredential.user != null) {
        await _syncUserToBackend(userCredential.user!.uid, email, name);
      }

      return userCredential.user;
    } catch (e) {
      print("Lỗi đăng ký: $e");
      return null;
    }
  }

  // 2. HÀM ĐĂNG NHẬP BẰNG EMAIL/MẬT KHẨU (ĐÃ TÍCH HỢP CHẶN BAN)
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // --- KIỂM TRA TRẠNG THÁI KHÓA TÀI KHOẢN ---
      if (userCredential.user != null) {
        bool isBanned = await _isBannedInMySQL(userCredential.user!.uid);
        if (isBanned) {
          await logOut(); // Bị khóa -> Đăng xuất ngay lập tức sạch session
          throw Exception('BANNED'); // Ném cờ báo lỗi ra ngoài UI màn hình login
        }
      }

      return userCredential.user;
    } catch (e) {
      if (e.toString().contains('BANNED')) rethrow; // Đẩy tiếp cờ lỗi BANNED ra UI
      print("Lỗi đăng nhập: $e");
      return null;
    }
  }

  // 3. ĐĂNG XUẤT
  Future<void> logOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // 4. HÀM ĐĂNG NHẬP BẰNG GOOGLE (ĐÃ TÍCH HỢP CHẶN BAN)
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        String name = googleUser.displayName ?? "Người dùng Google";
        String email = googleUser.email;
        
        // Thành công Google -> Đồng bộ luôn xuống MySQL (nếu user chưa tồn tại)
        await _syncUserToBackend(userCredential.user!.uid, email, name);

        // --- KIỂM TRA TRẠNG THÁI KHÓA TÀI KHOẢN SAU KHI ĐỒNG BỘ ---
        bool isBanned = await _isBannedInMySQL(userCredential.user!.uid);
        if (isBanned) {
          await logOut(); // Bị khóa -> Đăng xuất ngay lập tức
          throw Exception('BANNED'); // Ném cờ báo lỗi ra ngoài UI màn hình login
        }
      }

      return userCredential.user;
    } catch (e) {
      if (e.toString().contains('BANNED')) rethrow; // Đẩy tiếp cờ lỗi BANNED ra UI
      print("Lỗi đăng nhập Google: $e");
      return null;
    }
  }
}