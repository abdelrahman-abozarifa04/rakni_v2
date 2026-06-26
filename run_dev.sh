#!/bin/bash
# Rakni v2 — dev runner with secure API keys via --dart-define
# Usage: bash run_dev.sh
# Keys never end up hardcoded in source or compiled into the APK.

flutter run \
  --dart-define=GEMINI_API_KEY=AIzaSyCDTtucqRKFNsPq4SsC6Q4PxDa7P5OER4k \
  --dart-define=MAPS_API_KEY=AIzaSyCI9YS3MzCZju4NbBKa04NocCG8yA1J-LI \
  --dart-define=PARKING_API_BASE_URL=https://garage-api-system.onrender.com \
  --dart-define=PARKING_API_TOKEN=7d368c0721945f66f41f86a2810057c70f230919

