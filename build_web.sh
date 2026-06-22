#!/bin/bash

# Exit on error
set -e

# Compile Flutter web
echo "Building Flutter Web..."
flutter build web \
  --dart-define=MAPS_API_KEY=${MAPS_API_KEY} \
  --dart-define=GEMINI_API_KEY=${GEMINI_API_KEY} \
  --dart-define=PARKING_API_BASE_URL=${PARKING_API_BASE_URL} \
  --dart-define=PARKING_API_TOKEN=${PARKING_API_TOKEN} \
  --release

# Replace Google Maps API Key placeholder in built index.html
echo "Injecting Google Maps API Key..."
if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux"* ]]; then
  sed -i "s/YOUR_MAPS_KEY/${MAPS_API_KEY}/g" build/web/index.html
else
  # Fallback for Windows/environments without standard sed
  powershell -Command "(Get-Content build/web/index.html) -replace 'YOUR_MAPS_KEY', \$env:MAPS_API_KEY | Set-Content build/web/index.html"
fi

# Deploy to Firebase hosting
echo "Deploying to Firebase Hosting..."
firebase deploy --only hosting
