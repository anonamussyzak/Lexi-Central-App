# 🔧 Visual Studio C++ Compiler Fix

## 🚨 The Problem
The error `No CMAKE_CXX_COMPILER could be found` means Visual Studio's C++ development tools aren't installed or configured properly.

## ✅ Solution: Install Visual Studio 2022

### Step 1: Download Visual Studio 2022
- Go to: https://visualstudio.microsoft.com/downloads/
- Download **Visual Studio 2022 Community** (Free)

### Step 2: Install with Correct Workloads
During installation, you MUST select:
- ✅ **Desktop development with C++** (MOST IMPORTANT!)
- ✅ **Windows application development**
- ✅ **.NET desktop development**

### Step 3: Verify Installation
Open Visual Studio Installer and ensure these workloads are checked:
- ✅ Desktop development with C++
- ✅ Windows application development

### Step 4: Restart and Test
```powershell
# Restart PowerShell/Command Prompt
cd "c:\Users\borg\Desktop\Lexi Central"
flutter doctor -v
flutter run -d windows
```

## 🔧 Alternative: Visual Studio Build Tools

If you don't want full Visual Studio:
1. Download **Visual Studio Build Tools 2022**
2. During installation, select:
   - ✅ C++ build tools
   - ✅ Windows 10/11 SDK
   - ✅ CMake tools

## 🚀 After Fix - Run Lexi Central
```powershell
cd "c:\Users\borg\Desktop\exi Central"
flutter run -d windows
```

## 🎨 Then Customize Theme!
Once running, you can:
1. Open the app
2. Use the new customization section
3. Upload pictures
4. Change colors
5. Create presets
6. Rearrange modules

## 📱 If Still Issues
Try Android instead (no C++ needed):
```powershell
flutter run -d android
```

**The C++ compiler issue is the main blocker for Windows builds!**
