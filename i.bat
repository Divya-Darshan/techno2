@echo off

:: Put your actual Godot package name here (e.g., com.yourname.technodungeon)
set PACKAGE_NAME=com.example.dash
set APK_PATH=./app/app.apk
set ADB="C:\Users\Darshan\AppData\Local\Android\Sdk\platform-tools\adb.exe"

echo Installing...
%ADB% install -r "%APK_PATH%"

echo Launching...
%ADB% shell monkey -p %PACKAGE_NAME% -c android.intent.category.LAUNCHER 1

echo Done!