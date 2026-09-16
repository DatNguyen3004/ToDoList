# Cấu hình Supabase cho TDL

1. Tạo một dự án Supabase miễn phí.
2. Mở **SQL Editor** và chạy toàn bộ `setup.sql` trong thư mục này.
3. Trong Google Cloud, tạo OAuth Client loại **Web application**:
   - Authorized redirect URI: `https://PROJECT_REF.supabase.co/auth/v1/callback`.
   - Khi kiểm thử Web, thêm Authorized JavaScript origin `http://localhost:55524`.
4. Trong **Authentication > Providers > Google** của Supabase, bật Google rồi nhập Client ID/Client Secret ở bước trên.
5. Trong **Authentication > URL Configuration** của Supabase:
   - Site URL khi kiểm thử: `http://localhost:55524`.
   - Redirect URLs: thêm `http://localhost:55524/**` và `io.tdl.app://login-callback`.
6. Lấy Project URL và Publishable key trong bảng **Connect** của dự án.
7. Chạy ứng dụng bằng:

```powershell
flutter run -d chrome --web-port=55524 --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_KEY
```

Không đưa `service_role` key vào ứng dụng. TDL chỉ sử dụng publishable key; các chính sách RLS trong `setup.sql` bảo đảm mỗi tài khoản chỉ truy cập dữ liệu và hình ảnh của chính mình.
