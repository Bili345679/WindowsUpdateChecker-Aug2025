@echo off
setlocal enabledelayedexpansion

:: 定义要检查的更新列表
set "updates=KB5063709 KB5063877 KB5063871 KB5063889 KB5063878 KB5063875"

echo Checking for installed Windows updates...
echo -----------------------------------------

:: 获取已安装更新列表
for /f "tokens=*" %%i in ('wmic qfe get HotFixID ^| findstr /R "^KB"') do (
    set "line=%%i"
    for %%u in (%updates%) do (
        echo !line! | findstr /C:"%%u" >nul
        if !errorlevel! == 0 (
            echo [O] Update %%u is installed.
            set "found_%%u=true"
        )
    )
)

:: 检查是否有未安装的更新
for %%u in (%updates%) do (
    if not defined found_%%u (
        echo [X] Update %%u is NOT installed.
    )
)

echo -----------------------------------------
echo Check complete.
pause

