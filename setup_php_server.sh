#!/bin/bash

set -e

echo "=============================="
echo "🚀 Script Cài đặt Apache + PHP + SSL Let's Encrypt"
echo "=============================="

read -p "🌐 Nhập domain bạn muốn cài đặt (ví dụ: api.bloghong.com): " domain
if [[ -z "$domain" ]]; then
  echo "❌ Domain không được để trống. Vui lòng chạy lại script."
  exit 1
fi

read -p "📧 Nhập email của bạn để đăng ký SSL (Let's Encrypt sẽ gửi cảnh báo về email này): " user_email
if [[ -z "$user_email" ]]; then
  echo "❌ Email không được để trống. Vui lòng chạy lại script."
  exit 1
fi

echo "✅ Cập nhật hệ thống và cài đặt Apache + PHP..."
apt update -y && apt install apache2 php libapache2-mod-php curl unzip -y

echo "✅ Tạo file videos.php..."
mkdir -p /var/www/html
cat <<EOF > /var/www/html/videos.php
<?php
echo "Hello from videos.php";
?>
EOF

echo "✅ Cài đặt Certbot..."
apt install certbot python3-certbot-apache -y

echo "⚙️ Cấu hình VirtualHost cho domain $domain..."
cat <<EOL > /etc/apache2/sites-available/$domain.conf
<VirtualHost *:80>
    ServerName $domain
    DocumentRoot /var/www/html
</VirtualHost>
EOL

a2ensite $domain
systemctl reload apache2

echo "🔐 Gọi Certbot để tạo SSL..."
certbot --apache -d $domain --non-interactive --agree-tos -m $user_email

echo "🔁 Cấu hình Apache chuyển sang port 8080..."
sed -i 's/80/8080/g' /etc/apache2/ports.conf
sed -i 's/<VirtualHost \*:80>/<VirtualHost \*:8080>/g' /etc/apache2/sites-enabled/000-default.conf
sed -i 's/<VirtualHost \*:80>/<VirtualHost \*:8080>/g' /etc/apache2/sites-available/$domain.conf

echo "🔄 Restart Apache..."
if systemctl restart apache2; then
  echo "✅ Apache đã được khởi động lại thành công."
else
  echo "❌ Apache lỗi khi khởi động lại. Vui lòng kiểm tra cấu hình."
  exit 1
fi

echo "✅ Mở port 8080 trên tường lửa (nếu có)..."
ufw allow 8080 || true

echo "🎉 Cài đặt hoàn tất!"
echo "🔗 Truy cập thử: https://$domain:8080/videos.php"
