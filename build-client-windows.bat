@echo off
setlocal enabledelayedexpansion

echo Checking for Rust installation...
cargo --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Rust is not installed. Installing via rustup...
    curl -sSf https://win.rustup.rs/x86_64 -o rustup-init.exe
    if %errorlevel% neq 0 (
        echo Error downloading rustup installer.
        exit /b 1
    )
    rustup-init.exe -y --default-toolchain stable
    if %errorlevel% neq 0 (
        echo Error installing Rust.
        exit /b 1
    )
    call "%USERPROFILE%\.cargo\env.bat"
    del rustup-init.exe
    echo Rust installation complete.
) else (
    echo Rust found.
)

echo Checking for Chocolatey...
choco --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Chocolatey is not installed. Installing Chocolatey...
    @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    if %errorlevel% neq 0 (
        echo Error installing Chocolatey.
        exit /b 1
    )
    call refreshenv
    echo Chocolatey installation complete.
) else (
    echo Chocolatey found.
)

echo Checking for LLVM...
clang --version >nul 2>&1
if %errorlevel% neq 0 (
    echo LLVM not found. Installing LLVM...
    choco install llvm -y
    if %errorlevel% neq 0 (
        echo Error installing LLVM.
        exit /b 1
    )
    call refreshenv
) else (
    echo LLVM found.
)

echo Checking for OpenCV...
where opencv_world* >nul 2>&1
if %errorlevel% neq 0 (
    echo OpenCV not found. Installing OpenCV via vcpkg...
    
    rem Check if vcpkg is installed
    where vcpkg >nul 2>&1
    if %errorlevel% neq 0 (
        echo Installing vcpkg...
        choco install vcpkg -y
        if %errorlevel% neq 0 (
            echo Error installing vcpkg.
            exit /b 1
        )
        call refreshenv
    )
    
    echo Installing OpenCV via vcpkg...
    vcpkg install opencv[contrib,nonfree]:x64-windows
    if %errorlevel% neq 0 (
        echo Error installing OpenCV via vcpkg.
        exit /b 1
    )
    
    rem Set OpenCV environment variables
    for /f "delims=" %%i in ('vcpkg list opencv') do set OPENCV_FOUND=%%i
    if defined OPENCV_FOUND (
        set OPENCV_DIR=%VCPKG_ROOT%\installed\x64-windows
        set PATH=%OPENCV_DIR%\bin;%PATH%
    )
) else (
    echo OpenCV found.
)

rem Set environment variables for LLVM
for /f "delims=" %%i in ('where clang 2^>nul') do set CLANG_PATH=%%i
if defined CLANG_PATH (
    for %%i in ("%CLANG_PATH%") do set LLVM_DIR=%%~dpi..
    set LIBCLANG_PATH=!LLVM_DIR!\lib
) else (
    rem Fallback to common installation paths
    if exist "C:\Program Files\LLVM\lib" (
        set LIBCLANG_PATH=C:\Program Files\LLVM\lib
    ) else if exist "C:\tools\llvm\lib" (
        set LIBCLANG_PATH=C:\tools\llvm\lib
    )
)

rem Test C++ compilation capability
echo Testing C++ compilation...
echo #include ^<memory^> > test.cpp
echo int main() { return 0; } >> test.cpp
clang++ test.cpp -o test.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo C++ compilation test successful.
    del test.cpp test.exe
) else (
    echo Warning: C++ compilation test failed. You may need to install Visual Studio Build Tools.
    del test.cpp 2>nul
)

echo Environment configured.
echo Building the client in release mode...
cargo build --bin client --release
if %errorlevel% neq 0 (
    echo Build failed.
    exit /b 1
)

echo Build complete.
echo You can now run the client with:
echo .\target\release\client.exe