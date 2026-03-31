import joblib
import numpy as np
import pandas as pd

# Load the saved model and scaler
model_filename = "system_risk_model.pkl"
scaler_filename = "scaler.pkl"

try:
    loaded_model = joblib.load(model_filename)
    scaler = joblib.load(scaler_filename)
    print(f"Model and Scaler loaded successfully.")
except FileNotFoundError:
    print(f"Error: Model or Scaler file not found. Please train the model first.")
    exit()

# Define test inputs: [CPU, RAM, Disk, Net, Temp, Errors]
test_inputs = [
    [15, 20, 10, 5, 35, 0],   # Safe
    [65, 75, 50, 40, 60, 1],  # Warning (High RAM)
    [95, 90, 80, 70, 80, 0],  # Critical (High CPU/RAM)
    [30, 30, 90, 20, 40, 0],  # Warning (High Disk)
    [40, 40, 20, 10, 90, 0],  # Critical (High Temp)
    [20, 20, 20, 10, 40, 10]  # Critical (High Errors)
]

print("\n--- System Risk Predictions ---")
print(f"{'CPU':<5} | {'RAM':<5} | {'Disk':<5} | {'Net':<5} | {'Temp':<5} | {'Err':<3} | {'Prediction':<10}")
print("-" * 65)

risk_map = {0: 'Safe', 1: 'Warning', 2: 'Critical'}

for input_data in test_inputs:
    # Predict
    # Create DataFrame to match training context
    df_input = pd.DataFrame([input_data], columns=['cpu_usage', 'ram_usage', 'disk_usage', 'network_utilization', 'system_temperature', 'error_count'])
    
    # Scale input
    input_scaled = scaler.transform(df_input)
    
    prediction = loaded_model.predict(input_scaled)
    risk_class = int(prediction[0])
    
    status = risk_map.get(risk_class, "Unknown")
    
    print(f"{input_data[0]:<5} | {input_data[1]:<5} | {input_data[2]:<5} | {input_data[3]:<5} | {input_data[4]:<5} | {input_data[5]:<3} | {status:<10}")

print("\n-------------------------------")
