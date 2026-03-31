# Removed eventlet for Windows stability

from flask import Flask, render_template, request, jsonify
import joblib
import os
from dotenv import load_dotenv
import psutil
import numpy as np
import ctypes
from ctypes import wintypes
import time
from defence_engine import DefenceEngine
from db_manager import DatabaseManager
from flask_cors import CORS
import json

load_dotenv()

import queue
import threading
from flask_socketio import SocketIO, emit

# --- MESSAGE QUEUE SYSTEM ---
task_queue = queue.Queue()

def task_worker():
    """Background worker to handle CPU-intensive or slow I/O tasks from the queue."""
    print("Task Queue Worker Started.")
    while True:
        try:
            task = task_queue.get()
            if task is None: break # Termination signal
            
            func, args = task
            func(*args)
            
            task_queue.task_done()
        except Exception as e:
            print(f"Error in task worker: {e}")

# Start the background thread
worker_thread = threading.Thread(target=task_worker, daemon=True)
worker_thread.start()

app = Flask(__name__)
CORS(app)
app.config['SECRET_KEY'] = 'qunetx_secret'
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')

# Initialize Defence Engine with SocketIO for real-time logging
db_manager = DatabaseManager()
defence_engine = DefenceEngine(socketio=socketio, logger_callback=lambda msg: db_manager.log_event(msg, "AI"))

def get_foreground_app():
    try:
        # Get handle to foreground window
        hwnd = ctypes.windll.user32.GetForegroundWindow()
        if not hwnd:
            return "None"
        
        # Get process ID from window handle
        pid = wintypes.DWORD()
        ctypes.windll.user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
        
        # Get process name from PID
        process = psutil.Process(pid.value)
        return process.name()
    except Exception:
        return "Unknown"

# Load Model and Scaler using Joblib
MODEL_PATH = "system_risk_model.pkl"
SCALER_PATH = "scaler.pkl"

if os.path.exists(MODEL_PATH) and os.path.exists(SCALER_PATH):
    model = joblib.load(MODEL_PATH)
    scaler = joblib.load(SCALER_PATH)
    print("System Risk Model and Scaler loaded successfully.")
else:
    model = None
    scaler = None
    print("WARNING: System Risk Model or Scaler not found.")

# Load Behavior Model (KMeans)
BEHAVIOR_MODEL_PATH = "behavior_cluster_model.pkl"
BEHAVIOR_SCALER_PATH = "behavior_scaler.pkl"

if os.path.exists(BEHAVIOR_MODEL_PATH) and os.path.exists(BEHAVIOR_SCALER_PATH):
    behavior_model = joblib.load(BEHAVIOR_MODEL_PATH)
    behavior_scaler = joblib.load(BEHAVIOR_SCALER_PATH)
    print("Behavior Model and Scaler loaded successfully.")
else:
    behavior_model = None
    behavior_scaler = None
    print("WARNING: Behavior Model or Scaler not found.")

# State for rate calculation
last_io = {
    'net': None,
    'disk': None,
    'time': 0
}

import time
import pythoncom
import wmi

def get_real_temperature():
    try:
        pythoncom.CoInitialize()
        w = wmi.WMI(namespace="root\\wmi")
        temperature_info = w.MSAcpi_ThermalZoneTemperature()
        if temperature_info:
            # WMI returns temp in Kelvin * 10
            temp_kelvin = temperature_info[0].CurrentTemperature
            temp_celsius = (temp_kelvin - 2732) / 10.0
            return temp_celsius
    except Exception as e:
        pass
    return None

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/realtime')
def realtime():
    if model is None:
        return jsonify({'error': 'Model not loaded'}), 500
    
    global last_io
    current_time = time.time()
    
    # --- CPU ---
    # interval=0.5 for faster response but still accurate
    cpu = psutil.cpu_percent(interval=0.5)
    
    # --- RAM ---
    ram = psutil.virtual_memory().percent
    
    # --- DISK ACTIVITY & NETWORK ---
    # We calculate rates: bytes/sec or busy_time/sec
    
    net_io = psutil.net_io_counters()
    disk_io = psutil.disk_io_counters()
    
    network_usage = 0
    disk_usage = 0 # This will represent Active Time %
    
    if last_io['time'] > 0:
        delta = current_time - last_io['time']
        if delta > 0:
            # Network (Mbps) -> arbitrary scaling for 0-100% (Assuming 100Mbps link for visualization)
            # Bytes per second
            bytes_sent = net_io.bytes_sent - last_io['net'].bytes_sent
            bytes_recv = net_io.bytes_recv - last_io['net'].bytes_recv
            total_bytes = bytes_sent + bytes_recv
            
            # Convert to Mbps: (bytes * 8) / 1,000,000 / delta
            mbps = (total_bytes * 8) / (1000000 * delta)
            
            # Scale: 0-100 (100Mbps = 100%)
            network_usage = min(100, mbps)  

            # Disk (Active Time %)
            # busy_time is in ms
            # busy_delta = (disk_io.read_time + disk_io.write_time) - (last_io['disk'].read_time + last_io['disk'].write_time)
            # busy_percent = (busy_delta / (delta * 1000)) * 100
            
            # Note: psutil on Windows might not populate read_time/write_time correctly for all drivers.
            # Alternative: use read_count + write_count as activity proxy if times are 0
            
            read_time_delta = disk_io.read_time - last_io['disk'].read_time
            write_time_delta = disk_io.write_time - last_io['disk'].write_time
            
            busy_ms = read_time_delta + write_time_delta
            
            # Prevent negative (counter wrap/reset)
            if busy_ms < 0: busy_ms = 0
                
            disk_usage = min(100, (busy_ms / (delta * 1000)) * 100)
            
            # Fallback if disk times are not supported (stay 0): use IOPS scaling
            if busy_ms == 0:
                 ops_delta = (disk_io.read_count + disk_io.write_count) - (last_io['disk'].read_count + last_io['disk'].write_count)
                 # Arbitrary: 100 IOPS = 100%? No, 1000 IOPS.
                 disk_usage = min(100, ops_delta / delta / 10) 

    # Update state
    last_io['net'] = net_io
    last_io['disk'] = disk_io
    last_io['time'] = current_time
    
    # --- TEMPERATURE ---
    # Try real, fallback to logic
    real_temp = get_real_temperature()
    if real_temp is not None and real_temp > 0:
        temp = real_temp
    else:
        # Improved Mock: 
        # Base 40, add a portion of CPU load, add random jitter
        # CPU 100% -> +30C -> 70C
        temp = 40 + (cpu * 0.3) + np.random.randint(-1, 3)

    # Mocking Error Count
    errors = np.random.poisson(0.2)
    
    # Predict
    # Note: Model trained on "Disk Usage (Space)"? 
    # If the model was trained on random 10-100, checking "Disk Load 0-100" is compatible data-wise.
    
    # Pass 'disk load' as 'disk_usage' feature
    input_data = np.array([[cpu, ram, disk_usage, network_usage, temp, errors]])
    
    if scaler:
        input_scaled = scaler.transform(input_data)
        prediction = model.predict(input_scaled)
        risk_class = int(prediction[0])
    else:
        risk_class = 0
    
    foreground_app = get_foreground_app()
    
    return jsonify({
        'cpu': cpu,
        'ram': ram,
        'disk': disk_usage, # Sending Active Time % instead of Space
        'network': network_usage,
        'temp': temp,
        'errors': errors,
        'foreground_app': foreground_app,
        'risk_score': risk_class
    })

@app.route('/predict', methods=['POST'])
def predict():
    if model is None:
        return jsonify({'error': 'Model not loaded'}), 500

    if 'file' not in request.files:
        return jsonify({'error': 'No file uploaded'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400

    try:
        # Read CSV file manually to avoid pandas
        import csv
        import io
        
        file_content = file.read().decode('utf-8')
        dict_reader = csv.DictReader(io.StringIO(file_content))
        data_list = list(dict_reader)
        
        if not data_list:
            return jsonify({'error': 'CSV is empty'}), 400
            
        required_cols = ['cpu_usage', 'ram_usage', 'disk_usage', 'network_utilization', 'system_temperature', 'error_count']
        
        # Extract features into numpy array
        features_list = []
        for row in data_list:
            features_list.append([float(row[col]) for col in required_cols])
        
        features_np = np.array(features_list)
        features_scaled = scaler.transform(features_np)
        predictions = model.predict(features_scaled)
        
        # Add predictions to result
        for i, row in enumerate(data_list):
            row['predicted_risk'] = int(predictions[i])

        return jsonify({'status': 'success', 'data': data_list})

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/check_behavior', methods=['POST'])
def check_behavior():
    if behavior_model is None or behavior_scaler is None:
        return jsonify({'error': 'Behavior Model not loaded'}), 500

    data = request.json
    hour = data.get('hour')
    cpu = data.get('cpu_usage')

    if hour is None or cpu is None:
        return jsonify({'error': 'Missing hour or cpu_usage'}), 400

    try:
        # Prepare input for prediction using numpy
        input_data = np.array([[hour, cpu]])
        input_scaled = behavior_scaler.transform(input_data)
        
        # Predict Cluster
        cluster = behavior_model.predict(input_scaled)[0]
        centroid = behavior_model.cluster_centers_[cluster]
        
        # Calculate Distance to Centroid (Anomaly Score)
        distance = np.linalg.norm(input_scaled - centroid)
        
        # Threshold for Anomaly Detection based on training analysis
        # "Normal" behavior usually has distance < 1.0
        # "Anomalous" behavior (like 2AM High Load) had distance ~1.9
        THRESHOLD = 1.5 
        
        status = "Normal"
        if distance > THRESHOLD:
            status = "Anomaly"
            
        return jsonify({
            'status': status,
            'cluster': int(cluster),
            'distance': float(distance),
            'threshold': THRESHOLD,
            'message': 'Behavior Analysis Complete'
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/whitelist', methods=['POST'])
def add_to_whitelist():
    try:
        data = request.json
        process_name = data.get('process_name')
        if not process_name:
            return jsonify({'error': 'Process name is required'}), 400
        
        file_path = 'user_whitelist.json'
        whitelist = []
        if os.path.exists(file_path):
            with open(file_path, 'r') as f:
                whitelist = json.load(f)
        
        if process_name.lower() not in [p.lower() for p in whitelist]:
            whitelist.append(process_name.lower())
            with open(file_path, 'w') as f:
                json.dump(whitelist, f, indent=4)
            
            # Hot reload in defence engine
            defence_engine.load_user_whitelist()
            return jsonify({'status': 'Success', 'message': f'{process_name} added to whitelist.'})
        
        return jsonify({'status': 'Exists', 'message': f'{process_name} already in whitelist.'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/upgrade_gpu', methods=['POST'])
def upgrade_gpu_acceleration():
    """Triggers the GPU Setup script for Neural Boost."""
    try:
        from gpu_setup import setup_gpu_acceleration
        # This will run as a background task to avoid blocking the main app
        def run_boost():
            success = setup_gpu_acceleration()
            if success:
                defence_engine.log("SYSTEM UPDATE: Neural Core is now GPU ACCELERATED.")
            else:
                defence_engine.log("SYSTEM UPDATE: GPU Boost failed or no NVIDIA GPU detected.")
        
        task_queue.put((run_boost, ()))
        return jsonify({'status': 'Processing', 'message': 'Optimization started. Check logs for progress.'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/log_activity', methods=['POST'])
def log_activity():
    try:
        data = request.json
        hour = data.get('hour')
        cpu = data.get('cpu_usage')
        
        # Log to CSV using the Message Queue
        # Log to Database using the Message Queue
        def save_log(h, c):
            db_manager.log_metrics(c, 0, 0, 0) # Log load-only entries if needed
        
        # Add to queue
        task_queue.put((save_log, (hour, cpu)))
            
        return jsonify({'status': 'Task queued successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Global state for client tracking
connected_clients = 0

def metrics_agent():
    global connected_clients
    print("Metrics Agent Started - Adaptive Mode Active.")
    while True:
        try:
            # We recreate the logic from /realtime route for background emission
            global last_io
            current_time = time.time()
            
            # --- PHASE 1: LITE SCAN (Always run) ---
            # interval=0.1 for very fast, low-load check
            cpu = psutil.cpu_percent(interval=0.1)
            ram = psutil.virtual_memory().percent
            
            # Decide if we need HEAVY scan
            is_ui_active = connected_clients > 0
            is_critical = cpu > 75 or ram > 85 or (defence_engine.last_action_time > 0 and (current_time - defence_engine.last_action_time) < 30)
            
            # If system is healthy and no UI, we skip heavy IO and process iteration
            if not is_ui_active and not is_critical:
                # Still log metrics periodically (every 10s)
                if int(current_time) % 10 == 0:
                     db_manager.log_metrics(cpu, ram, 0, 0)
                
                # Deep sleep for idle systems without UI
                time.sleep(5.0)
                continue

            # --- PHASE 2: NORMAL SCAN (When UI active or Critical load) ---
            net_io = psutil.net_io_counters()
            disk_io = psutil.disk_io_counters()
            
            network_usage = 0
            disk_usage = 0
            
            if last_io['time'] > 0:
                delta = current_time - last_io['time']
                if delta > 0:
                    bytes_sent = net_io.bytes_sent - last_io['net'].bytes_sent
                    bytes_recv = net_io.bytes_recv - last_io['net'].bytes_recv
                    total_bytes = bytes_sent + bytes_recv
                    mbps = (total_bytes * 8) / (1000000 * delta)
                    network_usage = min(100, mbps)
                    
                    read_time_delta = disk_io.read_time - last_io['disk'].read_time
                    write_time_delta = disk_io.write_time - last_io['disk'].write_time
                    busy_ms = read_time_delta + write_time_delta
                    disk_usage = min(100, (busy_ms / (delta * 1000)) * 100) if busy_ms > 0 else 0

            # Update state for rates
            last_io['net'] = net_io
            last_io['disk'] = disk_io
            last_io['time'] = current_time

            real_temp = get_real_temperature()
            temp = real_temp if real_temp and real_temp > 0 else (40 + (cpu * 0.3) + np.random.randint(-1, 3))
            
            # --- REGISTRY MONITORING ---
            # Check for registry changes every 30 seconds (reduced from 10)
            if int(current_time) % 30 == 0:
                defence_engine.check_registry_integrity()

            # Find Top Resource Hog - ONLY if needed
            top_hog = "System"
            max_usage = 0
            all_processes = []
            
            # Optimization: Only scan process list if risk is possible or UI needs it
            if is_ui_active or cpu > 30:
                for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent', 'memory_info', 'io_counters']):
                    try:
                        p_info = proc.info
                        all_processes.append(p_info)
                        p_cpu = p_info['cpu_percent']
                        if p_cpu > max_usage:
                            max_usage = p_cpu
                            top_hog = p_info['name']
                    except: continue

            # Predict Risk
            risk_class = 0
            if model and scaler:
                input_np = np.array([[cpu, ram, disk_usage, network_usage, temp, 0]])
                input_scaled = scaler.transform(input_np)
                risk_class = int(model.predict(input_scaled)[0])
                
                # --- DEFENCE TRIGGER ---
                # Pass pre-scanned processes to engine
                defence_engine.handle_threat(risk_class, top_hog=top_hog, proc_list=all_processes)

            if is_ui_active:
                socketio.emit('system_metrics', {
                    'cpu': cpu,
                    'ram': ram,
                    'disk': disk_usage,
                    'network': network_usage,
                    'temp': temp,
                    'risk_score': risk_class,
                    'top_hog': top_hog,
                    'timestamp': time.strftime("%H:%M:%S")
                })

            # Persist Metrics to SQLite
            db_manager.log_metrics(cpu, ram, temp, risk_class)
            
            # --- EMERGENCY CLEANUP ---
            defence_engine.run_emergency_resource_cleanup()
            
            # Periodic Analysis for Predictive Maintenance (Every 2 minutes now)
            if int(current_time) % 120 == 0:
                maintenance_status = defence_engine.calculate_thermal_maintenance(temp)
                if maintenance_status['score'] > 0:
                    defence_engine.log(maintenance_status['message'], critical=(maintenance_status['score'] > 50))
            
            # Garbage Collection - FORCE FLUSH
            if int(current_time) % 60 == 0:
                import gc
                gc.collect()

        except Exception as e:
            print(f"Error in metrics agent: {e}")
            
        # ADAPTIVE SLEEP
        if risk_class > 0 or cpu > 75:
            sleep_time = 0.5
        elif is_ui_active:
            sleep_time = 1.0
        else:
            sleep_time = 3.0 # Lite polling when backgrounded
            
        time.sleep(sleep_time) 

@socketio.on('connect')
def handle_connect():
    global connected_clients
    connected_clients += 1
    print(f"Dashboard Connected. Active Clients: {connected_clients}")
    emit('status', {'message': 'Agent Connected'})

@socketio.on('disconnect')
def handle_disconnect():
    global connected_clients
    connected_clients = max(0, connected_clients - 1)
    print(f"Dashboard Disconnected. Active Clients: {connected_clients}")

@socketio.on('mitigation_response')

def handle_mitigation_response(data):
    pid = data.get('pid')
    approved = data.get('approved', False)
    print(f"User Response for Mitigation (PID {pid}): {'APPROVED' if approved else 'DENIED'}")
    defence_engine.execute_mitigation(pid, approved)

@socketio.on('set_priority')
def handle_set_priority(data):
    pid = data.get('pid')
    level = data.get('level', 'normal')
    defence_engine.set_priority(pid, level)

@socketio.on('toggle_survival_mode')
def handle_toggle_survival(data):
    active = data.get('active', False)
    defence_engine.survival_mode = active
    defence_engine.log(f"PROTOCOL: Survival Mode {'ACTIVATED' if active else 'DEACTIVATED'}")

@socketio.on('toggle_gaming_mode')
def handle_toggle_gaming(data):
    active = data.get('active', False)
    defence_engine.gaming_mode = active
    defence_engine.log(f"MODE: Gaming Optimization {'ENABLED' if active else 'DISABLED'}")

@socketio.on('toggle_deep_scan')
def handle_toggle_deep_scan(data):
    active = data.get('active', False)
    defence_engine.deep_scan_mode = active
    defence_engine.log(f"MODE: Deep Scan Protocol {'ACTIVATED' if active else 'DEACTIVATED'}")

@socketio.on('toggle_turbo_mode')
def handle_toggle_turbo_mode(data):
    active = data.get('active', False)
    result = defence_engine.toggle_turbo_mode(active)
    emit('turbo_mode_status', result)

@socketio.on('flush_memory')
def handle_flush_memory(data):
    process_name = data.get('name')
    # Find and kill the process
    for proc in psutil.process_iter(['pid', 'name']):
        if proc.info['name'] == process_name:
            try:
                proc.terminate()
                defence_engine.log(f"SHIELD: Flushed memory for {process_name}")
            except: pass

@socketio.on('request_simulation')
def handle_simulation(data):
    target = data.get('process')
    results = defence_engine.calculate_simulation(target)
    if results:
        socketio.emit('simulation_results', results)

@socketio.on('get_history')
def handle_get_history():
    # Fetch last 20 records for initial chart population
    history = db_manager.get_recent_metrics(limit=20)
    # db_manager returns [timestamp, cpu, ram, temp, risk]
    formatted_history = []
    for row in reversed(history):
        formatted_history.append({
            'cpu': row[1],
            'ram': row[2],
            'temp': row[3],
            'risk': row[4]
        })
    emit('history_data', formatted_history)

@socketio.on('ai_chat_query')
def handle_ai_chat(data):
    query = data.get('query')
    response = defence_engine.get_ai_diagnostic(user_query=query)
    emit('ai_chat_response', {'response': response})

@socketio.on('upgrade_gpu_request')
def handle_upgrade_gpu():
    print("GPU Upgrade Requested via Socket...")
    upgrade_gpu_acceleration()

if __name__ == '__main__':
    # Start metrics agent as a socketio background task
    socketio.start_background_task(metrics_agent)
    
    port = int(os.getenv('PORT', 8888))
    host = os.getenv('HOST', '127.0.0.1') # Changed to localhost for Windows reliability
    
    print(f"NOVA SHIELD: Starting Core on http://{host}:{port}...")
    # Use standard flask-socketio run
    socketio.run(app, debug=True, host=host, port=port, allow_unsafe_werkzeug=True)
