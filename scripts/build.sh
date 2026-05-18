#!/bin/bash
# Graphite Build & Setup Script - Kelvin's Flutter Project

echo "🔧 Setting up Graphite..."
set -e  # exit on error

cd /home/kel/projects/graphite

# Step 1: Clean and install dependencies
echo "1. Installing Flutter packages..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ Failed to install packages" >&2
    exit 1
fi

# Step 2: Analyze code for errors (Flutter checks)
echo "2. Running flutter analyze..."
flutter analyze lib/
if [ $? -eq 0 ]; then
    echo "✅ All Flutter checks passed!"
else
    echo "❌ Analysis found issues — see output above" >&2
fi

# Step 3: List connected devices
echo ""
echo "📱 Available platforms:" 
flutter doctor -v | grep -E "(Android|iOS|Windows|Mac)" || true

echo ""
echo "✨ Ready to run! Next steps:"
echo "  → flutter run -d <device-id>    # Build & launch on your device"
echo "  → flutter build apk --debug      # Build Android APK (debug mode)"
echo "  → flutter build ios --debug      # Build iOS app (macOS only)"

# Done!
echo ""
