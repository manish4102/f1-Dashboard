import gradio as gr
import subprocess
import threading
import os
import sys
import time

# Start FastAPI server in background
def start_server():
    os.chdir("/workspace")
    sys.path.insert(0, "/workspace/backend")
    os.environ["GEMINI_API_KEY"] = os.getenv("GEMINI_API_KEY", "")
    
    # Wait for gradio to be ready
    time.sleep(5)
    
    from app.main import app
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=7860)

# Start backend in background
thread = threading.Thread(target=start_server, daemon=True)
thread.start()

def call_api(path: str):
    import requests
    try:
        url = f"http://localhost:7860{path}"
        resp = requests.get(url, timeout=60)
        return f"Status: {resp.status_code}\n\n{resp.text[:1000]}"
    except Exception as e:
        return f"Error: {str(e)}\n\nNote: Backend may still be loading. Try again in 30 seconds."

# Simple UI to test the API
demo = gr.Interface(
    fn=call_api,
    inputs=gr.Textbox(value="/", label="API Endpoint (e.g., /, /health, /load-session)"),
    outputs=gr.Textbox(label="Response"),
    title="F1 Dashboard API",
    description="Backend loads on first request. Be patient - it fetches F1 data."
)

demo.launch(server_name="0.0.0.0", server_port=7860)