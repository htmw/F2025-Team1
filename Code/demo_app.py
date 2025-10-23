# demo_app.py

import streamlit as st
import requests
import numpy as np

# --- Configuration ---
API_ENDPOINT = "http://127.0.0.1:8000/predict_fraud/"

st.set_page_config(page_title="Sprint 1 Fraud Detection Demo", layout="wide")

st.title("💳 IT Architects: Real-Time Fraud Detection Demo (Sprint 1)")
st.caption("A functional prototype demonstrating real-time scoring via FastAPI.")
st.markdown("---")

# Use sliders to simulate input for the 30 features (V1-V28, Scaled Amount, Scaled Hour)
features = []
st.header("Simulate Transaction Features")

# Helper function for input - just for the demo, we use simplified inputs
def feature_input_section(start, end, label, min_val, max_val, step, default_val):
    st.subheader(label)
    for i in range(start, end + 1):
        features.append(st.slider(f'V{i}', min_val, max_val, default_val, step=step, key=f'V{i}'))

# V1-V10
col1, col2, col3 = st.columns(3)
with col1:
    feature_input_section(1, 10, "V1-V10 (PCA Features)", -5.0, 5.0, 0.1, 0.0)

# V11-V20
with col2:
    feature_input_section(11, 20, "V11-V20 (PCA Features)", -5.0, 5.0, 0.1, 0.0)

# V21-V28, Amount, Hour
with col3:
    feature_input_section(21, 28, "V21-V28 (PCA Features)", -5.0, 5.0, 0.1, 0.0)
    
    # Custom Features (Scaled)
    st.subheader("Engineered Features (Scaled)")
    features.append(st.slider('Amount (Scaled)', -2.0, 5.0, 0.0, step=0.1, key='Amount'))
    features.append(st.slider('Hour (Scaled)', -2.0, 2.0, 0.0, step=0.1, key='Hour'))

# --- Prediction Button ---
if st.button("RUN REAL-TIME FRAUD CHECK", type="primary"):
    # Send request to FastAPI
    transaction_data = {"features": features}
    
    try:
        response = requests.post(API_ENDPOINT, json=transaction_data)
        
        if response.status_code == 200:
            result = response.json()
            st.markdown("### 📢 Real-Time Alert & Decision")
            
            if "FRAUDULENT" in result['status']:
                st.error(f"🚨 **FRAUD ALERT!** Status: {result['status']}")
                st.warning(f"**Action Required:** {result['action_required']}")
            else:
                st.success(f"✅ **Transaction Approved.** Status: {result['status']}")
            
            st.info(f"Model Confidence Score (Fraud Probability): {result['prediction_score']}")

        else:
            st.error(f"API Error: Could not reach the scoring service. Status code: {response.status_code}")
            st.warning("Ensure the FastAPI service is running in Terminal 1.")

    except requests.exceptions.ConnectionError:
        st.error("Connection Error: The FastAPI service is not running. Please start it.")