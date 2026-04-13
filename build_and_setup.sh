#!/bin/bash

# Kirby App - Cloud Build & Dependency Setup Script
# This script prepares the environment, fetches dependencies, and builds the APK.

echo "🚀 Starting Kirby App Build Process..."

# 1. Grant execute permissions to gradlew
chmod +x gradlew

# 2. Clean and Fetch Dependencies
echo "📦 Fetching dependency modules..."
./gradlew clean --refresh-dependencies

# 3. Build Debug APK
echo "🛠️ Building Debug APK..."
./gradlew assembleDebug

# 4. Check results
if [ $? -eq 0 ]; then
    echo "✅ Build Successful!"
    echo "📱 APK Location: app/build/outputs/apk/debug/app-debug.apk"
else
    echo "❌ Build Failed. Check the logs above."
    exit 1
fi
