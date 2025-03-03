; Mettech-Explorer.nsi
;
; This script is based on example1.nsi but it remembers the directory, 
; has uninstall support and (optionally) installs start menu shortcuts.
;
; It will install Mettech-Explorer.nsi into a directory that the user selects.
;
; See install-shared.nsi for a more robust way of checking for administrator rights.
; See install-per-user.nsi for a file association example.

;--------------------------------

; The name of the installer
Name "Mettech-Explorer"

; The file to write
OutFile "Setup Mettech-Explorer.exe"

; Request application privileges for Windows Vista and higher
RequestExecutionLevel admin

; Build Unicode installer
Unicode True

; The default installation directory
InstallDir $PROGRAMFILES\Mettech-Explorer

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\NSIS_Mettech-Explorer" "Install_Dir"

;--------------------------------

; Pages

Page components
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

;--------------------------------

; The stuff to install
Section "Mettech-Explorer (required)"

  SectionIn RO
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  
  ; Put file there
  File "mettech-explorer.exe"
  SetOutPath "$INSTDIR\static"
  File /r "./static/*.*"
  
  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\NSIS_Mettech-Explorer "Install_Dir" "$INSTDIR"

  ; Добавить программу в автозапуск для текущего пользователя
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "Mettech-Explorer" '"$INSTDIR\mettech-explorer.exe"'
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mettech-Explorer" "DisplayName" "NSIS Mettech-Explorer"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mettech-Explorer" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mettech-Explorer" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mettech-Explorer" "NoRepair" 1
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
SectionEnd

; ; Optional section (can be disabled by the user)
; Section "Start Menu Shortcuts"

;   CreateDirectory "$SMPROGRAMS\Mettech-Explorer"
;   CreateShortcut "$SMPROGRAMS\Mettech-Explorer\Uninstall.lnk" "$INSTDIR\uninstall.exe"

; SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"
  
  ; Удалить программу из автозапуска при деинсталляции
  DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "Mettech-Explorer"

  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mettech-Explorer"
  DeleteRegKey HKLM SOFTWARE\NSIS_Mettech-Explorer

  ; Remove files and uninstaller
  Delete $INSTDIR\mettech-explorer.exe
  Delete $INSTDIR\uninstall.exe

  ; Remove shortcuts, if any
  Delete "$SMPROGRAMS\Mettech-Explorer\*.lnk"

  ; Remove directories
  RMDir "$SMPROGRAMS\Mettech-Explorer"
  RMDir "$INSTDIR"

SectionEnd
