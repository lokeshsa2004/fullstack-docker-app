"""Flask application for serving frontend templates"""
from flask import Flask, render_template, send_from_directory
import os

app = Flask(__name__, 
    template_folder=os.path.join(os.path.dirname(__file__), '..', 'frontend', 'templates'),
    static_folder=os.path.join(os.path.dirname(__file__), '..', 'frontend', 'static'),
    static_url_path='/static'
)

@app.route('/')
def home():
    """Render home page"""
    return render_template('home.html')

@app.route('/dashboard')
def dashboard():
    """Render dashboard page"""
    return render_template('dashboard.html')

@app.route('/about')
def about():
    """Render about page"""
    return render_template('about.html')

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return render_template('404.html'), 404

if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=5000)
