import os
import warnings
warnings.filterwarnings("ignore")

import google.generativeai as genai

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")

def _get_model():
    if not GEMINI_API_KEY:
        raise ValueError("GEMINI_API_KEY environment variable is not set. Please set it in your Hugging Face Spaces secrets.")
    genai.configure(api_key=GEMINI_API_KEY)
    return genai.GenerativeModel("gemini-2.5-flash")

_model = None

def _get_cached_model():
    global _model
    if _model is None:
        _model = _get_model()
    return _model

def ask_gemini(prompt: str) -> str:
    model = _get_cached_model()
    response = model.generate_content(prompt)
    return response.text