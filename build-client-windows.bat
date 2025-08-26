@echo off
setlocal enabledelayedexpansion

echo Checking for Rust installation...
cargo --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Rust is not installed. Installing via rustup...
    
    echo Attempting download with PowerShell...
    powershell -Command "Invoke-WebRequest -Uri 'https://win.rustup.rs/x86_64' -OutFile 'rustup-init.exe' -UseBasicParsing"
    if %errorlevel% neq 0 (
        echo PowerShell download failed. Trying curl...
        curl -L https://win.rustup.rs/x86_64 -o rustup-init.exe
        if %errorlevel% neq 0 (
            echo Download failed. Please manually install Rust from https://rustup.rs/
            echo After installation, re-run this script.
            pause
            exit /b 1
        )
    )
    
    echo Installing Rust...
    rustup-init.exe -y --default-toolchain stable
    if %errorlevel% neq 0 (
        echo Error installing Rust.
        exit /b 1
    )
    
    if exist "%USERPROFILE%\.cargo\env.bat" (
        call "%USERPROFILE%\.cargo\env.bat"
    ) else (
        set PATH=%USERPROFILE%\.cargo\bin;%PATH%
    )
    
    del rustup-init.exe
    echo Rust installation complete.
) else (
    echo Rust found.
)

echo Checking for LLVM...
clang --version >nul 2>&1
if %errorlevel% neq 0 (
    echo LLVM not found. 
    echo.
    echo MANUAL INSTALLATION REQUIRED:
    echo 1. Download LLVM from: https://github.com/llvm/llvm-project/releases
    echo 2. Install to default location
    echo 3. Add LLVM to your PATH during installation
    echo 4. Re-run this script after installation
    echo.
    pause
    exit /b 1
) else (
    echo LLVM found.
)

echo Checking for OpenCV...
where opencv_world* >nul 2>&1
if %errorlevel% neq 0 (
    echo OpenCV not found.
    echo.
    echo MANUAL INSTALLATION REQUIRED:
    echo Option 1 - Pre-built binaries:
    echo   1. Download OpenCV from: https://opencv.org/releases/
    echo   2. Extract to C:\opencv
    echo   3. Add C:\opencv\build\x64\vc16\bin to your PATH
    echo.
    echo Option 2 - vcpkg:
    echo   1. Install vcpkg: git clone https://github.com/Microsoft/vcpkg.git
    echo   2. Run: vcpkg install opencv[contrib]:x64-windows
    echo.
    echo After installation, re-run this script
    echo.
    set OPENCV_MISSING=1
) else (
    echo OpenCV found.
    set OPENCV_MISSING=0
)

for /f "delims=" %%i in ('where clang 2^>nul') do set CLANG_PATH=%%i
if defined CLANG_PATH (
    for %%i in ("%CLANG_PATH%") do set LLVM_DIR=%%~dpi..
    set LIBCLANG_PATH=!LLVM_DIR!\lib
) else (
    if exist "C:\Program Files\LLVM\lib" (
        set LIBCLANG_PATH=C:\Program Files\LLVM\lib
    ) else if exist "C:\tools\llvm\lib" (
        set LIBCLANG_PATH=C:\tools\llvm\lib
    )
)

echo Testing C++ compilation...
echo #include ^<memory^> > test.cpp
echo int main() { return 0; } >> test.cpp
clang++ test.cpp -o test.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo C++ compilation test successful.
    del test.cpp test.exe
) else (
    echo Warning: C++ compilation test failed.
    del test.cpp 2>nul
)

echo Environment configured.

if defined OPENCV_MISSING (
    if %OPENCV_MISSING%==1 (
        echo.
        echo WARNING: OpenCV not found. Build may fail.
        echo Install OpenCV manually and re-run this script.
        echo.
        pause
    )
)

echo Building the client in release mode...
cargo build --bin client --release
if %errorlevel% neq 0 (
    echo.
    echo Build failed. Common issues:
    echo 1. LLVM/Clang not properly installed or not in PATH
    echo 2. OpenCV not found or not properly configured
    echo 3. Missing Visual Studio Build Tools
    echo.
    echo Try installing Visual Studio Build Tools from:
    echo https://visualstudio.microsoft.com/visual-cpp-build-tools/
    echo.
    pause
    exit /b 1
)

echo Build complete.
echo You can now run the client with:
echo .\target\release\client.exe
pause