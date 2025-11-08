# api_service.py

from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import numpy as np

# Load the trained model and scaler
try:
    model = joblib.load('xgboost_fraud_model_sprint1.joblib')
    scaler = joblib.load('scaler_sprint1.joblib')
except FileNotFoundError:
    raise FileNotFoundError("Model or Scaler not found. Run train_model.py first!")

app = FastAPI(title="Real-Time Fraud Detection API (Sprint 1 Demo)")

# Define the input structure (28 PCA + Amount + Hour = 30 features)
class Transaction(BaseModel):
    # Features in order: V1..V28, Amount, Hour
    features: list[float]

@app.post("/predict_fraud/")
def predict_fraud(transaction: Transaction):
    
    input_data = np.array(transaction.features).reshape(1, -1)
    
    # Prediction and Probability
    prediction = model.predict(input_data)[0]
    probability = model.predict_proba(input_data)[0][1] # Probability of Fraud

    # Simple Sprint 1 Decision Logic:
    if prediction == 1 or probability > 0.7: 
        status = "FRAUDULENT - TRANSACTION BLOCKED"
        action = "Immediate Card Freeze Recommended"
    else:
        status = "LEGITIMATE - TRANSACTION APPROVED"
        action = "No action needed"

    return {
        "status": status,
        "prediction_score": f"{probability:.4f}",
        "action_required": action
    }