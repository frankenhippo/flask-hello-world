# app/streamlit_app.py
import streamlit as st
import os
import socket
from datetime import datetime
import pandas as pd
import numpy as np

# Page configuration
st.set_page_config(
    page_title="Hello World App",
    page_icon="👋",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Configuration from environment variables
CONFIG = {
    'environment': os.environ.get('ENVIRONMENT', 'development'),
    'app_name': os.environ.get('APP_NAME', 'hello-world-app'),
    'version': '1.0.0',
    'hostname': socket.gethostname()
}

# Sidebar with app information
with st.sidebar:
    st.title("App Information")
    st.info(f"**Environment:** {CONFIG['environment']}")
    st.info(f"**Version:** {CONFIG['version']}")
    st.info(f"**Hostname:** {CONFIG['hostname']}")
    st.info(f"**Timestamp:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

# Main content
st.title("👋 Hello, World!")
st.markdown(f"Welcome to **{CONFIG['app_name']}** running in **{CONFIG['environment']}** environment!")

# Tabs for different sections
tab1, tab2, tab3, tab4 = st.tabs(["Home", "Data Demo", "Environment", "Health Check"])

with tab1:
    st.header("Welcome!")
    st.write("This is a sample Streamlit application that demonstrates:")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Features")
        st.markdown("""
        - 🚀 Deployed on Google Cloud Run
        - 🏗️ Built with Terraform
        - 🔄 CI/CD with Cloud Build
        - 📊 Interactive Streamlit UI
        - 🔧 Environment-specific configuration
        """)
    
    with col2:
        st.subheader("Quick Stats")
        st.metric("Environment", CONFIG['environment'])
        st.metric("Version", CONFIG['version'])
        st.metric("Current Time", datetime.now().strftime('%H:%M:%S'))

with tab2:
    st.header("📊 Data Visualization Demo")
    
    # Generate sample data
    np.random.seed(42)
    chart_data = pd.DataFrame({
        'Day': range(1, 31),
        'Users': np.random.randint(100, 1000, 30),
        'Revenue': np.random.randint(1000, 5000, 30)
    })
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Daily Users")
        st.line_chart(chart_data.set_index('Day')['Users'])
    
    with col2:
        st.subheader("Daily Revenue")
        st.bar_chart(chart_data.set_index('Day')['Revenue'])
    
    st.subheader("Raw Data")
    st.dataframe(chart_data, use_container_width=True)
    
    # Interactive widgets
    st.subheader("Interactive Controls")
    user_input = st.text_input("Enter your name:", "World")
    slider_value = st.slider("Select a value:", 0, 100, 50)
    
    if st.button("Generate Greeting"):
        st.success(f"Hello, {user_input}! Your selected value is {slider_value}.")

with tab3:
    st.header("🔧 Environment Information")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Configuration")
        config_df = pd.DataFrame([
            {"Key": "App Name", "Value": CONFIG['app_name']},
            {"Key": "Environment", "Value": CONFIG['environment']},
            {"Key": "Version", "Value": CONFIG['version']},
            {"Key": "Hostname", "Value": CONFIG['hostname']},
        ])
        st.dataframe(config_df, use_container_width=True, hide_index=True)
    
    with col2:
        st.subheader("System Information")
        import sys
        system_df = pd.DataFrame([
            {"Key": "Python Version", "Value": sys.version.split()[0]},
            {"Key": "Streamlit Version", "Value": st.__version__},
            {"Key": "Platform", "Value": sys.platform},
        ])
        st.dataframe(system_df, use_container_width=True, hide_index=True)
    
    # Environment variables (filtered for security)
    st.subheader("Environment Variables")
    env_vars = {
        key: value for key, value in os.environ.items() 
        if not any(secret in key.upper() for secret in ['SECRET', 'PASSWORD', 'KEY', 'TOKEN', 'CREDENTIAL'])
    }
    
    if env_vars:
        env_df = pd.DataFrame([
            {"Variable": key, "Value": value} 
            for key, value in sorted(env_vars.items())
        ])
        st.dataframe(env_df, use_container_width=True, hide_index=True)
    else:
        st.info("No environment variables to display (security filtered)")

with tab4:
    st.header("🏥 Health Check")
    
    # Simulate health check
    health_status = {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "environment": CONFIG['environment'],
        "version": CONFIG['version'],
        "hostname": CONFIG['hostname']
    }
    
    st.success("✅ Application is healthy!")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.json(health_status)
    
    with col2:
        st.subheader("Health Metrics")
        # Simulate some metrics
        st.metric("Response Time", "< 100ms", delta="-5ms")
        st.metric("Memory Usage", "45%", delta="2%")
        st.metric("CPU Usage", "12%", delta="-1%")
    
    if st.button("Run Health Check"):
        with st.spinner("Running health check..."):
            import time
            time.sleep(1)  # Simulate check time
            st.balloons()
            st.success("Health check completed successfully!")

# Footer
st.markdown("---")
st.markdown(
    f"<div style='text-align: center; color: gray;'>"
    f"Powered by Streamlit • Running on Google Cloud Run • {CONFIG['environment'].title()} Environment"
    f"</div>",
    unsafe_allow_html=True
)
