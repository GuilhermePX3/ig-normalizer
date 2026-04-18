; ============================================================
;  ig-normalizer — Inno Setup script
;
;  Produces a single self-contained Setup EXE that:
;    * Installs ig-normalizer.exe in Program Files
;    * Registers right-click context menu in Windows Explorer
;    * Adds the install dir to the system PATH
;    * Creates a full Uninstaller (visible in Apps & Features)
;
;  Requirements:
;    - Inno Setup 6+  https://jrsoftware.org/isinfo.php
;    - dist\ig-normalizer.exe  (built by PyInstaller first)
;
;  Build steps:
;    1. .\build.ps1   (or build.bat)   → runs PyInstaller
;    2. ISCC.exe installer\ig-normalizer.iss
;       (build.ps1 does this automatically if ISCC is found)
; ============================================================

#define MyAppName      "ig-normalizer"
#define MyAppVersion   "1.0.0"
#define MyAppPublisher "igpsp"
#define MyAppURL       "https://github.com/igpsp/ig-normalizer"
#define MyAppExeName   "ig-normalizer.exe"
#define MyAppExePath   "..\dist\ig-normalizer.exe"

[Setup]
AppId={{A3F2C8D1-4B6E-4F7A-9D2C-1E5B8A3F0C7D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
VersionInfoVersion={#MyAppVersion}
VersionInfoDescription=Remove accents and special characters from filenames and file contents
VersionInfoCopyright=igpsp

; Install location
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes

; Output
OutputDir=output
OutputBaseFilename=ig-normalizer-setup-{#MyAppVersion}
; SetupIconFile=..\assets\icon.ico   ; uncomment when you have an .ico

; Compression
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
WizardResizable=no

; Privileges — required for Program Files + HKLM registry
PrivilegesRequired=admin
MinVersion=6.1          ; Windows 7+
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; Uninstall entry shown in Apps & Features / Programs & Features
UninstallDisplayName={#MyAppName} {#MyAppVersion}
UninstallDisplayIcon={app}\{#MyAppExeName}
CreateUninstallRegKey=yes

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "contextmenu"; Description: "Adicionar ao menu de contexto do Windows Explorer"; GroupDescription: "Integração com o Explorer:"; Flags: checked
Name: "addtopath";   Description: "Adicionar ao PATH do sistema (usar no terminal)";    GroupDescription: "Integração com o Explorer:"; Flags: checked

[Files]
; Main executable — single self-contained binary (no Python required)
Source: {#MyAppExePath}; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}";            Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Desinstalar {#MyAppName}"; Filename: "{uninstallexe}"

[Registry]
; ---------------------------------------------------------------
;  FOLDER — right-click on a folder icon in Explorer
; ---------------------------------------------------------------
Root: HKLM; Subkey: "SOFTWARE\Classes\Directory\shell\ig-normalizer"; \
    ValueType: string; ValueName: ""; \
    ValueData: "Normalizar Acentos (ig-normalizer)"; \
    Flags: uninsdeletekey; Tasks: contextmenu

Root: HKLM; Subkey: "SOFTWARE\Classes\Directory\shell\ig-normalizer"; \
    ValueType: string; ValueName: "Icon"; \
    ValueData: "{app}\{#MyAppExeName},0"; \
    Tasks: contextmenu

Root: HKLM; Subkey: "SOFTWARE\Classes\Directory\shell\ig-normalizer"; \
    ValueType: string; ValueName: "AppliesTo"; \
    ValueData: "System.FileName:*"; \
    Tasks: contextmenu

Root: HKLM; Subkey: "SOFTWARE\Classes\Directory\shell\ig-normalizer\command"; \
    ValueType: string; ValueName: ""; \
    ValueData: "cmd.exe /k ""{app}\{#MyAppExeName}"" ""%1"" --verbose & pause"; \
    Flags: uninsdeletekey; Tasks: contextmenu

; ---------------------------------------------------------------
;  FOLDER BACKGROUND — right-click inside an open folder window
; ---------------------------------------------------------------
Root: HKLM; Subkey: "SOFTWARE\Classes\Directory\Background\shell\ig-normalizer"; \
    ValueType: string; ValueName: ""; \
    ValueData: "Normalizar Acentos aqui (ig-normalizer)"; \
    Flags: uninsdeletekey; Tasks: contextmenu

Root: HKLM; Subkey: "SOFTWARE\Classes\Directory\Background\shell\ig-normalizer"; \
    ValueType: string; ValueName: "Icon"; \
    ValueData: "{app}\{#MyAppExeName},0"; \
    Tasks: contextmenu

Root: HKLM; Subkey: "SOFTWARE\Classes\Directory\Background\shell\ig-normalizer\command"; \
    ValueType: string; ValueName: ""; \
    ValueData: "cmd.exe /k ""{app}\{#MyAppExeName}"" ""%V"" --verbose & pause"; \
    Flags: uninsdeletekey; Tasks: contextmenu

; ---------------------------------------------------------------
;  PATH — add install dir so the CLI works in any terminal
; ---------------------------------------------------------------
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; \
    ValueType: expandsz; ValueName: "Path"; \
    ValueData: "{olddata};{app}"; \
    Check: NeedsAddPath('{app}'); Tasks: addtopath

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
// Helper: only append to PATH if the directory isn't already there
function NeedsAddPath(Param: string): boolean;
var
  OrigPath: string;
begin
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE,
    'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'Path', OrigPath)
  then begin
    Result := True;
    exit;
  end;
  Result := Pos(';' + Uppercase(Param) + ';',
               ';' + Uppercase(OrigPath) + ';') = 0;
end;

// Remove our directory from PATH on uninstall
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  OldPath, NewPath, Dir: string;
  P: Integer;
begin
  if CurUninstallStep <> usPostUninstall then exit;

  Dir := ExpandConstant('{app}');
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE,
    'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'Path', OldPath)
  then exit;

  NewPath := OldPath;

  // Remove  ";Dir"  or  "Dir;"  variants
  P := Pos(';' + Uppercase(Dir), Uppercase(NewPath));
  if P > 0 then
    Delete(NewPath, P, Length(';' + Dir))
  else begin
    P := Pos(Uppercase(Dir) + ';', Uppercase(NewPath));
    if P > 0 then Delete(NewPath, P, Length(Dir + ';'));
  end;

  if NewPath <> OldPath then
    RegWriteStringValue(HKEY_LOCAL_MACHINE,
      'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
      'Path', NewPath);
end;
