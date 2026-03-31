import pandas as pd
import numpy as np
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
import joblib
import os

# --- Generate Synthetic User Behavior Data ---
# Logic:
# 1. "Meet dopeher mein 2-5 baje tak Heavy Coding karta hai" (14:00 - 17:00 -> High Load)
# 2. "Raat ko 2 baje High Load allowed nahi hai" (02:00 -> Low Load expected)
# 3. Other times -> Moderate/Random behavior

np.random.seed(42)
num_samples = 2000 # Simulate a few months of data points

# Time (Hour of day: 0-23)
hours = np.random.randint(0, 24, num_samples)

# Initialize Load (CPU Usage %)
cpu_usage = np.zeros(num_samples)

for i in range(num_samples):
    h = hours[i]
    
    # Behavior Logic:
    if 14 <= h <= 17:
        # Afternoon Heavy Coding: High CPU (60-95%)
        cpu_usage[i] = np.random.randint(60, 96)
    elif 1 <= h <= 5: 
        # Night Time (Sleep): Low CPU (0-10%)
        # Occasional update spikes (up to 30%)
        if np.random.rand() < 0.05:
            cpu_usage[i] = np.random.randint(15, 31)
        else:
            cpu_usage[i] = np.random.randint(0, 11)
    else:
        # Other times: Random Moderate Load (10-60%)
        cpu_usage[i] = np.random.randint(10, 61)

# Create DataFrame
data = {
    'hour': hours,
    'cpu_usage': cpu_usage
}
df = pd.DataFrame(data)

# Save simulated data for reference
df.to_csv('user_activity.csv', index=False)
print("Simulated user activity data saved to user_activity.csv")

# --- Train K-Means Clustering Model ---

# Features for clustering: Hour, CPU Usage
X = df[['hour', 'cpu_usage']]

# Scale data
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# K-Means Clustering
# We choose K=3 (Low Load, Medium Load, High Load)
# Or maybe K=5 for more granularity
kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
kmeans.fit(X_scaled)

# Assign labels
df['cluster'] = kmeans.labels_

# Calculate Centroids (Unscaled for interpretation)
centroids_scaled = kmeans.cluster_centers_
centroids = scaler.inverse_transform(centroids_scaled)

print("\n--- Cluster Centers ---")
print("Cluster | Hour | CPU Usage")
for i, c in enumerate(centroids):
    print(f"{i:7} | {c[0]:4.1f} | {c[1]:9.1f}")

# Save Model and Scaler
joblib.dump(kmeans, 'behavior_cluster_model.pkl')
joblib.dump(scaler, 'behavior_scaler.pkl')
print("\nModel saved as behavior_cluster_model.pkl")
print("Scaler saved as behavior_scaler.pkl")

# --- Test Logic ---
# Function to check if current behavior is anomalous
def is_anomalous(hour, cpu, threshold=2.0):
    # Scale input
    input_data = pd.DataFrame([[hour, cpu]], columns=['hour', 'cpu_usage'])
    input_scaled = scaler.transform(input_data)
    
    # Get cluster
    cluster = kmeans.predict(input_scaled)[0]
    centroid = kmeans.cluster_centers_[cluster]
    
    # Calculate distance to centroid
    dist = np.linalg.norm(input_scaled - centroid)
    
    print(f"\nTest: Hour={hour}, CPU={cpu}% -> Cluster {cluster}, Distance={dist:.4f}")
    
    if dist > threshold:
        return True, dist
    else:
        return False, dist

# Test Scenarios
# 1. 2:00 PM (14:00), High CPU (80%) -> Should be Normal
is_anomalous(14, 80)

# 2. 2:00 AM (02:00), High CPU (80%) -> Should be Anomaly
is_anomalous(2, 80)
