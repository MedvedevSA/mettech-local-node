; Mettech-node.nsi
;
; This script is based on example1.nsi but it remembers the directory, 
; has uninstall support and (optionally) installs start menu shortcuts.
;
; It will install Mettech-node.nsi into a directory that the user selects.
;
; See install-shared.nsi for a more robust way of checking for administrator rights.
; See install-per-user.nsi for a file association example.

;--------------------------------

; The name of the installer
Name "Mettech-node"

; The file to write
OutFile "Install-Mettech-node.exe"

; Request application privileges for Windows Vista and higher
RequestExecutionLevel admin

; Build Unicode installer
Unicode True

; The default installation directory
InstallDir $PROGRAMFILES\Mettech-node

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\NSIS_Mettech-node" "Install_Dir"

;--------------------------------

; Pages

Page components
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

;--------------------------------

; The stuff to install
Section "Mettech-node (required)"

  SectionIn RO
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  
  ; Put file there
  File "Mettech-node.nsi"
  SetOutPath "$INSTDIR\static"
  File /r "путь\к\static\*.*"
  
  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\NSIS_Mettech-node "Install_Dir" "$INSTDIR"
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mettech-node" "DisplayName" "NSIS Mettech-node"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mettech-node" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mettech-node" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mettech-node" "NoRepair" 1
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
SectionEnd

; Optional section (can be disabled by the user)
Section "Start Menu Shortcuts"

  CreateDirectory "$SMPROGRAMS\Mettech-node"
  CreateShortcut "$SMPROGRAMS\Mettech-node\Uninstall.lnk" "$INSTDIR\uninstall.exe"
  CreateShortcut "$SMPROGRAMS\Mettech-node\Mettech-node (MakeNSISW).lnk" "$INSTDIR\Mettech-node.nsi"

SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mettech-node"
  DeleteRegKey HKLM SOFTWARE\NSIS_Mettech-node

  ; Remove files and uninstaller
  Delete $INSTDIR\Mettech-node.nsi
  Delete $INSTDIR\uninstall.exe

  ; Remove shortcuts, if any
  Delete "$SMPROGRAMS\Mettech-node\*.lnk"

  ; Remove directories
  RMDir "$SMPROGRAMS\Mettech-node"
  RMDir "$INSTDIR"

SectionEnd
