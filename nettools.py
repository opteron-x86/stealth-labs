from flask import Flask, request, render_template_string
import subprocess

app = Flask(__name__)

@app.route('/')
def index():
    return '''
        <h1>Free Net Tools</h1>
        <p>Use these tools to diagnose your network issues.</p>
        <ul>
            <li><a href="/ping">Ping</a></li>
            <li><a href="/traceroute">Traceroute</a></li>
        </ul>
    '''

@app.route('/ping', methods=['GET', 'POST'])
def ping():
    if request.method == 'POST':
        ip = request.form['ip']
        result = subprocess.check_output(f'ping -c 1 {ip}', shell=True)
        return render_template_string('''
            <h1>Ping Result</h1>
            <pre>{{result}}</pre>
            <a href="/ping">Go Back</a>
        ''', result=result.decode())
    return '''
        <h1>Ping</h1>
        <form method="post">
            IP Address: <input type="text" name="ip">
            <input type="submit" value="Ping">
        </form>
    '''

@app.route('/traceroute', methods=['GET', 'POST'])
def traceroute():
    if request.method == 'POST':
        ip = request.form['ip']
        result = subprocess.check_output(f'traceroute {ip}', shell=True)
        return render_template_string('''
            <h1>Traceroute Result</h1>
            <pre>{{result}}</pre>
            <a href="/traceroute">Go Back</a>
        ''', result=result.decode())
    return '''
        <h1>Traceroute</h1>
        <form method="post">
            IP Address: <input type="text" name="ip">
            <input type="submit" value="Traceroute">
        </form>
    '''

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
