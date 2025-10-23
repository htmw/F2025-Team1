
import pandas as pd
import numpy as np
import xgboost as xgb
import joblib
from collections import Counter
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from imblearn.over_sampling import SMOTE
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score

# --- 1. Data Loading and Feature Engineering ---
print("1. Loading Data and Engineering 'Hour' Feature...")
data = pd.read_csv('creditcard.csv')

# Feature Engineering: Convert 'Time' (seconds elapsed) into 'Hour' (0-24)
data['Hour'] = data['Time'].apply(lambda x: (x / 3600) % 24)

# Separate features (X) and target (y)
X = data.drop(['Class', 'Time'], axis=1)
y = data['Class']

# --- 2. Scaling and Splitting ---
# Scale 'Amount' and the new 'Hour' feature
scaler = StandardScaler()
X[['Amount', 'Hour']] = scaler.fit_transform(X[['Amount', 'Hour']])
joblib.dump(scaler, 'scaler_sprint1.joblib') # Save scaler for API to use

# Split data: Stratify ensures the fraud ratio is preserved in test set
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# --- 3. Apply SMOTE to the Training Data ---
print("2. Applying SMOTE to the training data...")
sm = SMOTE(random_state=42, sampling_strategy='minority')
X_train_res, y_train_res = sm.fit_resample(X_train, y_train)

print(f"Original Train size: {len(X_train)}. Resampled Train size: {len(X_train_res)}")

# --- 4. Train Tuned XGBoost Classifier ---
print("3. Training XGBoost Classifier...")
# We use a strategic blend of SMOTE + implicit weighting (max_depth) for Sprint 1
model = xgb.XGBClassifier(
    objective='binary:logistic',
    n_estimators=100,
    learning_rate=0.1,
    max_depth=6, # Slight depth increase for better pattern capture
    use_label_encoder=False,
    eval_metric='logloss',
    tree_method='hist',
    random_state=42,
)

model.fit(X_train_res, y_train_res)
print("Training complete.")

# --- 5. Evaluation and Model Saving ---
print("\n4. Evaluation on Test Data (Real-world scenario)...")
y_pred = model.predict(X_test)
y_proba = model.predict_proba(X_test)[:, 1]

print("Confusion Matrix:")
print(confusion_matrix(y_test, y_pred))
print("\nClassification Report (Focus on Precision/Recall):")
print(classification_report(y_test, y_pred))
print(f"\nROC AUC Score: {roc_auc_score(y_test, y_proba):.4f}")

# Save the trained model
joblib.dump(model, 'xgboost_fraud_model_sprint1.joblib')
print("\nModel saved as 'xgboost_fraud_model_sprint1.joblib'.")