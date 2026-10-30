; Inno Setup script. Built by scripts/publish-windows.ps1 / GitHub Actions.
; Produces SolidCraftAgent-Setup-r{Revision}.exe

#ifndef AppVersion
  #define AppVersion "1.0.1"
#endif
#ifndef AppRevision
  #define AppRevision "1"
#endif
#ifndef SourceDir
  #define SourceDir "..\dist\publish"
#endif
#ifndef OutDir
  #define OutDir "..\dist"
#endif

[Setup]
AppId={{8F3C2A91-6D4E-4B1F-9C70-A1B2C3D4E5F6}
AppName=SolidCraft Agent
AppVersion={#AppVersion}
AppVerName=SolidCraft Agent r{#AppRevision}
AppPublisher=SolidCraft Agent
DefaultDirName={autopf}\SolidCraftAgent
DefaultGroupName=SolidCraft Agent
DisableProgramGroupPage=yes
OutputDir={#OutDir}
OutputBaseFilename=SolidCraftAgent-Setup-r{#AppRevision}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
UninstallDisplayIcon={app}\SolidCraftAgent.exe
SetupIconFile=
VersionInfoVersion={#AppVersion}.0
VersionInfoProductVersion={#AppVersion}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\SolidCraft Agent"; Filename: "{app}\SolidCraftAgent.exe"
Name: "{autodesktop}\SolidCraft Agent"; Filename: "{app}\SolidCraftAgent.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\SolidCraftAgent.exe"; Description: "Launch SolidCraft Agent"; Flags: nowait postinstall skipifsilent
