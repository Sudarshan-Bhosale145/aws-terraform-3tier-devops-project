#!/bin/bash
# ===============================
# Web EC2 Setup Script (FIXED)
# ===============================

# Update & install required packages
sudo apt-get update -y
sudo apt-get install -y nginx php php-mysql

# Terraform-injected RDS variables
DB_ENDPOINT="${db_endpoint}"
DB_USER="${db_username}"
DB_PASS="${db_password}"

# -------------------------------
# Create Registration HTML Page
# -------------------------------
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
<title>Registration Form</title>
<style>
body {
    font-family: Arial;
    background-color: #f2f2f2;
}
.container {
    width: 400px;
    margin: 100px auto;
    background: white;
    padding: 20px;
    border-radius: 8px;
}
input {
    width: 100%;
    padding: 8px;
}
button {
    padding: 10px;
    width: 100%;
    background: green;
    color: white;
    border: none;
}
</style>
</head>
<body>

<div class="container">
<h2>Registration Form</h2>

<form action="http://10.0.175.192/submit.php" method="post">

<label>Name</label>
<input type="text" name="name" required><br><br>

<label>Email</label>
<input type="email" name="email" required><br><br>

<label>Phone</label>
<input type="text" name="phone" required><br><br>

<button type="submit">Register</button>

</form>

</div>

</body>
</html>
EOF

# -------------------------------
# Create submit.php on Web EC2
# -------------------------------
cat <<EOF > /var/www/html/submit.php
<?php
\$conn = new mysqli("$DB_ENDPOINT", "$DB_USER", "$DB_PASS", "mydb");
if (\$conn->connect_error) {
    die("Database connection failed");
}

\$name  = \$_POST['name'];
\$email = \$_POST['email'];
\$phone = \$_POST['phone'];

\$stmt = \$conn->prepare("INSERT INTO registrations (name,email,phone) VALUES (?, ?, ?)");
\$stmt->bind_param("sss", \$name, \$email, \$phone);
\$stmt->execute();

echo "<h2>Registration Successful</h2>";

\$stmt->close();
\$conn->close();
?>
EOF

sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# -------------------------------
# Nginx Configuration for PHP
# -------------------------------
sudo tee /etc/nginx/sites-available/default > /dev/null <<EOT
server {
    listen 80;
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    }
}
EOT

sudo systemctl restart nginx
sudo systemctl enable nginx

echo "Web EC2 setup complete. Access at: http://13.62.224.89"
