#!/bin/bash

set -e

echo "✅ Cập nhật hệ thống và cài đặt Apache + PHP..."
apt update -y && apt install apache2 php libapache2-mod-php curl unzip -y

echo "✅ Tạo file videos.php..."
mkdir -p /var/www/html
cat <<EOF > /var/www/html/videos.php
<?php
echo "Hello from videos.php";
?>
EOF

echo "✅ Cấu hình Apache chạy port 8080..."
sed -i 's/80/8080/g' /etc/apache2/ports.conf
sed -i 's/<VirtualHost \*:80>/<VirtualHost \*:8080>/g' /etc/apache2/sites-enabled/000-default.conf

echo "✅ Restart Apache..."
systemctl restart apache2

echo "✅ Mở port 8080 trên tường lửa (nếu có)..."
ufw allow 8080 || true

echo "✅ Cài đặt Certbot và cấp SSL cho domain api.bloghong.com..."
apt install certbot python3-certbot-apache -y

echo "⚠️ Cấu hình VirtualHost để Certbot nhận diện domain..."
cat <<EOL > /etc/apache2/sites-available/api.bloghong.com.conf
<VirtualHost *:80>
    ServerName api.bloghong.com
    DocumentRoot /var/www/html
</VirtualHost>
EOL

a2ensite api.bloghong.com
systemctl reload apache2

echo "🔐 Gọi Certbot để tạo SSL..."
certbot --apache -d api.bloghong.com --non-interactive --agree-tos -m you@example.com

echo "🎉 Hoàn tất! Truy cập: https://api.bloghong.com:8080/videos.php"
