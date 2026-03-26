from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.services.gemini_service import ask_gemini

router = APIRouter()

class ChatRequest(BaseModel):
    message: str

@router.post("/chat")
async def chat(request: ChatRequest):
    try:
        response = ask_gemini(request.message)
        return {"response": response}
    except ValueError as e:
        raise HTTPException(status_code=503, detail=f"AI chat unavailable: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Chat error: {str(e)}")
