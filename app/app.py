# app/app.py
import os
import logging
from flask import Flask, jsonify, request
from datetime import datetime
import socket

# Configure logging
logging.basicConfig(
    level=getattr(logging, os.environ.get('LOG_LEVEL', 'INFO')),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration from environment variables
CONFIG = {
    'environment': os.environ.get('ENVIRONMENT', 'development'),
    'app_name': os.environ.get('APP_NAME', 'hello-world-app'),
    'version': '1.0.0',
    'hostname': socket.gethostname()
}

@app.route('/')
def hello():
    """Main hello world endpoint"""
    logger.info(f"Hello world request from {request.remote_addr}")
    
    return jsonify({
        'message': 'Hello, World!',
        'app_name': CONFIG['app_name'],
        'environment': CONFIG['environment'],
        'version': CONFIG['version'],
        'hostname': CONFIG['hostname'],
        'timestamp': datetime.utcnow().isoformat() + 'Z'
    })

@app.route('/health')
def health_check():
    """Health check endpoint for load balancer"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'environment': CONFIG['environment'],
        'version': CONFIG['version']
    }), 200

@app.route('/info')
def info():
    """Information endpoint"""
    return jsonify({
        'app_name': CONFIG['app_name'],
        'environment': CONFIG['environment'],
        'version': CONFIG['version'],
        'hostname': CONFIG['hostname'],
        'python_version': os.sys.version,
        'environment_variables': {
            key: value for key, value in os.environ.items() 
            if not key.startswith(('SECRET', 'PASSWORD', 'KEY', 'TOKEN'))
        }
    })

@app.route('/status')
def status():
    """Status endpoint with more detailed information"""
    return jsonify({
        'status': 'running',
        'uptime': 'Available on restart',  # Could implement actual uptime tracking
        'environment': CONFIG['environment'],
        'version': CONFIG['version'],
        'hostname': CONFIG['hostname'],
        'request_info': {
            'method': request.method,
            'url': request.url,
            'remote_addr': request.remote_addr,
            'user_agent': request.headers.get('User-Agent', 'Unknown')
        }
    })

@app.errorhandler(404)
def not_found(error):
    """404 error handler"""
    logger.warning(f"404 error for path: {request.path}")
    return jsonify({
        'error': 'Not Found',
        'message': f'The requested URL {request.path} was not found.',
        'status_code': 404
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """500 error handler"""
    logger.error(f"500 error: {str(error)}")
    return jsonify({
        'error': 'Internal Server Error',
        'message': 'An internal server error occurred.',
        'status_code': 500
    }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    logger.info(f"Starting {CONFIG['app_name']} on port {port}")
    logger.info(f"Environment: {CONFIG['environment']}")
    logger.info(f"Version: {CONFIG['version']}")
    
    app.run(
        host='0.0.0.0',
        port=port,
        debug=CONFIG['environment'] == 'development'
    )
