import psutil
import time
import ctypes
import os
import winreg
import numpy as np
from sklearn.ensemble import IsolationForest
from collections import deque
from ctypes import wintypes
import json
import win32api
import win32gui
import win32con
import win32clipboard
import hashlib
import random

class DefenceEngine:
    def __init__(self, socketio=None, logger_callback=None):
        self.socketio = socketio
        self.logger_callback = logger_callback
        self.last_action_time = 0
        self.cooldown_duration = 120  # 2 minutes cooldown
        self.is_cooling_down = False
        self.pending_mitigations = {} # PID -> Info
        
        # Core system whitelist
        self.system_whitelist = [
            'explorer.exe', 'taskhostw.exe', 'svchost.exe', 'wininit.exe', 
            'services.exe', 'lsass.exe', 'csrss.exe', 'python.exe', 'node.exe',
            'vmmem', 'system idle process', 'qunx_ai.exe', 'dart.exe', 'flutter_tester.exe',
            'dwm.exe', 'winlogon.exe', 'spoolsv.exe', 'smss.exe', 'searchindexer.exe',
            'msmpeng.exe', 'runtimebroker.exe', 'audiodg.exe', 'compattelrunner.exe',
            'fontdrvhost.exe', 'shellexperiencehost.exe'
        ]
        self.user_whitelist_file = 'user_whitelist.json'
        self.reputation_file = 'process_reputation.json'
        self.load_user_whitelist()
        self.load_reputation()
        
        # Advanced Monitoring State
        self.metric_history = {'cpu': [], 'ram': []}
        self.history_size = 30
        self.survival_mode = False
        self.deep_scan_mode = False # Task 2: Adaptive Thresholds
        self.auto_pilot = True
        self.consecutive_threats = 0 # For Ghost-Spike detection
        self.threat_threshold = 10  # Task 5: Damping - Need 10 frames (~5s) to confirm threat
        self.current_top_hog = "System"
        
        # Gaming Mode Logic
        self.gaming_mode = False
        self.game_executables = [
            'gta5.exe', 'valorant.exe', 'csgo.exe', 'rdr2.exe', 'cyberpunk2077.exe',
            'fortniteclient-win64-shipping.exe', 'minecraft.exe', 'overwatch.exe',
            'steam.exe', 'epicgameslauncher.exe', 'origin.exe', 'battle.net.exe'
        ]

        # --- CACHING SYSTEM ---
        self.analysis_cache = {} # PID -> {timestamp, result, footprint}
        self.cache_expiry = 5 # seconds
        
        # --- TURBO MODE & GOVERNOR STATE ---
        self.is_turbo_mode = False
        self.suspended_pids = [] # Tracks processes put to sleep
        self.throttled_pids = [] # Tracks processes with lowered priority
        self.resource_cleanup_threshold = 92.0 # Trigger cleanup if RAM > 92%
        
        # Persistence Monitoring
        self.monitored_reg_keys = [
            (winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\Run"),
            (winreg.HKEY_LOCAL_MACHINE, r"Software\Microsoft\Windows\CurrentVersion\Run")
        ]
        self.initial_registry_snapshot = self.get_registry_snapshot()
        
        # --- Advanced Shields State ---
        self.anomaly_detector = IsolationForest(contamination=0.01) # 1% anomaly threshold
        self.training_data = deque(maxlen=500) # Baseline DNA window
        self.is_baseline_ready = False
        
        # Suspicious Parent-Child Maps (Task 3: Graph Logic)
        self.suspicious_hierarchy = {
            'notepad.exe': ['cmd.exe', 'powershell.exe', 'vbc.exe', 'csc.exe'],
            'calc.exe': ['cmd.exe', 'powershell.exe'],
            'explorer.exe': ['certutil.exe', 'bitsadmin.exe'],
            'svchost.exe': ['cmd.exe'] # Svchost spawning cmd is highly suspicious
        }

        # Network Monitoring State (Task 5: NIDS)
        self.network_baseline = {} # process_name -> avg_connections

        # --- Ultra-Light Local LLM Strategy (Size: ~250MB) ---
        self.llm = None
        self.model_path = os.path.join(os.path.dirname(__file__), "models", "smollm2-360m-instruct-q4_k_m.gguf")
        self.is_llm_loading = False

        # --- ADVANCED PROTECT LAYER (Phase 1 & 2) ---
        self.last_clipboard_content = ""
        self.bait_files = []
        self.setup_deception_layer()
        self.quantum_rotation_token = hashlib.sha256(str(random.random()).encode()).hexdigest()[:8]
        
        # Start Event Watchers (Phase 2: Event-Driven)
        self._init_event_watchers()

    def _init_event_watchers(self):
        """Starts background threads to watch for Windows system events (New Processes)."""
        import threading
        
        def process_watcher():
            import pythoncom
            import wmi
            # We must initialize COM for the new thread
            pythoncom.CoInitialize()
            try:
                c = wmi.WMI()
                # Watch for process creation via Win32_Process creation events
                watcher = c.Win32_Process.watch_for("creation")
                self.log("EVENT SHIELD: Real-time Process Watcher is ONLINE.")
                
                while True:
                    try:
                        # blocks until a new process is created
                        new_proc = watcher()
                        name = new_proc.Name
                        pid = new_proc.ProcessId
                        
                        # Trigger an instant security audit for this process
                        self.scan_specific_process(pid, name)
                        
                    except Exception as e:
                        time.sleep(1)
            except Exception as e:
                self.log(f"EVENT SHIELD Error: {e}")
            finally:
                pythoncom.CoUninitialize()

        watcher_thread = threading.Thread(target=process_watcher, daemon=True)
        watcher_thread.start()

    def scan_specific_process(self, pid, name):
        """Audits a newly created process instantly."""
        try:
            # Check whitelist first
            if name.lower() in [s.lower() for s in self.system_whitelist] + [u.lower() for u in self.user_whitelist]:
                return

            p = psutil.Process(pid)
            # Basic metrics for risk prediction
            p_cpu = p.cpu_percent()
            p_mem = p.memory_percent()
            
            # Check for suspicious hierarchy
            hierarchy_threat = self.check_process_hierarchy({'name': name, 'ppid': p.ppid()})
            if hierarchy_threat:
                self.log(f"CRITICAL: Suspicious startup detected! {name} spawned by unauthorized parent.", critical=True)
                self.handle_threat(2, top_hog=name, proc_list=[{'pid': pid, 'name': name, 'cpu_percent': p_cpu, 'memory_percent': p_mem}])
                return

            # Check reputation
            trust = self.get_trust_score(name)
            if trust < 20:
                self.log(f"SHIELD: High-risk application started: {name}. Monitoring closely.")
                self.handle_threat(1, top_hog=name, proc_list=[{'pid': pid, 'name': name, 'cpu_percent': p_cpu, 'memory_percent': p_mem}])

        except: pass

    def _init_llm(self):
        """Lazy loads the ultra-light LLM model."""
        if self.llm is not None:
            return True
            
        if not os.path.exists(self.model_path):
            self.log(f"LLM Info: Ultra-light model not found at {self.model_path}. Chat unavailable.", critical=False)
            return False
            
        try:
            self.is_llm_loading = True
            from llama_cpp import Llama
            self.log("Activating Neural Nano-Core (GPU Accelerated if available)...")
            
            # --- GPU ACCELERATION LOGIC ---
            # n_gpu_layers: -1 means offload all layers to GPU. 
            # This requires llama-cpp-python to be compiled with CUDA/Vulkan support.
            try:
                self.llm = Llama(
                    model_path=self.model_path,
                    n_ctx=1024,
                    n_threads=os.cpu_count() // 2, # Use half of physical cores
                    n_gpu_layers=-1, # ATTEMPT FULL GPU OFFLOAD
                    verbose=False
                )
            except Exception as e:
                self.log(f"GPU Load failed ({e}). Falling back to CPU-only Mode.")
                self.llm = Llama(
                    model_path=self.model_path,
                    n_ctx=1024,
                    n_threads=min(4, os.cpu_count()),
                    n_gpu_layers=0, # CPU only
                    verbose=False
                )
            
            self.is_llm_loading = False
            self.log("Nano AI Co-pilot is ONLINE.")
            return True
        except Exception as e:
            self.is_llm_loading = False
            self.log(f"Failed to load Nano AI: {e}")
            return False

    def get_ai_diagnostic(self, user_query=None):
        """Task 3.1: Ultra-Light LLM Diagnostics - Improved Accuracy & Hinglish."""
        if not self._init_llm():
            return "AI DIAGNOSTIC: Offline. (Download smollm2-360m to models/ to enable)"
            
        # Expanded Keywords for better detection
        perf_keywords = [
            "slow", "hang", "lag", "performance", "cpu", "ram", "memory", 
            "speed", "heat", "hot", "system", "status", "pc", "computer", 
            "halat", "garam", "load", "kam", "atak", "thik", "fix", "issue", 
            "problem", "analysis", "scan", "risk", "resource", "usage", "health",
            "kaisa", "batao", "chal", "report", "check"
        ]
        
        is_performance_query = False
        if user_query:
            query_lower = user_query.lower()
            is_performance_query = any(kw in query_lower for kw in perf_keywords)
        else:
            is_performance_query = True
            user_query = "System status check."

        # Fetch all metrics including Temperature
        cpu = psutil.cpu_percent(interval=0.1)
        ram_info = psutil.virtual_memory()
        ram_p = ram_info.percent
        # Temperature from engine state
        current_temp = getattr(self, '_last_temp', 45.0) 
        if hasattr(self, 'metric_history') and self.metric_history['cpu']:
             # Use real-time logic to estimate if not updated
             pass

        if is_performance_query:
            context = f"METRICS: CPU {cpu}%, RAM {ram_p}%, Temp {current_temp}C. Top Process: {self.current_top_hog}."
            
            # Strict Prompt for SmolLM-360M
            system_prompt = (
                "You are NOVA SHIELD AI. Task: Analyze the PC metrics provided and answer the user. "
                "CRITICAL: Use Hinglish (mix of Hindi and English) to explain. "
                f"Data: {context}. "
                "If Temp is high (>70), tell them to clean dust. If CPU is high, mention the Top Process. "
                "Keep it professional but friendly."
            )
        else:
            system_prompt = (
                "You are NOVA SHIELD AI. Answer the user normally in Hinglish. "
                "Do not mention system metrics unless asked. Keep it short."
            )

        # ChatML format with better instruction following
        prompt = f"<|im_start|>system\n{system_prompt}<|im_end|>\n<|im_start|>user\n{user_query}<|im_end|>\n<|im_start|>assistant\n"
        
        try:
            # Increase temp or penalty if needed, but keeping default for stability
            response = self.llm(
                prompt, 
                max_tokens=256, 
                stop=["<|im_end|>", "User:", "System:"],
                temperature=0.7
            )
            text_resp = response['choices'][0]['text'].strip()
            
            # Simple cleanup if model repeats system markers
            if "<|im_start|>" in text_resp:
                text_resp = text_resp.split("<|im_start|>")[0].strip()
                
            return text_resp
        except Exception as e:
            return f"AI Error: {e}"

    def load_user_whitelist(self):
        """Loads whitelist from persistent JSON storage."""
        try:
            if os.path.exists(self.user_whitelist_file):
                with open(self.user_whitelist_file, 'r') as f:
                    self.user_whitelist = json.load(f)
            else:
                self.user_whitelist = []
        except Exception as e:
            print(f"Error loading user whitelist: {e}")
            self.user_whitelist = []

    def load_reputation(self):
        """Task 1: Dynamic Trust Scoring persistence."""
        try:
            if os.path.exists(self.reputation_file):
                with open(self.reputation_file, 'r') as f:
                    self.reputation_db = json.load(f)
            else:
                self.reputation_db = {}
        except:
            self.reputation_db = {}

    def save_reputation(self):
        try:
            with open(self.reputation_file, 'w') as f:
                json.dump(self.reputation_db, f)
        except: pass

    def get_trust_score(self, process_name):
        # System whitelist starts at 100, others 50
        if process_name.lower() in self.system_whitelist: return 100
        return self.reputation_db.get(process_name.lower(), 50)

    def update_trust_score(self, process_name, delta):
        name = process_name.lower()
        score = self.get_trust_score(name)
        new_score = max(0, min(100, score + delta))
        self.reputation_db[name] = new_score
        if abs(delta) > 0: self.save_reputation()

    def log(self, message, process_name=None, critical=False):
        timestamp = time.strftime("%H:%M:%S")
        full_message = f"[{timestamp}] [DEFENCE] {message}"
        print(full_message)
        
        if critical:
            self.send_desktop_notification("CRITICAL THREAT DETECTED", message)

        if self.socketio:
            # Rotate Quantum Token for visual impact in logs
            self.quantum_rotation_token = hashlib.sha256(self.quantum_rotation_token.encode()).hexdigest()[:8]
            
            self.socketio.emit('new_log', {
                'id': int(time.time() * 1000),
                'time': timestamp,
                'action': message,
                'type': 'AI',
                'process': process_name,
                'critical': critical,
                'quantum_token': f"QS-{self.quantum_rotation_token.upper()}"
            })
        if self.logger_callback:
            self.logger_callback(full_message)

    def send_desktop_notification(self, title, msg):
        """Sends a native Windows toast notification."""
        try:
            import win32gui, win32con
            import os
            
            # Simple notification using MessageBox as a fallback or a real tool if needed
            # For real toast we'd need more code, but win32gui can do it
            # I'll use a simplified version for now or just MessageBox for high visibility
            win32api.MessageBox(0, msg, title, win32con.MB_ICONWARNING | win32con.MB_OK | win32con.MB_SYSTEMMODAL)
        except Exception as e:
            print(f"Failed to send notification: {e}")

    def get_foreground_pid(self):
        """Gets the PID of the currently active window."""
        try:
            hwnd = ctypes.windll.user32.GetForegroundWindow()
            if not hwnd: return None
            pid = wintypes.DWORD()
            ctypes.windll.user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
            return pid.value
        except:
            return None

    def check_cooldown(self):
        """Checks if the engine is in cool-down mode."""
        if self.is_cooling_down:
            elapsed = time.time() - self.last_action_time
            if elapsed < self.cooldown_duration:
                remaining = int(self.cooldown_duration - elapsed)
                return True, remaining
            else:
                self.is_cooling_down = False
                self.log("Cool-Down phase complete. System stabilized.")
        return False, 0

    def identify_resource_hogs(self, foreground_pid, cpu_threshold=40.0, ram_threshold=15.0, proc_list=None):
        """Task 2: Adaptive Thresholds based on System Mode."""
        hogs = []
        
        # 1. Base Adaptive Threshold Logic
        if self.gaming_mode:
            cpu_threshold = 10.0 # Strict background limit during gaming
            ram_threshold = 10.0
        elif self.deep_scan_mode:
            cpu_threshold = 5.0  # Ultra strict for catching silent threats
            ram_threshold = 5.0
        elif self.survival_mode:
            cpu_threshold = 20.0
            
        targets = proc_list if proc_list else psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent'])
        
        for p in targets:
            try:
                name = p['name'].lower()
                # Task 1: Trust Scoring Integration
                trust = self.get_trust_score(name)
                
                # Whitelist bypass
                if name in [s.lower() for s in self.system_whitelist] + [u.lower() for u in self.user_whitelist]:
                    continue

                if p['pid'] == foreground_pid or p['pid'] == os.getpid():
                    continue

                # Also ignore parent process (the runner)
                try:
                    if p['pid'] == psutil.Process().ppid():
                        continue
                except: pass

                # If highly trusted (90+), double the threshold to avoid false positives
                eff_cpu = cpu_threshold * 2 if trust >= 90 else cpu_threshold
                eff_ram = ram_threshold * 2 if trust >= 90 else ram_threshold
                
                if p['cpu_percent'] > eff_cpu or p['memory_percent'] > eff_ram:
                    hogs.append(p)
            except: continue
        return hogs

    def handle_threat(self, risk_level, top_hog="System", proc_list=None):
        """Orchestrates PEAS-based response hierarchy."""
        self.current_top_hog = top_hog
        
        # 0. Check for Gaming Awareness
        foreground_pid = self.get_foreground_pid()
        is_game_running = False
        try:
            if foreground_pid:
                proc = psutil.Process(foreground_pid)
                if proc.name().lower() in self.game_executables:
                    is_game_running = True
        except: pass

        effective_gaming = self.gaming_mode or is_game_running
        
        if effective_gaming:
            if risk_level == 1: risk_level = 0 
            elif risk_level == 2:
                if psutil.cpu_percent() < 98: risk_level = 1 
        
        # Task 5: Ghost-Spike Damping
        if risk_level >= 1:
            self.consecutive_threats += 1
        else:
            self.consecutive_threats = 0

        self.emit_advanced_metrics(proc_list=proc_list)

        if self.consecutive_threats < self.threat_threshold and risk_level >= 1:
            return

        if risk_level == 0:
            if self.auto_pilot: self.auto_tune_idle_system()
            return

        in_cooldown, remaining = self.check_cooldown()
        if in_cooldown: return

        # --- RESPONSE HIERARCHY (Task 3) ---
        hogs = self.identify_resource_hogs(foreground_pid, proc_list=proc_list)

        # Proactive Survival Mode if crash imminent
        prediction = self.calculate_prediction()
        if prediction and prediction['status'] == 'critical':
            if not self.survival_mode:
                self.log("CRITICAL: IMMINENT CRASH! ACTIVATING SURVIVAL ACTUATORS.")
                self.survival_mode = True

        for hog in hogs:
            pid = hog['pid']
            trust = self.get_trust_score(hog['name'])
            
            # Level 1: Throttling (If Warning or High Trust)
            if risk_level == 1 or trust >= 70:
                self.set_priority(pid, 'idle')
                self.update_trust_score(hog['name'], -0.5)
                self.log(f"HIERARCHY L1: Throttled {hog['name']} (Trust: {trust})")
            
            # Level 2: Suspension & Critical Warning (If Low Trust or Survival)
            elif risk_level == 2 or self.survival_mode:
                try:
                    p = psutil.Process(pid)
                    if trust < 40 or self.survival_mode:
                        p.suspend()
                        self.log(f"HIERARCHY L2: Suspended {hog['name']} (PID: {pid})")
                        self.update_trust_score(hog['name'], -5)
                except: pass

            # Emit for UI Mitigation
            if pid not in self.pending_mitigations:
                self.pending_mitigations[pid] = hog
                if self.socketio:
                    self.socketio.emit('mitigation_request', {
                        'pid': pid, 'name': hog['name'], 'cpu': hog['cpu_percent'],
                        'ram': hog['memory_percent'], 'trust': trust, 'risk': risk_level
                    })



    def emit_advanced_metrics(self, proc_list=None):
        """Calculates and emits data for the 4 new prevention pages."""
        # 1. Update History
        cpu = psutil.cpu_percent()
        ram = psutil.virtual_memory().percent
        self.metric_history['cpu'].append(cpu)
        self.metric_history['ram'].append(ram)
        if len(self.metric_history['cpu']) > self.history_size:
            self.metric_history['cpu'].pop(0)
            self.metric_history['ram'].pop(0)

        # 2. Predictive Analysis (Simple Linear Trend)
        prediction = self.calculate_prediction()
        
        # OPTIMIZATION: Detect leaks/behavior threats ONLY every 3 seconds (reduces CPU)
        now = time.time()
        if not hasattr(self, '_last_deep_scan') or (now - self._last_deep_scan > 3.0):
            self._cached_leaks = self.detect_memory_leaks(proc_list)
            self._cached_balance = self.get_resource_balance(proc_list)
            self._cached_behavior = self.detect_behavioral_threats(proc_list)
            self._last_deep_scan = now

        if self.socketio:
            self.socketio.emit('advanced_metrics', {
                'prediction': prediction,
                'leaks': self._cached_leaks,
                'balance': self._cached_balance,
                'dna_threats': self._cached_behavior,
                'privacy_threats': self.detect_privacy_threats(),
                'deception_logs': self.check_bait_files(),
                'survival_mode': self.survival_mode,
                'gaming_mode': self.gaming_mode,
                'turbo_mode': self.is_turbo_mode,
                'top_hog': self.current_top_hog,
                'history': {
                    'cpu': self.metric_history['cpu'],
                    'ram': self.metric_history['ram']
                }
            })

    def calculate_prediction(self):
        """Predicts time to crash based on RAM growth."""
        if len(self.metric_history['ram']) < 5:
            return {"min": 99, "sec": 59, "status": "stable"}
        
        # Simple slope calculation (delta usage / delta time)
        y = self.metric_history['ram']
        growth = (y[-1] - y[0]) / len(y)
        
        if growth <= 0:
            return {"min": 99, "sec": 59, "status": "stable"}
        
        remaining_capacity = 100 - y[-1]
        time_to_crash_seconds = (remaining_capacity / growth) * 1 # approx interval (0.5s * 2)
        
        minutes = int(time_to_crash_seconds // 60)
        seconds = int(time_to_crash_seconds % 60)
        
        status = "critical" if minutes < 5 else "warning" if minutes < 15 else "stable"
        
        # Only show countdown if not stable
        if status == "stable":
            return {"min": 0, "sec": 0, "status": "stable"}

        return {
            "min": min(99, minutes),
            "sec": seconds,
            "status": status
        }

    def detect_memory_leaks(self, proc_list=None):
        """Identifies processes with high memory but low activity."""
        leaks = []
        targets = proc_list if proc_list else psutil.process_iter(['name', 'memory_info', 'cpu_percent'])
        for p_info in targets:
            try:
                # Potential leak: > 500MB and < 2% CPU usage
                mem_mb = p_info['memory_info'].rss / (1024 * 1024)
                if mem_mb > 500 and p_info['cpu_percent'] < 2:
                    leaks.append({
                        'name': p_info['name'],
                        'mem': f"{int(mem_mb)}MB",
                        'cpu': p_info['cpu_percent']
                    })
            except: continue
        return leaks[:5]

    def get_resource_balance(self, proc_list=None):
        """Splits load between Foreground and Background."""
        fg_pid = self.get_foreground_pid()
        fg_load = 0
        bg_load = 0
        
        targets = proc_list if proc_list else psutil.process_iter(['pid', 'cpu_percent'])
        for p_info in targets:
            try:
                if p_info['pid'] == fg_pid:
                    fg_load += p_info['cpu_percent']
                else:
                    bg_load += p_info['cpu_percent']
            except: continue
        
        total = max(1, fg_load + bg_load)
        return {
            'foreground': int((fg_load / total) * 100),
            'background': int((bg_load / total) * 100)
        }

    def set_priority(self, pid, level):
        """Changes process priority class on Windows."""
        try:
            p = psutil.Process(pid)
            levels = {
                'idle': psutil.IDLE_PRIORITY_CLASS,
                'normal': psutil.NORMAL_PRIORITY_CLASS,
                'high': psutil.HIGH_PRIORITY_CLASS,
                'realtime': psutil.REALTIME_PRIORITY_CLASS
            }
            p.nice(levels.get(level.lower(), psutil.NORMAL_PRIORITY_CLASS))
            self.log(f"GOVERNOR: Changed {p.name()} priority to {level.upper()}")
            return True
        except Exception as e:
            self.log(f"ERROR: Priority change failed: {e}")
            return False

    def execute_mitigation(self, pid, approved=True):
        """Callback from frontend to either kill or ignore a hog."""
        if pid in self.pending_mitigations:
            hog = self.pending_mitigations.pop(pid)
            name = hog['name']
            if approved:
                try:
                    self.log(f"PERMITTED: Terminating background hog {name} (PID: {pid})", process_name=name)
                    p = psutil.Process(pid)
                    p.terminate()
                    self.update_trust_score(name, -10) # Heavy penalty for confirmed threat
                    self.last_action_time = time.time()
                    self.is_cooling_down = True
                except Exception as e:
                    self.log(f"ERROR: Execution failed for {name}: {e}", process_name=name)
            else:
                self.log(f"DENIED: User protected {name}. Increasing trust.", process_name=name)
                self.update_trust_score(name, 10) # Reward if user says it's safe

    # --- NOVA TURBO MODE & RESOURCE GOVERNOR (The "Lets Do It" Implementation) ---

    def toggle_turbo_mode(self, active=True):
        """Main entry point for Turbo Mode activation/restoration."""
        self.is_turbo_mode = active
        if active:
            return self.activate_turbo_mode()
        else:
            return self.deactivate_turbo_mode()

    def activate_turbo_mode(self):
        """Logic to suspend/throttle background processes for maximum FPS/Performance."""
        self.log("🚀 BOOSTER: Activating NOVA TURBO MODE. Real-time optimization in progress...")
        freed_count = 0
        
        # 1. Flush RAM Cache where possible
        import gc
        gc.collect()
        
        # 2. Identify Non-Essential Background Targets
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
            try:
                name = proc.info['name'].lower()
                pid = proc.info['pid']
                
                # Check safe groupings
                is_system = any(s.lower() in name for s in self.system_whitelist)
                is_user_fav = any(u.lower() in name for u in self.user_whitelist)
                is_self = pid == os.getpid()
                
                if not is_system and not is_user_fav and not is_self:
                    # Target detected!
                    p = psutil.Process(pid)
                    
                    # Option A: Suspend Heavy Background Tasks (Suspend logic)
                    if proc.info['cpu_percent'] > 2.0 or proc.info['memory_percent'] > 5.0:
                        try:
                            p.suspend()
                            self.suspended_pids.append(pid)
                            freed_count += 1
                        except: pass
                    else:
                        # Option B: Throttle Lighter Tasks (Priority logic)
                        try:
                            p.nice(psutil.IDLE_PRIORITY_CLASS)
                            self.throttled_pids.append((pid, psutil.NORMAL_PRIORITY_CLASS)) # Store to restore
                        except: pass
            except: continue
        
        self.log(f"BOOSTER: Optimized {freed_count} processes. Performance ceiling increased.")
        return {"status": "success", "optimized": freed_count}

    def deactivate_turbo_mode(self):
        """Restores system to normal state by resuming and resetting priorities."""
        self.log("🔄 SYSTEM: Deactivating Turbo Mode. Restoring background ecosystem...")
        
        # 1. Resume Suspended Processes
        for pid in self.suspended_pids:
            try:
                p = psutil.Process(pid)
                p.resume()
            except: pass
        self.suspended_pids = []
        
        # 2. Restore Throttled Priorities
        for pid, old_priority in self.throttled_pids:
            try:
                p = psutil.Process(pid)
                p.nice(old_priority)
            except: pass
        self.throttled_pids = []
        
        self.log("SYSTEM: All background tasks synchronized.")
        return {"status": "restored"}

    def run_emergency_resource_cleanup(self):
        """Option C: The 'Aggressive' cleanup for 95%+ RAM usage."""
        ram_p = psutil.virtual_memory().percent
        if ram_p < self.resource_cleanup_threshold:
            return
            
        self.log(f"⚠️ EMERGENCY: RAM Critical ({ram_p}%). Purging non-essential background bloat.", critical=True)
        
        purged = []
        # Target specific common bloat/updaters + any non-essential hog
        bloat_keywords = ['update', 'telemetry', 'crashreporter', 'notificationhelper', 'feedback', 'broker', 'servicehub']
        
        for proc in psutil.process_iter(['pid', 'name', 'memory_percent']):
            try:
                name = proc.info['name'].lower()
                is_system = any(s.lower() in name for s in self.system_whitelist)
                is_user = any(u.lower() in name for u in self.user_whitelist)
                
                if not is_system and not is_user:
                    # Kill if it's explicitly bloat OR if it's using too much RAM (>4%)
                    if any(k in name for k in bloat_keywords) or proc.info['memory_percent'] > 4.0:
                        proc.terminate()
                        purged.append(name)
            except: continue
            
        if purged:
            self.log(f"RECOVERY: Closed {len(purged)} background services (e.g., {', '.join(purged[:3])}). System Stabilized.")

    def detect_behavioral_threats(self, proc_list=None):
        """Task 4: Multi-Sensor Correlation DNA Analysis."""
        threats = []
        now = time.time()
        targets = list(proc_list) if proc_list else list(psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_info', 'io_counters', 'ppid']))
        
        self.update_anomaly_baseline(targets)
        
        for pinfo in targets:
            try:
                pid = pinfo['pid']
                io = pinfo.get('io_counters')
                if not io: continue
                
                # --- TASK 1: Reputation Reward ---
                # If a process is running fine, increase trust slowly
                if pinfo['cpu_percent'] < 5:
                    self.update_trust_score(pinfo['name'], 0.01) # Passive trust build

                # --- SHIELD 1: Hierarchy (Graph Logic) ---
                hierarchy_threat = self.check_process_hierarchy(pinfo)
                if hierarchy_threat: threats.append(hierarchy_threat)

                # --- SHIELD 2: Multi-Sensor Correlation (Ransomware/Stealer) ---
                # Pattern: Low CPU + Extreme Disk Write + Unknown/Low Trust
                trust = self.get_trust_score(pinfo['name'])
                write_delta = io.write_bytes # Simplified for example
                if pinfo['cpu_percent'] < 10 and write_delta > 50 * 1024 * 1024 and trust < 40:
                    threats.append({"name": pinfo['name'], "dna": "ENCRYPTION_DISK_SPIKE", "risk": "critical"})
                    self.update_trust_score(pinfo['name'], -20)

                # --- SHIELD 3: Anomaly DNA (Task 4) ---
                if self.is_baseline_ready:
                    anomaly_threat = self.check_anomaly(pinfo)
                    if anomaly_threat: threats.append(anomaly_threat)

                # --- SHIELD 4: NIDS (Task 5) ---
                network_threat = self.detect_network_anomalies(pinfo)
                if network_threat: threats.append(network_threat)
                    
            except: continue
        return threats[:5]

    def check_process_hierarchy(self, pinfo):
        """Task 3: Graph Logic - Detects suspicious parent-child relationships."""
        try:
            name = pinfo['name'].lower()
            ppid = pinfo['ppid']
            parent = psutil.Process(ppid)
            parent_name = parent.name().lower()
            
            if parent_name in self.suspicious_hierarchy:
                if name in self.suspicious_hierarchy[parent_name]:
                    return {
                        "name": name,
                        "dna": f"SUSPICIOUS_HIERARCHY ({parent_name} -> {name})",
                        "risk": "critical"
                    }
        except: pass
        return None

    def update_anomaly_baseline(self, targets):
        """Task 4: Establishes Baseline DNA for anomaly detection."""
        for p in targets[:20]: # Only sample top processes to save CPU
            try:
                features = [p['cpu_percent'], p['memory_info'].rss / 1024 / 1024]
                self.training_data.append(features)
            except: continue
        
        if len(self.training_data) >= 300 and not self.is_baseline_ready:
            self.anomaly_detector.fit(list(self.training_data))
            self.is_baseline_ready = True
            self.log("ZERO-DAY PROTECTION: Baseline DNA established. Anomaly detection active.")

    def check_anomaly(self, pinfo):
        """Task 4: Detects unseen 'Zero-Day' behavior using Isolation Forest."""
        try:
            features = np.array([[pinfo['cpu_percent'], pinfo['memory_info'].rss / 1024 / 1024]])
            prediction = self.anomaly_detector.predict(features)
            if prediction[0] == -1: # Anomaly detected
                return {"name": pinfo['name'], "dna": "ANOMALOUS_DNA_SIGNATURE", "risk": "warning"}
        except: pass
        return None

    def detect_network_anomalies(self, pinfo):
        """Task 5: NIDS - Detects suspicious network connections."""
        try:
            proc = psutil.Process(pinfo['pid'])
            connections = proc.connections()
            if len(connections) > 15: # Arbitrary threshold for high-activity
                return {
                    "name": pinfo['name'],
                    "dna": f"HIGH_NETWORK_ACTIVITY ({len(connections)} conn)",
                    "risk": "warning"
                }
            
            # Detect Data Exfiltration (High read/write with active connections)
            io = pinfo.get('io_counters')
            if io and (io.write_bytes > 50 * 1024 * 1024) and connections:
                return {"name": pinfo['name'], "dna": "POTENTIAL_DATA_EXFIL", "risk": "critical"}
        except: pass
        return None

    def calculate_simulation(self, target_proc=None):
        """Simulates stability improvement (Digital Twin)."""
        if not self.metric_history['ram'] or len(self.metric_history['ram']) < 5:
            return None
            
        current_usage = self.metric_history['ram'][-1]
        savings = 15.0 # Base hypothetical savings
        
        # If simulation for a specific process, get its real RAM %
        if target_proc:
            for proc in psutil.process_iter(['name', 'memory_percent']):
                if proc.info['name'] == target_proc:
                    savings = proc.info['memory_percent']
                    break
        
        simulated_usage = max(10, current_usage - savings)
        growth = (self.metric_history['ram'][-1] - self.metric_history['ram'][0]) / len(self.metric_history['ram'])
        if growth <= 0: growth = 0.5
        
        sim_time_sec = ((90 - simulated_usage) / growth) * 1
        return {
            "improvement_min": int(sim_time_sec // 60) + 12, # Simulation bonus
            "new_stability": min(99, 100 - (simulated_usage * 0.5)),
            "savings": round(savings, 1)
        }

    def auto_tune_idle_system(self):
        """Task 1.4: Automatically lowers Priority of non-essential BG tasks when system is idle."""
        # Simple definition of idle: CPU < 5% for several seconds
        # To avoid overhead, we only check this every 30 seconds
        if int(time.time()) % 30 == 0:
            cpu = psutil.cpu_percent()
            if cpu < 5.0:
                self.log("IDLE OPTIMIZATION: System idle detected. Conserving power.")
                for proc in psutil.process_iter(['name', 'pid', 'cpu_percent']):
                    try:
                        if proc.info['name'].lower() not in self.system_whitelist and proc.info['cpu_percent'] > 0.5:
                            self.set_priority(proc.info['pid'], 'idle')
                    except: continue

    def calculate_thermal_maintenance(self, temp):
        """Task 3.3: Predicts if hardware needs cleaning based on temperature per CPU load."""
        # Baseline: At 10% load, temp should be ~45deg. 
        # If temp is 60deg at 10% load, thermal paste/dust is an issue.
        cpu = psutil.cpu_percent()
        expected_temp = 40 + (cpu * 0.4) 
        delta = temp - expected_temp
        
        if delta > 15:
            return {"score": 85, "message": "CRITICAL: Urgent thermal maintenance required. (Dust/Paste)"}
        elif delta > 8:
            return {"score": 40, "message": "ADVISORY: Cooling performance degrading."}
        return {"score": 0, "message": "Optimal"}


    def get_registry_snapshot(self):
        """Returns a snapshot of current startup registry keys."""
        snapshot = {}
        for root, path in self.monitored_reg_keys:
            try:
                key = winreg.OpenKey(root, path, 0, winreg.KEY_READ)
                count = winreg.QueryInfoKey(key)[1]
                for i in range(count):
                    name, value, _ = winreg.EnumValue(key, i)
                    snapshot[f"{root}\\{path}\\{name}"] = value
                winreg.CloseKey(key)
            except Exception as e:
                print(f"Error reading registry {path}: {e}")
        return snapshot

    def check_registry_integrity(self):
        """Detects new or changed startup items."""
        current = self.get_registry_snapshot()
        changes = []
        for key_path, value in current.items():
            if key_path not in self.initial_registry_snapshot:
                changes.append(f"NEW PERSISTENCE DETECTED: {key_path} -> {value}")
            elif self.initial_registry_snapshot[key_path] != value:
                changes.append(f"MODIFIED PERSISTENCE: {key_path} changed from {self.initial_registry_snapshot[key_path]} to {value}")
        
        if changes:
            for c in changes:
                self.log(c, critical=True)
            self.initial_registry_snapshot = current # Update snapshot
        return changes

    # --- ADVANCED PROTECTION LAYER METHODS ---

    def setup_deception_layer(self):
        """Creates hidden 'bait' files to trap ransomware or data thieves."""
        bait_locations = [
            os.path.join(os.environ.get('USERPROFILE', ''), 'Documents', '.shield_vault'),
            os.path.join(os.environ.get('TEMP', ''), 'sys_config_backup.dat'),
            os.path.join(os.environ.get('USERPROFILE', ''), 'Desktop', 'passwords.txt')
        ]
        
        for loc in bait_locations:
            try:
                if not os.path.exists(loc):
                    with open(loc, 'w') as f:
                        f.write(f"NOVA SHIELD BAIT FILE - DO NOT ACCESS\nID: {random.randint(1000, 9999)}")
                    # Set as hidden
                    ctypes.windll.kernel32.SetFileAttributesW(loc, 0x02) # FILE_ATTRIBUTE_HIDDEN
                
                # Store modification time and content hash
                mtime = os.path.getmtime(loc)
                self.bait_files.append({'path': loc, 'last_mtime': mtime})
                # self.log(f"Holo-Deception: Bait set at {loc}")
            except: pass

    def check_bait_files(self):
        """Detects unauthorized access to bait files."""
        alerts = []
        for bait in self.bait_files:
            try:
                current_mtime = os.path.getmtime(bait['path'])
                if current_mtime != bait['last_mtime']:
                    msg = f"DECEPTION TRIGGERED: Unauthorized access/change to {os.path.basename(bait['path'])}!"
                    self.log(msg, critical=True)
                    alerts.append(msg)
                    bait['last_mtime'] = current_mtime
            except: 
                # File might have been deleted by malware
                msg = f"DECEPTION TRIGGERED: Bait file REMOVED! ({os.path.basename(bait['path'])})"
                self.log(msg, critical=True)
                alerts.append(msg)
                self.bait_files.remove(bait)
        return alerts

    def monitor_clipboard(self):
        """Detects potential clipboard hijacking (Crypto swapping)."""
        try:
            win32clipboard.OpenClipboard()
            data = win32clipboard.GetClipboardData()
            win32clipboard.CloseClipboard()
            
            if data != self.last_clipboard_content:
                # Basic check for crypto address patterns (simulated for now)
                # If content changes multiple times in 1 second, it's suspicious
                self.last_clipboard_content = data
                # self.log(f"Clipboard Monitor: Content updated.")
        except: pass

    def detect_privacy_threats(self):
        """Heuristic check for camera/mic access by suspicious processes."""
        threats = []
        # Task 6: Privacy Shield - Logic to check process descriptors
        # For now, we flag any non-whitelisted process using high CPU + Network that isn't a browser/meeting app
        meeting_apps = ['zoom.exe', 'teams.exe', 'webex.exe', 'discord.exe', 'chrome.exe', 'msedge.exe', 'firefox.exe']
        
        for proc in psutil.process_iter(['name', 'cpu_percent', 'pid']):
            try:
                name = proc.info['name'].lower()
                if name not in meeting_apps and name not in self.system_whitelist:
                    # If a background app is using > 5% CPU consistently while not in focus
                    if proc.info['cpu_percent'] > 5.0:
                        fg_pid = self.get_foreground_pid()
                        if proc.info['pid'] != fg_pid:
                            # Potential background eavesdropping
                            threats.append({
                                'name': name,
                                'type': 'POTENTIAL_PRIVACY_LEAK',
                                'reason': 'Passive CPU usage in background'
                            })
            except: continue
        return threats[:3]
