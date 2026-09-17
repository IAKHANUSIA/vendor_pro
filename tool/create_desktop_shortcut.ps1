# PowerShell script to create Desktop shortcuts for Vendor Pro Web
$desktopPath = [Environment]::GetFolderPath("Desktop")
$projectDir = (Get-Item -Path $PSScriptRoot\..).FullName
$batLauncher = Join-Path $projectDir "Launch_Vendor_Pro_Web.bat"
$iconPath = Join-Path $projectDir "windows\runner\resources\app_icon.ico"

# 1. Create Windows Shell Shortcut (.lnk) pointing to the local launcher bat
$wsShell = New-Object -ComObject WScript.Shell
$shortcutPath = Join-Path $desktopPath "Vendor Pro Web (Local).lnk"
$shortcut = $wsShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $batLauncher
$shortcut.WorkingDirectory = $projectDir
if (Test-Path $iconPath) {
    $shortcut.IconLocation = "$iconPath, 0"
}
$shortcut.Description = "Vendor Pro - Newspaper & Magazine Management (Web Desktop)"
$shortcut.Save()

# 2. Create Internet Shortcut (.url) directly to GitHub Pages Live URL
$urlOnlinePath = Join-Path $desktopPath "Vendor Pro Web (GitHub Live).url"
$urlOnlineContent = @"
[InternetShortcut]
URL=https://iakhanusia.github.io/vendor_pro/
IconIndex=0
HotKey=0
IDList=
"@
if (Test-Path $iconPath) {
    $urlOnlineContent += "`nIconFile=$iconPath`nIconIndex=0"
}
Set-Content -Path $urlOnlinePath -Value $urlOnlineContent -Encoding ASCII

# 3. Create Internet Shortcut (.url) for Localhost
$urlLocalPath = Join-Path $desktopPath "Vendor Pro Web (Localhost).url"
$urlLocalContent = @"
[InternetShortcut]
URL=http://localhost:8080
IconIndex=0
HotKey=0
IDList=
"@
if (Test-Path $iconPath) {
    $urlLocalContent += "`nIconFile=$iconPath`nIconIndex=0"
}
Set-Content -Path $urlLocalPath -Value $urlLocalContent -Encoding ASCII

Write-Host "Created Desktop Shortcuts successfully with app icon:"
Write-Host "   1. $shortcutPath (Local Launcher with Server)"
Write-Host "   2. $urlOnlinePath (Live GitHub URL: https://iakhanusia.github.io/vendor_pro/)"
Write-Host "   3. $urlLocalPath (Localhost URL: http://localhost:8080)"

