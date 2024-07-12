#!/bin/bash

sleep 60

echo "Broker VM Setup Script"

sudo su

# Update and install dependencies
apt update && apt install -y openjdk-11-jre nginx wget unzip

# Download and extract ActiveMQ
wget https://archive.apache.org/dist/activemq/5.15.15/apache-activemq-5.15.15-bin.tar.gz
tar -xf apache-activemq-5.15.15-bin.tar.gz
mv apache-activemq-5.15.15 /opt

sleep 2

# Configure ActiveMQ
sed -i 's/createConnector(bindAddress)/createConnector(bindAddress).setName("stomp")/' /opt/apache-activemq-5.15.15/conf/activemq.xml

sleep 2

# Add activemq user 
useradd -m -s /bin/bash activemq
echo 'activemq ALL=(ALL) NOPASSWD: /usr/sbin/nginx' | sudo tee /etc/sudoers.d/activemq

sleep 2

# Create ActiveMQ systemd service
cat << EOF > /etc/systemd/system/activemq.service
[Unit]
Description=Apache ActiveMQ
After=network.target

[Service]
Type=forking
User=activemq
Group=activemq
ExecStart=/opt/apache-activemq-5.15.15/bin/activemq start
ExecStop=/opt/apache-activemq-5.15.15/bin/activemq stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

sleep 2

# Nginx configuration (to proxy ActiveMQ web interface)
cat << EOF > /etc/nginx/sites-available/activemq
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://localhost:8161;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

sleep 2

chown -R activemq:activemq /opt/apache-activemq-5.15.15/data

ln -s /etc/nginx/sites-available/activemq /etc/nginx/sites-enabled/

sleep 2

# Enable and start ActiveMQ
systemctl daemon-reload
systemctl enable activemq
systemctl start activemq
systemctl restart nginx

# Create user flag
echo "16e8e8b09a3293690853eb66d0e0f081100bd372" > /home/activemq/user.txt
chown activemq:activemq /home/activemq/user.txt

# Create root flag
echo "de576edd1215f2c88e233a9352b87317454699be" > /root/root.txt
chmod 600 /root/root.txt

echo "Broker setup is complete! ActiveMQ is running on port 8161 (web interface is proxied to port 80)."