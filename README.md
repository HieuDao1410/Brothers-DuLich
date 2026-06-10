# Ứng dụng Du lịch Việt Nam — Nhóm Brothers

Đồ án môn **Lập trình thiết bị di động**. Ứng dụng giới thiệu, quảng bá, tìm kiếm các địa danh du lịch ở Việt Nam.

## Cấu trúc repo
- `ltdd_brothers/` — Ứng dụng di động (Flutter / Dart).
- `VietNamTravelAPI/` — Máy chủ Web API (ASP.NET Core 8, C#) + MySQL.

## Công nghệ
- Client: Flutter, Provider, SQLite (sqflite), image_picker, google_maps_flutter, geolocator, shared_preferences, http.
- Server: ASP.NET Core 8 Web API, Entity Framework Core 8 + Pomelo MySQL.
- Xác thực: Firebase Authentication. Lưu ảnh: thư mục tĩnh `wwwroot/images`.
- Ảnh địa điểm Lân cận: Wikipedia + Mapillary (đường phố thật).

## Cách chạy
### 1) Backend (Visual Studio 2022)
- Cài MySQL, tạo database `VietnamTravelDB` (xem chuỗi kết nối trong `VietNamTravelAPI/appsettings.json`).
- Tạo bảng: `dotnet ef database update` → chạy `dotnet run`.
- (Tùy chọn) Mở `http://localhost:5144/swagger` → **POST /api/Locations/seed** để có dữ liệu địa danh mẫu.

### 2) Ứng dụng (VS Code + máy ảo Android)
- Mở `ltdd_brothers` → `flutter pub get` → `flutter run`.
- Máy ảo gọi backend qua `http://10.0.2.2:5144`.

## Bảng phân công

| Người | Phụ trách | File chính |
|---|---|---|
| **Đào Văn Hiếu** (nhóm trưởng) | **Khám phá, Lân cận, Bản đồ & Quản lý Địa danh** + tổng hợp | `home_screen`, `nearby_screen`, `detail_screen`, `location_map_screen`, `location_service`, `favorite_screen`, `admin/manage_locations`, `admin/add_location` · `LocationsController` |
| **Lê Quốc Trung** | Mạng xã hội & Quản trị | `community_screen`, `create_post_screen`, `comments_screen`, `community_service`, `admin/admin_dashboard`, `admin/manage_users`, `admin/moderate_posts`, `admin/moderate_reviews` · `PostsController` |
| **Nguyễn Đặng Vĩnh Khang** | Tài khoản & Giao diện | `auth/login_screen`, `auth/register_screen`, `auth_service`, `profile_screen`, `theme_provider`, `utils/app_colors`, `utils/location_placeholder` · `UsersController` |
| **Nguyễn Ngọc Quý** | Đánh giá & Lịch trình | `review_screen`, `location_reviews_screen`, `review_service`, `schedule_screen`, `trip_provider`, `local_db`, `schedule_service` · `ReviewsController`, `SchedulesController` |

## Các chức năng
**Người dùng:** Đăng ký/Đăng nhập · Khám phá (tìm kiếm) · Lân cận (bản đồ + địa điểm thật + ảnh) · Lịch trình (offline + đồng bộ) · Mạng xã hội (đăng bài/like/bình luận) · Đánh giá (1–5 sao) · Hồ sơ & Dark mode.

**Quản trị viên:** Dashboard thống kê · Quản lý Địa danh (CRUD + ảnh) · Kiểm duyệt Đánh giá/Bài đăng · Quản lý Tài khoản.

## Cơ sở dữ liệu (MySQL) — 7 bảng
`Users`, `Locations`, `Reviews`, `Schedules`, `Posts`, `Comments`, `PostLikes`.
