import os
import subprocess
import sys
import ctypes

def is_nvidia_gpu_available():
    """Checks if an NVIDIA GPU is present using nvidia-smi."""
    try:
        subprocess.check_output("nvidia-smi", shell=True, stderr=subprocess.STDOUT)
        return True
    except:
        return False

def setup_gpu_acceleration():
    """
    Safely installs CUDA-enabled llama-cpp-python for performance boost.
    No personal data is collected or transmitted during this process.
    """
    print("\n--- NOVA SHIELD: Neural Performance Booster ---")
    print("Checking hardware capabilities...\n")

    if not is_nvidia_gpu_available():
        print("[!] No NVIDIA GPU detected. System will stay in High-Efficiency CPU Mode.")
        return False

    print("[+] NVIDIA GPU Detected! Preparing 10x Performance Boost.")
    print("[i] Privacy Note: This will only download local processing libraries.")
    
    try:
        # Step 1: Uninstall existing CPU-only version
        print("Cleaning up old neural kernels...")
        subprocess.run([sys.executable, "-m", "pip", "uninstall", "llama-cpp-python", "-y"], check=True)

        # Step 2: Set CUDA environment variables for the build
        # We target a common CUDA environment (CuBLAS)
        os.environ["CMAKE_ARGS"] = "-DLLAMA_CUBLAS=on"
        os.environ["FORCE_CMAKE"] = "1"

        # Step 3: Install CUDA version from official PyPI
        print("Installing High-Speed Neural Core (This may take a minute)...")
        subprocess.run([sys.executable, "-m", "pip", "install", "llama-cpp-python", "--no-cache-dir"], check=True)

        print("\n[SUCCESS] Neural Engine is now GPU ACCELERATED!")
        print("Please restart the AI Agent to apply changes.")
        return True
    except Exception as e:
        print(f"\n[ERROR] Optimization failed: {e}")
        print("Reverting to standard mode. Your data remains safe.")
        subprocess.run([sys.executable, "-m", "pip", "install", "llama-cpp-python"], check=False)
        return False

if __name__ == "__main__":
    setup_gpu_acceleration()
