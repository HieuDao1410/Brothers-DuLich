# HƯỚNG DẪN CHẠY ĐỒ ÁN — Nhóm Brothers

Ứng dụng Du lịch Việt Nam gồm **2 phần**: App Flutter (`ltdd_brothers`) + Backend ASP.NET (`VietNamTravelAPI`) + cơ sở dữ liệu MySQL.

---

## 1. CÀI ĐẶT (mỗi máy làm 1 lần)

| Phần mềm | Dùng để |
|---|---|
| **Flutter SDK** | Chạy app di động |
| **Android Studio** (kèm máy ảo Android) | Giả lập điện thoại |
| **.NET 8 SDK** | Chạy backend |
| **Visual Studio 2022** (hoặc VS Code) | Mở/chạy backend |
| **MySQL** (Server + Workbench) | Cơ sở dữ liệu |
| **Git** | Tải code về |

---

## 2. TẢI CODE VỀ
```
git clone https://github.com/HieuDao1410/Brothers-DuLich.git
```

---

## 3. CHẠY BACKEND (làm phần này TRƯỚC)

**B1. Tạo database rỗng** (mở MySQL Workbench, chạy lệnh):
```sql
CREATE DATABASE VietnamTravelDB;
```

**B2. Sửa kết nối MySQL** — mở `VietNamTravelAPI/appsettings.json`, đổi `User`/`Password` cho khớp MySQL **MÁY BẠN**:
```json
"DefaultConnection": "Server=localhost;Port=3306;Database=VietnamTravelDB;User=root;Password=MẬT_KHẨU_CỦA_BẠN;"
```

**B3. Tạo các bảng** — mở terminal trong thư mục `VietNamTravelAPI`, chạy:
```
dotnet ef database update
```
> Nếu báo lỗi thiếu công cụ: chạy `dotnet tool install --global dotnet-ef` rồi làm lại.

**B4. Chạy backend:**
```
dotnet run
```
> Hoặc mở `VietNamTravelAPI.sln` bằng Visual Studio 2022 → bấm nút **Run (▶)**.
> Backend chạy ở **http://localhost:5144**.

**B5. (Nên làm) Tạo dữ liệu địa danh mẫu:**
- Mở trình duyệt: `http://localhost:5144/swagger`
- Tìm **POST /api/Locations/seed** → **Try it out** → **Execute** → có sẵn 8 địa danh kèm ảnh.

---

## 4. CHẠY APP FLUTTER

**B1.** Mở thư mục `ltdd_brothers` bằng VS Code → mở terminal, chạy:
```
flutter pub get
```

**B2.** Mở **máy ảo Android** (trong Android Studio → Device Manager → ▶).

**B3.** Chạy app:
```
flutter run
```

---

## 5. TÀI KHOẢN ĐĂNG NHẬP
- **Người dùng thường:** bấm **Đăng ký** trong app để tạo tài khoản mới (qua Firebase).
- **Quản trị viên (Admin):** đăng nhập bằng email **`admin@gmail.com`** (đăng ký tài khoản này trước) → vào được trang Quản trị.

---

## ⚠️ LƯU Ý QUAN TRỌNG
1. **Bật backend TRƯỚC**, rồi mới chạy app.
2. App gọi backend qua `http://10.0.2.2:5144` → **chỉ đúng với MÁY ẢO Android** (không phải điện thoại thật).
3. Backend phải chạy đúng **port 5144**.
4. Mỗi người có **MySQL riêng trên máy mình** (dữ liệu không chung) — bình thường khi test.
5. Firebase, Google Maps, Mapillary token đã có sẵn trong code → **không cần chỉnh**.

---

## 🛠️ LỖI THƯỜNG GẶP
| Lỗi | Cách xử lý |
|---|---|
| `'dotnet ef' not found` | Chạy `dotnet tool install --global dotnet-ef` |
| `'flutter' / 'git' is not recognized` | Chưa cài/ chưa thêm vào PATH → cài lại |
| App báo "Không thể kết nối máy chủ" | Backend chưa chạy, hoặc sai port 5144 |
| Backend lỗi kết nối MySQL | Sai user/password trong `appsettings.json`, hoặc chưa tạo DB |
| Khám phá không có ảnh | Chưa chạy seed (Bước 3-B5) |
