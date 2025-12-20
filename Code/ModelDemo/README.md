# ModelDemo: `transaction_generator.py`

This folder contains a small demo script (`transaction_generator.py`) that:

1. Generates a synthetic transaction (amount + geo + timestamp)
2. Runs the saved fraud model locally (`joblib`)
3. POSTs the transaction to the Supabase Edge Function `/transactions`
4. If flagged as fraud, POSTs to the Supabase Edge Function `/notify` to send a push notification

## Prerequisites

- Python 3.10+
- Required Python packages (minimum):
  - `requests`
  - `numpy`
  - `joblib`
  - whatever your model requires at runtime (e.g., `xgboost` if your model is an XGBoost classifier)
- Supabase Edge Function deployed with these routes:
  - `POST /transactions`
  - `POST /notify`
- For `/notify` to actually reach devices:
  - `public.pns` table exists and contains at least one active token row for the `USER_ID`
  - `PUSHY_SECRET_KEY` is configured for the Edge Function

## Environment Variables

`transaction_generator.py` loads env vars from a `.env` file in the **project root** (`Code/.env`) and/or from your shell environment.

Required variables:

- `EDGE_BASE_URL`  
  - Base URL of your edge middleware (example: `https://<project>.supabase.co/functions/v1/app-middleware`)
- `EDGE_ADMIN_SECRET`  
  - Must match the Edge Function `EDGE_ADMIN_SECRET` (and the iOS app’s configured value)
- `USER_ID`  
  - The Supabase `Users.id` for the user to attach transactions/notifications to
- `CC_NUMBER`  
  - A credit card number string used in the generated transaction
- `MODEL_PATH`  
  - Path to your saved model `.joblib`
- `SCALER_PATH`  
  - Path to your saved scaler `.joblib`

Optional:

- `FRAUD_THRESHOLD` (default `0.5`)

### Example `.env`

Create or update `Code/.env`:

```bash
EDGE_BASE_URL=https://<project>.supabase.co/functions/v1/app-middleware
EDGE_ADMIN_SECRET=edge_admin@3333

USER_ID=deb92102-1adb-4be9-8460-f893ea521495
CC_NUMBER=4111111111111111

MODEL_PATH=Code/xgboost_fraud_model_sprint1.joblib
SCALER_PATH=Code/scaler_sprint1.joblib

FRAUD_THRESHOLD=0.5
```

## Run

From the project root (`Code/`):

```bash
python3 ModelDemo/transaction_generator.py
```

## What to Expect

- The script prints:
  - The generated transaction fields
  - The model output (`fraud_flag`, `fraud_reason`)
  - The payload sent to Supabase
  - HTTP status + response bodies for `/transactions`
  - If fraud: HTTP status + response bodies for `/notify`

## Notes / Troubleshooting

- If you see `Missing environment variable: ...`, add it to `Code/.env` or export it in your shell.
- If `/notify` returns “No active device tokens for user”, register a device token into `public.pns` for that `USER_ID`.
- The model feature vector uses `V1..V28 = 0` and only scales `Amount` and `Hour` to match the training pipeline. This is for demo/testing only.


