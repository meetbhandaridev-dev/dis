import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
import joblib
import os

# Create dummy data for System Monitoring
# Input Features:
# - CPU Usage (%)
# - RAM Usage (%)
# - Disk Usage (%)
# - Network Utilization (%)
# - System Temperature (°C)
# - Error Count
# Output Classes:
# - 0: Safe
# - 1: Warning
# - 2: Critical

np.random.seed(42)
num_samples = 1000

# Generate random features
cpu_usage = np.random.randint(0, 101, num_samples)
ram_usage = np.random.randint(10, 101, num_samples)
disk_usage = np.random.randint(10, 100, num_samples)
network_utilization = np.random.randint(0, 101, num_samples)
system_temperature = np.random.randint(20, 100, num_samples)
error_count = np.random.poisson(1, num_samples)

# Artificial injection of high error scenarios to ensure model learns this pattern
# Set 5% of samples to have high errors (6-15)
high_error_indices = np.random.choice(num_samples, size=int(num_samples * 0.05), replace=False)
error_count[high_error_indices] = np.random.randint(6, 15, size=len(high_error_indices))

# Define ground truth logic for classification
def determine_risk(row):
    # Critical conditions
    if (row['cpu_usage'] > 90) or \
       (row['ram_usage'] > 90) or \
       (row['system_temperature'] > 85) or \
       (row['error_count'] > 5):
        return 2 # Critical
    
    # Warning conditions
    if (row['cpu_usage'] > 70) or \
       (row['ram_usage'] > 70) or \
       (row['disk_usage'] > 85) or \
       (row['system_temperature'] > 70) or \
       (row['error_count'] > 2):
        return 1 # Warning
        
    # Safe
    return 0

data = {
    'cpu_usage': cpu_usage,
    'ram_usage': ram_usage,
    'disk_usage': disk_usage,
    'network_utilization': network_utilization,
    'system_temperature': system_temperature,
    'error_count': error_count
}

df = pd.DataFrame(data)
# Apply logic to create target variable
df['risk_class'] = df.apply(determine_risk, axis=1)

from sklearn.preprocessing import StandardScaler
from sklearn.impute import SimpleImputer
from sklearn.pipeline import Pipeline

# --- Data Contamination (Introducing Issues for Cleaning) ---
# Introduce some missing values (NaN)
nan_indices = np.random.choice(num_samples, size=int(num_samples * 0.05), replace=False)
df.loc[nan_indices, 'cpu_usage'] = np.nan

# Introduce some invalid data (Negative values)
invalid_indices = np.random.choice(num_samples, size=int(num_samples * 0.02), replace=False)
df.loc[invalid_indices, 'ram_usage'] = -10

# Introduce some extreme outliers
outlier_indices = np.random.choice(num_samples, size=int(num_samples * 0.01), replace=False)
df.loc[outlier_indices, 'system_temperature'] = 500  # Impossible high temp

print("Original Data Shape (with noise):", df.shape)

# --- Data Cleaning & Preprocessing ---

# 1. Handle Missing Values (Imputation)
# Fill NaN CPU usage with the median value
imputer = SimpleImputer(strategy='median')
df['cpu_usage'] = imputer.fit_transform(df[['cpu_usage']])

# 2. Remove Invalid Data
# CPU, RAM, Disk, Network cannot be negative
# System Temp usually between 0 and 120 (for active systems)
df = df[
    (df['cpu_usage'] >= 0) & 
    (df['ram_usage'] >= 0) & 
    (df['disk_usage'] >= 0) & 
    (df['network_utilization'] >= 0) & 
    (df['system_temperature'] < 150) # Removing extreme outliers
]

print("Cleaned Data Shape:", df.shape)

from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, precision_score, recall_score, confusion_matrix, classification_report
import seaborn as sns
import matplotlib.pyplot as plt

# Features and Target
feature_cols = ['cpu_usage', 'ram_usage', 'disk_usage', 'network_utilization', 'system_temperature', 'error_count']
X = df[feature_cols]
y = df['risk_class']

# Split Data into Training and Testing Sets (80% Train, 20% Test)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Normalization / Scaling
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# Initialize and train Random Forest Classifier
print("Training Random Forest Classifier on Scaled Data...")
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train_scaled, y_train)

# Make Predictions on Training Set (to check for overfitting)
y_train_pred = model.predict(X_train_scaled)
train_accuracy = accuracy_score(y_train, y_train_pred)

# Make Predictions on Test Set
y_pred = model.predict(X_test_scaled)

# --- Evaluation Metrics ---
print("\n--- Model Evaluation ---")
accuracy = accuracy_score(y_test, y_pred)
precision = precision_score(y_test, y_pred, average='weighted')
recall = recall_score(y_test, y_pred, average='weighted')
conf_matrix = confusion_matrix(y_test, y_pred)

print(f"Training Accuracy: {train_accuracy:.4f}")
print(f"Test Accuracy:     {accuracy:.4f}")
print(f"Precision:         {precision:.4f}")
print(f"Recall:            {recall:.4f}")
print("\nConfusion Matrix:")
print(conf_matrix)
print("\nClassification Report:")
print(classification_report(y_test, y_pred, target_names=['Safe', 'Warning', 'Critical']))

# Save the model and the scaler (fit on training data)
model_filename = "system_risk_model.pkl"
scaler_filename = "scaler.pkl"

joblib.dump(model, model_filename)
joblib.dump(scaler, scaler_filename)

print(f"Model saved as {model_filename}")
print(f"Scaler saved as {scaler_filename}")

# Test prediction (Single Sample)
# Example: High CPU, High Temp -> Should be Critical (2)
test_input = pd.DataFrame([[95, 80, 50, 20, 90, 0]], columns=feature_cols)
# Apply scaling to test input
test_input_scaled = scaler.transform(test_input)
prediction = model.predict(test_input_scaled)
print(f"\nTest Input (Raw): {test_input.values}")
print(f"Predicted Class: {prediction[0]} (0=Safe, 1=Warning, 2=Critical)")
