#!/bin/bash

# Wait for boot
sleep 60

# Install dependencies
apt update
apt install -y python3.12-venv python3-pip jq nmap
snap install aws-cli --classic

sleep 2

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data-iam-info"

# Format and mount the EBS volume
sudo mkfs -t ext4 /dev/nvme1n1
sudo mkdir /newvolume
sudo mount /dev/nvme1n1 /newvolume

# Create the sensitive data file
sudo touch /newvolume/aws_keys.txt
echo "AWS_ACCESS_KEY_ID=8BDD34C684507DA0AAD3B435B51404EE" | sudo tee /newvolume/aws_keys.txt
echo "AWS_SECRET_ACCESS_KEY=6218ae01ddd00f510418a217a67ac327d81b7f17"| sudo tee -a /newvolume/aws_keys.txt
echo "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEArEep...
-----END RSA PRIVATE KEY-----" | sudo tee -a /newvolume/aws_keys.txt

# Verify the file content
cat /newvolume/aws_keys.txt

# Delete the sensitive file
sudo rm /newvolume/aws_keys.txt

sudo rm -rf /newvolume

# Unmount the EBS volume
sudo umount /newvolume

aws ec2 detach-volume --volume-id vol-072f0679c8217523e

# Add canteen user
useradd -m -s /bin/bash canteen

# Create user flag
echo "16e8e8b09a3293690853eb66d0e0f081100bd372" > /home/canteen/user.txt
chown canteen:canteen /home/canteen/user.txt

# Create app directory
mkdir -p /opt/net_tools
touch /var/log/net_tools.log
chown canteen:canteen /var/log/net_tools.log
chown -R canteen:canteen /opt/net_tools
chmod -R 775 /opt/net_tools
cd /opt/net_tools
python3 -m venv venv
sleep 2
source venv/bin/activate
pip3 install flask boto3
sleep 2

cat << 'EOF' > /opt/net_tools/upload_logs.sh
#!/bin/bash

LOG_FILE="/var/log/net_tools.log"
S3_BUCKET="flask-app-templates"
S3_KEY="net_tools.log"

# Upload the log file to S3
aws s3 cp "${LOG_FILE}" "s3://${S3_BUCKET}/${S3_KEY}" --acl private

EOF

# Make the upload script executable
chmod +x /opt/net_tools/upload_logs.sh

# Schedule the cron job
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/net_tools/upload_logs.sh") | crontab -


# Fetch app.py from a secure location or repository
cat << 'EOF' > /opt/net_tools/app.py
from flask import Flask, request, jsonify
import subprocess
import boto3
import logging

# Set up logging
logging.basicConfig(filename='/var/log/net_tools.log', level=logging.INFO, format='%(asctime)s %(message)s')

app = Flask(__name__)

region_name = 'us-east-1'
s3_client = boto3.client('s3', region_name=region_name)
bucket_name = 'flask-app-templates'

def get_template(template_name):
    try:
        obj = s3_client.get_object(Bucket=bucket_name, Key=template_name)
        template_content = obj['Body'].read().decode('utf-8')
        app.logger.info(f"Fetched {template_name} from S3.")
        return template_content
    except Exception as e:
        app.logger.error(f"Error fetching {template_name} from S3: {e}")
        return "<h1>Template not found</h1>"

@app.route('/')
def index():
    template = get_template('index.html')
    app.logger.info(f"Accessed index page from {request.remote_addr}")
    return render_template_string(template)

@app.route('/ping', methods=['POST'])
def ping():
    ip = request.form['ip']
    result = subprocess.check_output(f'ping -c 4 {ip}', shell=True).decode()
    app.logger.info(f"{request.remote_addr} pinged IP: {ip}")
    return jsonify(result=result)

@app.route('/traceroute', methods=['POST'])
def traceroute():
    ip = request.form['ip']
    result = subprocess.check_output(f'traceroute {ip}', shell=True).decode()
    app.logger.info(f"{request.remote_addr} Tracerouted IP: {ip}")
    return jsonify(result=result)

@app.route('/dns_lookup', methods=['POST'])
def dns_lookup():
    domain = request.form['domain']
    result = subprocess.check_output(f'dig {domain}', shell=True).decode()
    app.logger.info(f"{request.remote_addr} sent DNS lookup for domain: {domain}")
    return jsonify(result=result)

@app.route('/port_scan', methods=['POST'])
def port_scan():
    ip = request.form['ip']
    result = subprocess.check_output(f'nmap -sT {ip}', shell=True).decode()
    app.logger.info(f"{request.remote_addr} port scanned IP: {ip}")
    return jsonify(result=result)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8081)
EOF

# Ensure the files are owned by the canteen user
chown -R canteen:canteen /opt/net_tools/*

sleep 2

# Create systemd service
cat << 'EOF' > /etc/systemd/system/net_tools_app.service
[Unit]
Description=Network Diagnostic Tools for Network Admins
After=network.target

[Service]
User=canteen
WorkingDirectory=/opt/net_tools
ExecStart=/opt/net_tools/venv/bin/python /opt/net_tools/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sleep 2

# Start and enable the service
systemctl daemon-reload
systemctl enable net_tools_app.service
systemctl start net_tools_app.service