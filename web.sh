#!/bin/bash
# ===============================
# Web EC2 Setup Script
# ===============================

# Install Nginx
sudo apt-get update -y
sudo apt-get install -y nginx

# Terraform-injected private IP of App EC2
APP_IP="${app_private_ip}"

# Create registration HTML form
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

<form action="http://$APP_IP/submit.php" method="post">

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

# Nginx configuration
sudo tee /etc/nginx/sites-available/default > /dev/null <<EOT
server {
    listen 80;

    root /var/www/html;

    location / {
        index index.html;
    }
}
EOT

sudo systemctl enable nginx
sudo systemctl restart nginx

echo "Web EC2 setup complete. Form available at http://<Web_EC2_Public_IP>"
