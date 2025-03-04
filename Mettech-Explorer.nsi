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

!define APP_NAME "Mettech-Explorer"
!define EXE_NAME "${APP_NAME}.exe"

; The name of the installer
Name "${APP_NAME}"

; The file to write
OutFile "Setup ${APP_NAME}.exe"

; Request application privileges for Windows Vista and higher
RequestExecutionLevel admin

; Build Unicode installer
Unicode True

; The default installation directory
InstallDir "$PROGRAMFILES\${APP_NAME}"

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\NSIS_${APP_NAME}" "Install_Dir"

;--------------------------------

;--------------------------------
!include "MUI2.nsh"
!include "LogicLib.nsh"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES

; Настройка Finish Page с запуском приложения
!define MUI_FINISHPAGE_RUN "$INSTDIR\${EXE_NAME}"
!define MUI_FINISHPAGE_RUN_TEXT "Запустить ${APP_NAME} сейчас"
!insertmacro MUI_PAGE_FINISH

UninstPage uninstConfirm
UninstPage instfiles


!insertmacro MUI_LANGUAGE "Russian"

Section "MainSection" SEC01
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
  RMDir /r "$INSTDIR"

SectionEnd
