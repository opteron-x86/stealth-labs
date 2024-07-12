from flask import Flask, request, render_template, render_template_string
import subprocess

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/ping', methods=['GET', 'POST'])
def ping():
    result = None
    if request.method == 'POST':
        ip = request.form['ip']
        result = subprocess.check_output(f'ping -c 4 {ip}', shell=True).decode()
    return render_template('ping.html', result=result)

@app.route('/traceroute', methods=['GET', 'POST'])
def traceroute():
    result = None
    if request.method == 'POST':
        ip = request.form['ip']
        result = subprocess.check_output(f'traceroute {ip}', shell=True).decode()
    return render_template('traceroute.html', result=result)

@app.route('/dns_lookup', methods=['GET', 'POST'])
def dns_lookup():
    result = None
    if request.method == 'POST':
        domain = request.form['domain']
        result = subprocess.check_output(f'dig {domain}', shell=True).decode()
    return render_template('dns_lookup.html', result=result)

@app.route('/port_scan', methods=['GET', 'POST'])
def port_scan():
    result = None
    if request.method == 'POST':
        ip = request.form['ip']
        result = subprocess.check_output(f'nmap -sT {ip}', shell=True).decode()
    return render_template('port_scan.html', result=result)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8081)
