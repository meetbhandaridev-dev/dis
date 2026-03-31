import sqlite3
import os
import time

class DatabaseManager:
    def __init__(self, db_name="system_metrics.db"):
        self.db_name = db_name
        self.init_db()

    def init_db(self):
        with sqlite3.connect(self.db_name) as conn:
            cursor = conn.cursor()
            
            # --- PERFORMANCE TUNING ---
            cursor.execute('PRAGMA journal_mode=WAL')
            cursor.execute('PRAGMA synchronous=NORMAL')
            
            # Metrics table for time-series data
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS metrics (
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    cpu REAL,
                    ram REAL,
                    temp REAL,
                    risk_score INTEGER
                )
            ''')
            # Events table for logs
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS events (
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    action TEXT,
                    type TEXT,
                    process_name TEXT
                )
            ''')
            conn.commit()

    def log_metrics(self, cpu, ram, temp, risk):
        with sqlite3.connect(self.db_name) as conn:
            cursor = conn.cursor()
            cursor.execute('INSERT INTO metrics (cpu, ram, temp, risk_score) VALUES (?, ?, ?, ?)', 
                           (cpu, ram, temp, risk))
            conn.commit()

    def log_event(self, action, event_type, process=""):
        with sqlite3.connect(self.db_name) as conn:
            cursor = conn.cursor()
            cursor.execute('INSERT INTO events (action, type, process_name) VALUES (?, ?, ?)', 
                           (action, event_type, process))
            conn.commit()

    def get_recent_metrics(self, limit=30):
        with sqlite3.connect(self.db_name) as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM metrics ORDER BY timestamp DESC LIMIT ?', (limit,))
            return cursor.fetchall()

    def get_weekly_summary(self):
        # Query for weekly trends (Task 1.1 - Persistence)
        with sqlite3.connect(self.db_name) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT DATE(timestamp), AVG(cpu), AVG(ram), MAX(temp)
                FROM metrics
                GROUP BY DATE(timestamp)
                LIMIT 7
            ''')
            return cursor.fetchall()
