from flask import Flask, render_template, redirect, url_for, flash, session, request
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import DataRequired, EqualTo
from flask_bootstrap import Bootstrap
import requests
import sqlite3

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your_secret_key'
Bootstrap(app)

class RegistrationForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired()])
    password = PasswordField('Password', validators=[DataRequired()])
    confirm_password = PasswordField('Confirm Password', validators=[DataRequired(), EqualTo('password')])
    submit = SubmitField('Register')

class LoginForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired()])
    password = PasswordField('Password', validators=[DataRequired()])
    submit = SubmitField('Login')

def init_db():
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        approved INTEGER NOT NULL
    )
    ''')
    # Add sample users
    cursor.execute("INSERT INTO users (username, password, approved) VALUES ('admin', '6irvw-wrgn3-94vse', 1)")
    cursor.execute("INSERT INTO users (username, password, approved) VALUES ('user1', 'uler4-own24-nwia2', 1)")
    cursor.execute("INSERT INTO users (username, password, approved) VALUES ('user2', 'hardtoguesspassword', 0)")
    conn.commit()
    conn.close()

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    form = RegistrationForm()
    if form.validate_on_submit():
        conn = sqlite3.connect('users.db')
        cursor = conn.cursor()
        cursor.execute("INSERT INTO users (username, password, approved) VALUES (?, ?, 0)", 
                       (form.username.data, form.password.data))
        conn.commit()
        conn.close()
        flash('Registration successful. Waiting for admin approval.', 'success')
        return redirect(url_for('login'))
    return render_template('register.html', form=form)

@app.route('/login', methods=['GET', 'POST'])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        conn = sqlite3.connect('users.db')
        cursor = conn.cursor()
        # Vulnerable SQL query for demonstration purposes
        query = f"SELECT * FROM users WHERE username='{form.username.data}' AND password='{form.password.data}' AND approved=1"
        try:
            cursor.execute(query)
            user = cursor.fetchone()
        except sqlite3.OperationalError as e:
            print(f"SQL error: {e}")
            user = None
        conn.close()
        if user:
            session['username'] = form.username.data
            flash('Login successful.', 'success')
            return redirect(url_for('profile'))
        else:
            flash('Invalid credentials or user not approved.', 'danger')
    return render_template('login.html', form=form)

@app.route('/profile')
def profile():
    if 'username' not in session:
        flash('You need to login first.', 'danger')
        return redirect(url_for('login'))
    return render_template('profile.html', username=session['username'])

@app.route('/ssrf', methods=['GET', 'POST'])
def ssrf():
    if 'username' not in session:
        flash('You need to login first.', 'danger')
        return redirect(url_for('login'))
    
    data = None
    if request.method == 'POST':
        url = request.form['url']
        try:
            response = requests.get(url)
            data = response.text
        except Exception as e:
            data = str(e)
    return render_template('ssrf.html', data=data)

@app.route('/logout')
def logout():
    session.pop('username', None)
    flash('You have been logged out.', 'success')
    return redirect(url_for('index'))

@app.route('/admin/approve')
def admin_approve():
    if 'username' not in session or session['username'] != 'admin':
        flash('You need to login as admin to access this page.', 'danger')
        return redirect(url_for('login'))
    
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE approved=0")
    users = cursor.fetchall()
    conn.close()
    return render_template('approval.html', users=users)

@app.route('/approve_user/<int:user_id>')
def approve_user(user_id):
    if 'username' not in session or session['username'] != 'admin':
        flash('You need to login as admin to access this page.', 'danger')
        return redirect(url_for('login'))

    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET approved=1 WHERE id=?", (user_id,))
    conn.commit()
    conn.close()
    flash('User approved successfully.', 'success')
    return redirect(url_for('admin_approve'))

if __name__ == '__main__':
    init_db()
    app.run(debug=True, host='0.0.0.0', port=8080)
