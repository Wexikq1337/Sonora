// Inno Setup script for Sonora (Windows).
// Build:  ISCC.exe /DAppVersion=1.0.0 tool\installer\sonora.iss
// Source: build\windows\x64\runner\Release  (produced by `flutter build windows --release`)
// Output: dist\Sonora-<version>-setup.exe   (single-file installer, per-user, no UAC)

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif

#ifndef OutputDir
  #define OutputDir "..\..\dist"
#endif

#ifndef AppExe
  #define AppExe "sonora.exe"
#endif

[Setup]
AppId={{8F3C1E52-9B4A-4D77-9A61-2E5B7C0D3A11}
AppName=Sonora
AppVersion={#AppVersion}
AppVerName=Sonora {#AppVersion}
AppPublisher=Sonora
AppPublisherURL=https://github.com/
DefaultDirName={localappdata}\Programs\Sonora
DefaultGroupName=Sonora
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir={#OutputDir}
OutputBaseFilename=Sonora-{#AppVersion}-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName=Sonora
UninstallDisplayIcon={app}\{#AppExe}
MinVersion=10.0

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Sonora"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\Sonora"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,Sonora}"; Flags: nowait postinstall skipifsilent
