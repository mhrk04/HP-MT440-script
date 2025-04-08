@echo off
REM === Restrict all removable media for Computer ===
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices" /v Deny_All /t REG_DWORD /d 1 /f

REM === Restrict all removable media for User ===
reg add "HKCU\Software\Policies\Microsoft\Windows\RemovableStorageDevices" /v Deny_All /t REG_DWORD /d 1 /f

REM === Wait for changes to apply (optional) ===
timeout /t 2 >nul

REM === Open Group Policy Editor to verify settings ===
start gpedit.msc
