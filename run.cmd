chcp 65001

@echo off
setlocal enabledelayedexpansion

if not defined FIRST_RUN (
    set FIRST_RUN=true
    start cmd /k "%~f0"
    exit /b
)

set STAGE_FILE=stage.txt

for /f "delims=" %%i in (%STAGE_FILE%) do set STAGE=%%i

if "%STAGE%"=="初始化子模块" goto :SUBMODULE
if "%STAGE%"=="安装环境" goto :INSTALL_ENV
if "%STAGE%"=="应用补丁" goto :PATCH
if "%STAGE%"=="进入环境" goto :ACTIVATE_ENV
if "%STAGE%"=="安装依赖" goto :INSTALL_DEPENDENCIES
if "%STAGE%"=="下载模型" goto :DOWNLOAD_MODELS
if "%STAGE%"=="运行" goto :RUN

:SUBMODULE
echo 初始化子模块
echo 初始化子模块>%STAGE_FILE%
git submodule update --init --recursive
if %ERRORLEVEL% neq 0 echo 致命错误 && pause && exit

:INSTALL_ENV
echo 安装环境
echo 安装环境>%STAGE_FILE%
powershell -command "$env:ONE_CLICK_RUN_PORTABLE_CONDA_SELECTEDMATCH = 'Miniconda3-py310_24.11.1-0-Windows-x86_64.exe'; irm 'https://raw.githubusercontent.com/one-click-run/portable-conda/main/init.ps1' | iex"
if %ERRORLEVEL% neq 0 echo 致命错误 && pause && exit

:PATCH
echo 应用补丁
echo 应用补丁>%STAGE_FILE%
copy .\patch\requirements.txt .\CosyVoice\
if %ERRORLEVEL% neq 0 echo 致命错误 && pause && exit

:ACTIVATE_ENV
echo 进入环境
echo 进入环境>%STAGE_FILE%
call .\OCR-portable-conda\Scripts\activate.bat
if %ERRORLEVEL% neq 0 echo 致命错误 && pause && exit

:INSTALL_DEPENDENCIES
echo 安装依赖
echo 安装依赖>%STAGE_FILE%
start /wait cmd /k "conda install -y -c conda-forge pynini==2.1.5 && exit || exit"
if %ERRORLEVEL% neq 0 echo 致命错误 && pause && exit
cd CosyVoice && pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host=mirrors.aliyun.com && cd ..
if %ERRORLEVEL% neq 0 echo 致命错误 && pause && exit

:DOWNLOAD_MODELS
echo 下载模型
echo 下载模型>%STAGE_FILE%
if not exist pretrained_models mkdir pretrained_models
if not exist pretrained_models\CosyVoice-300M-SFT git clone https://www.modelscope.cn/iic/CosyVoice-300M-SFT.git pretrained_models/CosyVoice-300M-SFT
if %ERRORLEVEL% neq 0 echo 致命错误 && pause && exit
if not exist pretrained_models\CosyVoice2-0.5B git clone https://www.modelscope.cn/iic/CosyVoice2-0.5B.git pretrained_models/CosyVoice2-0.5B
if %ERRORLEVEL% neq 0 echo 致命错误 && pause && exit

:RUN
echo 请选择模型:
echo "1: 使用 SFT 模型（具有预训练音色）"
echo "2: 用 V2 模型（只能进行语音复刻）"
set /p modelChoice="请输入选择的数字 (1 或 2): "
if exist "%USERPROFILE%\.cache\modelscope" rmdir /s /q "%USERPROFILE%\.cache\modelscope"
call .\OCR-portable-conda\Scripts\activate.bat
if "%modelChoice%"=="1" python .\CosyVoice\webui.py --model_dir pretrained_models\CosyVoice-300M-SFT
if "%modelChoice%"=="2" python .\CosyVoice\webui.py --model_dir pretrained_models\CosyVoice2-0.5B
if not "%modelChoice%"=="1" if not "%modelChoice%"=="2" echo 无效的选择，请重新运行程序并选择正确的模型 && pause && exit
if %ERRORLEVEL% neq 0 echo 致命错误 && pause && exit

pause
