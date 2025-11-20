import os
import random
import requests
from datetime import datetime
from typing import Dict, Any

import joblib
import numpy as np

# ================================================================
# 1. LIGHTWEIGHT .env LOADER (NO python-dotenv NEEDED)
# ================================================================

def load_env(path: str = ".env"):
    """
    Minimal .env loader: KEY=VALUE per line.
    Ignores blank lines and lines starting with '#'.
    """
    if not os.path.exists(path):
        # It's fine if there's no .env; we might be using real env vars
        return

    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            # Don't override existing env vars
            if key not in os.environ:
                os.environ[key] = value

# Load from project root .env
# (Make sure you run this script from the project root directory)
load_env(".env")

def _env(name: str) -> str:
    val = os.getenv(name)
    if not val:
        raise RuntimeError(f"Missing environment variable: {name}")
    return val


# ================================================================
# 2. ENV VARS + MODEL / SCALER PATHS
# ================================================================

EDGE_BASE_URL = _env("EDGE_BASE_URL")
EDGE_ADMIN_SECRET = _env("EDGE_ADMIN_SECRET")
USER_ID = _env("USER_ID")
CC_NUMBER = _env("CC_NUMBER")

MODEL_PATH = _env("MODEL_PATH")      # e.g. Code/xgboost_fraud_model_sprint1.joblib
SCALER_PATH = _env("SCALER_PATH")    # e.g. Code/scaler_sprint1.joblib

FRAUD_THRESHOLD = float(os.getenv("FRAUD_THRESHOLD", "0.5"))

print(f"🔄 Loading model from: {MODEL_PATH}")
MODEL = joblib.load(MODEL_PATH)

print(f"🔄 Loading scaler from: {SCALER_PATH}")
SCALER = joblib.load(SCALER_PATH)


# ================================================================
# 3. FEATURE VECTOR — MATCHES YOUR TRAINING PIPELINE
# ================================================================
# In train_model.py you did:
#   X = data.drop(['Class', 'Time'], axis=1)
# with columns: V1..V28, Amount, Hour
# You scaled Amount & Hour with SCALER.
# Here we can't reconstruct V1..V28 from live data, so we use zeros
# for V1..V28 and still scale [Amount, Hour] with the same scaler.
# ================================================================

def make_feature_vector(tx: Dict[str, Any]) -> np.ndarray:
    # 28 PCA features: V1..V28 -> we don't have them live, so zeros
    v_features = np.zeros(28, dtype=float)

    # Scale Amount & Hour using your saved scaler
    dummy = np.array([[tx["amount"], tx["hour"]]], dtype=float)
    scaled = SCALER.transform(dummy)
    scaled_amount = scaled[0, 0]
    scaled_hour = scaled[0, 1]

    full_vec = np.concatenate([v_features, [scaled_amount, scaled_hour]])
    return full_vec.reshape(1, -1)


def run_model(tx: Dict[str, Any]) -> Dict[str, Any]:
    X = make_feature_vector(tx)

    proba = float(MODEL.predict_proba(X)[0][1])
    fraud_flag = proba >= FRAUD_THRESHOLD

    return {
        "fraud_flag": fraud_flag,
        "fraud_reason": f"ML score={proba:.4f} (threshold={FRAUD_THRESHOLD})"
    }


# ================================================================
# 4. GENERATE SYNTHETIC TRANSACTION
# ================================================================

def generate_transaction() -> Dict[str, Any]:
    amount = int(round(random.uniform(5, 1500)))

    longitude = -74.5 + random.uniform(-0.3, 0.3)
    latitude = 40.5 + random.uniform(-0.3, 0.3)

    now = datetime.now()
    hour = now.hour

    return {
        "userId": USER_ID,
        "ccNumber": CC_NUMBER,
        "date": now.date().isoformat(),
        "time": now.time().isoformat(timespec="seconds"),
        "longitude": longitude,
        "latitude": latitude,
        "amount": amount,
        "hour": float(hour),
    }


# ================================================================
# 5. SEND TO SUPABASE EDGE FUNCTION
# ================================================================

def send_to_supabase(tx: Dict[str, Any], model_out: Dict[str, Any]):
    payload = {
        **tx,
        "fraud_flag": model_out["fraud_flag"],
        "fraud_reason": model_out["fraud_reason"],
    }

    print("=== PAYLOAD TO SUPABASE ===")
    print(payload)

    url = f"{EDGE_BASE_URL}/transactions"
    headers = {
        "Content-Type": "application/json",
        "x-admin-secret": EDGE_ADMIN_SECRET,
    }

    resp = requests.post(url, json=payload, headers=headers)
    print("Status:", resp.status_code)
    try:
        print("Response JSON:", resp.json())
    except Exception:
        print("Raw response:", resp.text)


# ================================================================
# 6. MAIN
# ================================================================

def main():
    tx = generate_transaction()
    print("Generated TX:", tx)

    model_out = run_model(tx)
    print("Model Output:", model_out)

    send_to_supabase(tx, model_out)


if __name__ == "__main__":
    main()
