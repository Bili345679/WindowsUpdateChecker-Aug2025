@echo off
setlocal enabledelayedexpansion

:: 定义要检查的更新列表
set "updates=KB5063709 KB5063877 KB5063871 KB5063889 KB5063878 KB5063875"
set "installed_updates="
set "installed_count=0"

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
            set "installed_updates=!installed_updates! %%u"
            set /a "installed_count+=1"
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

:: 如果有已安装的更新，询问是否要卸载
if !installed_count! gtr 0 (
    echo.
    echo Found !installed_count! installed update^(s^): !installed_updates!
    echo.
    set /p "choice=Do you want to uninstall these updates? (Y/N): "
    
    if /i "!choice!"=="Y" (
        echo.
        echo Starting uninstall process...
        echo -----------------------------------------
        
        :: 使用更可靠的管理员权限检测方法
        fsutil dirty query %systemdrive% >nul 2>&1
        if !errorlevel! neq 0 (
            echo [ERROR] This operation requires administrator privileges.
            echo Please run this script as administrator by:
            echo 1. Right-click on the .bat file
            echo 2. Select "Run as administrator"
            echo -----------------------------------------
            pause
            exit /b 1
        )
        
        echo [INFO] Administrator privileges confirmed.
        echo [NOTE] Will try multiple uninstall methods if needed.
        echo.
        
        :: 逐个卸载已安装的更新
        for %%u in (!installed_updates!) do (
            :: 提取 KB 号码（去掉 "KB" 前缀）
            set "kb_number=%%u"
            set "kb_number=!kb_number:KB=!"
            
            echo Processing %%u ^(KB number: !kb_number!^)...
            set "uninstall_success=false"
            
            :: 方法1: 尝试交互式 wusa
            echo [1/3] Trying wusa method...
            wusa /uninstall /kb:!kb_number! /norestart
            set "wusa_result=!errorlevel!"
            
            if !wusa_result! == 0 (
                echo [O] wusa completed successfully for %%u
                set "uninstall_success=true"
            ) else if !wusa_result! == 2359302 (
                echo [!] Update %%u is not installed or already removed
                set "uninstall_success=true"
            ) else (
                :: 显示 wusa 失败的原因
                if !wusa_result! == 1223 (
                    echo [!] wusa failed: User cancelled the operation
                ) else if !wusa_result! == 2359303 (
                    echo [!] wusa failed: Protected system update
                ) else if !wusa_result! == 87 (
                    echo [!] wusa failed: Invalid parameter
                ) else (
                    echo [!] wusa failed ^(Error: !wusa_result!^)
                )
                
                :: 方法2: 尝试 DISM 方法
                echo [2/3] Trying DISM method...
                set "dism_success=false"
                
                :: 创建临时文件来存储 DISM 输出
                set "temp_file=%temp%\dism_packages.txt"
                
                echo [INFO] Querying DISM packages ^(this may take a moment^)...
                dism /online /get-packages /format:table > "!temp_file!" 2>nul
                
                if exist "!temp_file!" (
                    echo [INFO] Searching for packages containing KB!kb_number!...
                    
                    :: 搜索包含 KB 号码的行
                    for /f "tokens=*" %%p in ('findstr /i "!kb_number!" "!temp_file!" 2^>nul') do (
                        set "package_line=%%p"
                        :: 提取包名称（第一列）
                        for /f "tokens=1" %%n in ("!package_line!") do (
                            set "package_name=%%n"
                            :: 确保这是一个有效的包名称而不是标题行
                            echo !package_name! | findstr /R "Package_" >nul
                            if !errorlevel! == 0 (
                                echo [INFO] Found DISM package: !package_name!
                                echo [INFO] Attempting removal...
                                dism /online /remove-package /packagename:!package_name! /quiet /norestart
                                if !errorlevel! == 0 (
                                    echo [O] Successfully removed %%u using DISM
                                    set "uninstall_success=true"
                                    set "dism_success=true"
                                    goto :cleanup_temp
                                ) else (
                                    echo [!] Failed to remove package !package_name!
                                )
                            )
                        )
                    )
                    
                    :cleanup_temp
                    del "!temp_file!" 2>nul
                    
                    if "!dism_success!"=="false" (
                        echo [X] No removable DISM packages found for %%u
                    )
                ) else (
                    echo [X] Failed to query DISM packages
                )
                
                :: 方法3: 尝试直接从注册表查找卸载信息
                if "!uninstall_success!"=="false" (
                    echo [3/3] Trying registry-based method...
                    
                    :: 查找更新的卸载字符串
                    for /f "skip=2 tokens=2*" %%r in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "%%u" /d 2^>nul ^| findstr /i "UninstallString"') do (
                        set "uninstall_cmd=%%s"
                        if not "!uninstall_cmd!"=="" (
                            echo [INFO] Found uninstall command: !uninstall_cmd!
                            echo [WARNING] This will attempt to run the official uninstaller
                            set /p "reg_choice=Execute uninstaller for %%u? (Y/N): "
                            if /i "!reg_choice!"=="Y" (
                                echo [INFO] Running uninstaller...
                                !uninstall_cmd! /quiet /norestart
                                if !errorlevel! == 0 (
                                    echo [O] Registry method succeeded for %%u
                                    set "uninstall_success=true"
                                ) else (
                                    echo [!] Registry method failed for %%u
                                )
                            ) else (
                                echo [INFO] Registry method skipped by user
                            )
                        )
                    )
                    
                    if "!uninstall_success!"=="false" (
                        echo [X] No registry uninstaller found for %%u
                    )
                )
            )
            
            :: 显示每个更新的最终结果
            if "!uninstall_success!"=="true" (
                echo [RESULT] [SUCCESS] %%u - UNINSTALL COMPLETED
            ) else (
                echo [RESULT] [FAILED] %%u - ALL METHODS FAILED
                echo [INFO] This update may be:
                echo        - Part of a larger cumulative update
                echo        - A system-critical component
                echo        - Superseded by newer updates
                echo [TIP] Try manual removal via:
                echo       Settings ^> Update ^& Security ^> Windows Update ^> View update history ^> Uninstall updates
            )
            
            echo.
            timeout /t 2 >nul
        )
        
        echo -----------------------------------------
        echo Uninstall process completed.
        echo.
        echo Verifying results...
        
        :: 重新检查更新状态
        set "still_installed="
        set "successfully_removed="
        
        for /f "tokens=*" %%i in ('wmic qfe get HotFixID ^| findstr /R "^KB"') do (
            set "line=%%i"
            for %%u in (!installed_updates!) do (
                echo !line! | findstr /C:"%%u" >nul
                if !errorlevel! == 0 (
                    set "still_installed=!still_installed! %%u"
                )
            )
        )
        
        :: 确定真正被移除的更新
        for %%u in (!installed_updates!) do (
            set "found_still=false"
            for %%s in (!still_installed!) do (
                if "%%u"=="%%s" set "found_still=true"
            )
            if "!found_still!"=="false" (
                set "successfully_removed=!successfully_removed! %%u"
            )
        )
        
        echo.
        echo === VERIFICATION RESULTS ===
        if defined successfully_removed (
            echo [SUCCESS] Actually removed:!successfully_removed!
        )
        if defined still_installed (
            echo [STILL PRESENT] Still installed:!still_installed!
        )
        if not defined still_installed (
            echo [SUCCESS] All targeted updates have been removed!
        )
        
        echo.
        set /p "restart_choice=Restart now to finalize changes? (Y/N): "
        
        if /i "!restart_choice!"=="Y" (
            echo Restarting in 10 seconds... Press Ctrl+C to cancel.
            timeout /t 10
            shutdown /r /t 0 /c "Restarting to finalize update removal"
        ) else (
            echo Please restart manually when convenient.
        )
    ) else (
        echo Uninstall cancelled.
    )
) else (
    echo.
    echo No target updates found installed on this system.
)

echo.
pause
