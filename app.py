import gradio as gr
import subprocess
import threading
import os
import sys

# Start FastAPI in background
def start_server():
    os.chdir("/workspace")
    sys.path.insert(0, "/workspace/backend")
    os.environ["GEMINI_API_KEY"] = os.getenv("GEMINI_API_KEY", "")
    from app.main import app
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=7860)

# Start in background thread
thread = threading.Thread(target=start_server, daemon=True)
thread.start()

# Create Gradio interface that proxies to FastAPI
def proxy_request(path: str):
    import requests
    try:
        resp = requests.get(f"http://localhost:7860{path}", timeout=30)
        return resp.text
    except Exception as e:
        return f"Error: {str(e)}"

demo = gr.Interface(
    fn=proxy_request,
    inputs=gr.Textbox(label="API Path", value="/"),
    outputs=gr.Textbox(label="Response"),
    title="F1 Dashboard API",
    description="Backend is loading... Try /health after a moment"
)

demo.launch()