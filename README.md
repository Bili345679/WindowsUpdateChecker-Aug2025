# WindowsUpdateChecker-Aug2025
Batch script to verify if critical Windows updates from August 2025 (e.g. KB5063878, KB5063709) are installed on Windows 10/11 systems.

# 🛡️ Windows 更新检查工具：2025年8月补丁扫描器（Windows 10 / 11）

## 简介
这是一个用于检查 Windows 系统是否已安装 **2025 年 8 月关键更新补丁** 的批处理脚本。该工具支持 Windows 10 和 Windows 11，特别关注可能影响硬盘（如 SSD）稳定性的补丁，例如 KB5063878、KB5063709 等。

## 功能
- 检查是否安装了指定的 KB 补丁
- 支持 Windows 10 和 Windows 11 系统
- 以管理员身份运行后自动扫描并输出结果
- 无需安装任何第三方软件

## 使用方法
1. 下载并保存脚本文件：`Check_Aug2025_WindowsUpdates.bat`
2. 右键点击文件，选择 **“以管理员身份运行”**
3. 查看命令行窗口中的检查结果

## 检查的补丁列表
- Windows 11: `KB5063878`
- Windows 10: `KB5063709`, `KB5063877`, `KB5063871`, `KB5063889`

## 注意事项
- 建议在运行前备份重要数据
- 某些系统可能禁用 `wmic` 命令，如遇问题可使用 PowerShell 版本（后续更新）
- 本工具仅用于检测，不会修改系统或卸载补丁

## 示例输出 / Sample Output

以下是运行 `CheckUpdates.bat.bat` 后的典型输出示例：
### ✅ 情况一：已安装部分更新

```
Checking for installed Windows updates...
-----------------------------------------
[O] Update KB5063709 is installed.
[O] Update KB5063878 is installed.
[X] Update KB5063877 is NOT installed.
[X] Update KB5063889 is NOT installed.
-----------------------------------------
Check complete.
```

### ❌ 情况二：未安装任何更新

```
Checking for installed Windows updates...
-----------------------------------------
[X] Update KB5063709 is NOT installed.
[X] Update KB5063878 is NOT installed.
[X] Update KB5063877 is NOT installed.
[X] Update KB5063889 is NOT installed.
-----------------------------------------
Check complete.
```

### ✅ 情况三：已安装全部更新

```
Checking for installed Windows updates...
-----------------------------------------
[O] Update KB5063709 is installed.
[O] Update KB5063878 is installed.
[O] Update KB5063877 is installed.
[O] Update KB5063889 is installed.
-----------------------------------------
Check complete.
```

## 作者声明
本脚本由 **Microsoft Copilot** 编写，旨在帮助用户快速识别潜在风险更新，提升系统安全性与稳定性。

---

# 🛡️ Windows Update Checker: August 2025 Patch Scanner (Windows 10 / 11)

## Overview
This batch script helps verify whether your Windows system has installed **critical updates released in August 2025**, which may affect SSD or HDD stability. It supports both Windows 10 and Windows 11 and checks for specific KB patches such as KB5063878 and KB5063709.

## Features
- Scans for specific KB updates
- Compatible with Windows 10 and Windows 11
- Outputs results directly in the command line
- No third-party software required

## How to Use
1. Download and save the script: `Check_Aug2025_WindowsUpdates.bat`
2. Right-click the file and select **"Run as administrator"**
3. View the scan results in the command prompt window

## Targeted KB Updates
- Windows 11: `KB5063878`
- Windows 10: `KB5063709`, `KB5063877`, `KB5063871`, `KB5063889`

## Notes
- It’s recommended to back up important data before running
- Some systems may have `wmic` disabled; a PowerShell version will be provided in future updates
- This tool is read-only and does not modify or uninstall any updates

## Author Statement
This script was written by **Microsoft Copilot**, designed to help users quickly identify potentially risky updates and improve system stability and security.
