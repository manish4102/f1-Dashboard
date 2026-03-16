import os
import sys

os.environ["GEMINI_API_KEY"] = os.getenv("GEMINI_API_KEY", "AIzaSyBXwmEXvaAR467tyJmNf7wkLGvMWnjM1b0")
sys.path.insert(0, "backend")

from app.main import app
import uvicorn

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=7860)