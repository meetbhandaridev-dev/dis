# 🛡️ Digital Immunity System (DIS) - Team Role Distribution

To ensure the success of the **Digital Immunity System (DIS)**, the project is divided into 4 key roles. Each role is designed to cover a specific architectural layer, from real-time system monitoring to AI-driven autonomous defense.

---

### 1️⃣ Role: Lead Frontend & UX Engineer 📱
**Primary Tech:** Flutter, Dart, Canvas/Charts libraries.

*   **Focus:** Visualizing high-frequency telemetry data and user interaction.
*   **Key Responsibilities:**
    *   Develop the **Qunx AI** dashboard for real-time monitoring of CPU, RAM, and Disk I/O.
    *   Create intuitive visual alerts when the system moves from "Stable" to "Risk" or "Critical".
    *   Implement controls for manual intervention and system configuration pages.
    *   Ensure a premium, high-performance UI experience across Windows and Mobile.
*   **Primary Workspace:** `qunx_ai/lib/`

---

### 2️⃣ Role: AI & ML Research Engineer 🧠
**Primary Tech:** Python, Scikit-Learn, Pandas, NumPy.

*   **Focus:** Predictive analytics and anomaly detection logic.
*   **Key Responsibilities:**
    *   Maintain and retrain the **System Risk Model** and **Behavior Cluster Model**.
    *   Refine the mathematical thresholds in the `defence_engine.py` for "System Exhaustion".
    *   Analyze telemetry patterns to differentiate between normal high-load and impending crash sequences.
    *   Optimize model latency to ensure predictions happen in milliseconds.
*   **Primary Workspace:** `ai_service/models/`, `ai_service/defence_engine.py` (AI Logic)

---

### 3️⃣ Role: Backend & Systems Architect ⚙️
**Primary Tech:** Python (FastAPI/Flask), SQLite, SQL.

*   **Focus:** Data pipeline, API services, and metric persistence.
*   **Key Responsibilities:**
    *   Manage the **System Metrics Database** (`system_metrics.db`) and data ingestion speed.
    *   Build the API bridges (`app.py`) between the AI service and the Flutter frontend.
    *   Design the `db_manager.py` for efficient historical data querying and cleanup.
    *   Ensure secure and reliable communication between all system components.
*   **Primary Workspace:** `ai_service/app.py`, `ai_service/db_manager.py`

---

### 4️⃣ Role: DevOps & Reliability Engineer (SRE) 🛡️
**Primary Tech:** OS-level Python (os, psutil), Shell Scripting, HW Acceleration.

*   **Focus:** Core system integration, GPU setup, and autonomous mitigation.
*   **Key Responsibilities:**
    *   Integrate the **Defence Engine** with OS-level process management (throttling/priority shifting).
    *   Handle hardware-specific setups like **GPU acceleration** (`gpu_setup.py`) for AI tasks.
    *   Manage the `.env` configurations, deployment scripts, and system-wide logging.
    *   Perform Stress Testing (QA) to ensure the "Survival Mode" actually prevents crashes.
*   **Primary Workspace:** `ai_service/gpu_setup.py`, `ai_service/.env`, `ai_service/defence_engine.py` (System Hooks)

---

## 🚀 Team Collaboration Workflow
1.  **Frontend** requests data → **Backend** fetches from **DB** → **AI Engineer** provides the "Risk Score" → **SRE** checks if action is needed.
2.  All team members should document their progress in the `DIS_Project_Info.md` file.
3.  Weekly sync to test if the **Predictive Infrastructure Healing** is functioning correctly.
