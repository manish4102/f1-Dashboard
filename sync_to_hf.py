#!/usr/bin/env python3
"""Sync local backend files to HuggingFace Space."""

import os
from huggingface_hub import HfApi

TOKEN = os.environ.get("HF_TOKEN", "")

if not TOKEN:
    print("Error: Set HF_TOKEN environment variable")
    exit(1)

SPACE_ID = "manish4102/f1-dashboard"

api = HfApi()

# Files to upload from backend/
files_to_upload = [
    "backend/app/main.py",
    "backend/app/__init__.py",
    "backend/app/services/__init__.py",
    "backend/app/services/fastf1_loader.py",
    "backend/app/services/cache_store.py",
    "backend/app/services/gemini_service.py",
    "backend/app/api/__init__.py",
    "backend/app/api/routes_auth.py",
    "backend/app/api/routes_data.py",
    "backend/app/api/routes_chat.py",
    "backend/app/models/__init__.py",
    "backend/app/models/schemas.py",
    "requirements.txt",
]

# Also update README for proper HF Space config
files_to_upload.extend([
    "README.md",
])

print(f"Uploading to {SPACE_ID}...")

for file_path in files_to_upload:
    if not os.path.exists(file_path):
        print(f"  Skipping (not found): {file_path}")
        continue
    print(f"  Uploading: {file_path}")
    api.upload_file(
        path_or_fileobj=file_path,
        path_in_repo=file_path,
        repo_id=SPACE_ID,
        repo_type="space",
        token=TOKEN,
        commit_message=f"Upload {file_path}",
    )

print("Done!")
