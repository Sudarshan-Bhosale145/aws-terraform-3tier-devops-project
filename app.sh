#!/bin/bash
# ===============================
# App EC2 Setup Script
# ===============================

# Install dependencies
sudo apt-get update -y
sudo apt-get install -y apache2 php php-mysql mysql-client unzip git

# Terraform-injected variables
DB_ENDPOINT="${db_endpoint}"
DB_USER="${db_username}"
DB_PASS="${db_password}"

# Wait until RDS is ready
until mysql -h $DB_ENDPOINT -u $DB_USER -p$DB_PASS -e "show databases;" >/dev/null 2>&1; do
  echo "Waiting for RDS MySQL to be ready..."
  sleep 10
done

echo "RDS is ready. Setting up database and tables..."

# Copy initial SQL schema
cat <<EOF > /home/ubuntu/init.sql
CREATE DATABASE IF NOT EXISTS mydb;
USE mydb;
CREATE TABLE IF NOT EXISTS registrations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    email VARCHAR(50),
    phone VARCHAR(15)
);
EOF

# Execute SQL to create DB and tables
mysql -h $DB_ENDPOINT -u $DB_USER -p$DB_PASS < /home/ubuntu/init.sql

# Setup Apache2 for PHP processing
sudo systemctl enable apache2
sudo systemctl restart apache2

# Deploy submit.php to handle form submissions from web tier
cat <<EOF > /var/www/html/submit.php
<?php
\$conn = new mysqli('$DB_ENDPOINT', '$DB_USER', '$DB_PASS', 'mydb');
if (\$conn->connect_error) { die("Connection failed: " . \$conn->connect_error); }

\$name = \$_POST['name'];
\$email = \$_POST['email'];
\$phone = \$_POST['phone'];

\$stmt = \$conn->prepare("INSERT INTO registrations (name,email,phone) VALUES (?, ?, ?)");
\$stmt->bind_param("sss", \$name, \$email, \$phone);
\$stmt->execute();

echo "Registration Successful!";

\$stmt->close();
\$conn->close();
?>
EOF

sudo chown www-data:www-data /var/www/html/submit.php
sudo chmod 644 /var/www/html/submit.php


echo "App EC2 setup complete."
# ===============================
# GUARANTEED submit.php creation FIX
# ===============================

sudo mkdir -p /var/www/html

cat <<'EOF' | sudo tee /var/www/html/submit.php > /dev/null
<?php
$conn = new mysqli('${db_endpoint}', '${db_username}', '${db_password}', 'mydb');

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$name = $_POST['name'];
$email = $_POST['email'];
$phone = $_POST['phone'];

$stmt = $conn->prepare("INSERT INTO registrations (name,email,phone) VALUES (?, ?, ?)");
$stmt->bind_param("sss", $name, $email, $phone);
$stmt->execute();

echo "Registration Successful!";

$stmt->close();
$conn->close();
?>
EOF

sudo chown www-data:www-data /var/www/html/submit.php
sudo chmod 644 /var/www/html/submit.php
