#!/bin/bash
# Rakni v2 — dev runner with secure API keys via --dart-define
# Usage: bash run_dev.sh
# Keys never end up hardcoded in source or compiled into the APK.

flutter run \
  --dart-define=GEMINI_API_KEY=AIzaSyCDTtucqRKFNsPq4SsC6Q4PxDa7P5OER4k \
  --dart-define=MAPS_API_KEY=AIzaSyCI9YS3MzCZju4NbBKa04NocCG8yA1J-LI \
  --dart-define=PARKING_API_BASE_URL=https://overfill-barley-confront.ngrok-free.dev \
  --dart-define=PARKING_API_TOKEN=33f95afc9ead18b464c2d1aa52642e0c7cc62ecd

