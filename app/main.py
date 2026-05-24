import os
from fastapi import FastAPI

app = FastAPI(title="TechTest API")

@app.get("/health")
async def health_check():
    return {
        "status": "ok",
        "environment": os.getenv("ENVIRONMENT", "development")
    }
