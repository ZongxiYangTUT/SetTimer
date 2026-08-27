#ifndef AppVersion
  #error AppVersion is required. Build with scripts\build-release.ps1.
#endif
#ifndef AppVersionQuad
  #error AppVersionQuad is required. Build with scripts\build-release.ps1.
#endif
#ifndef KokoroModelDirectory
  #error KokoroModelDirectory is required. Build with scripts\build-release.ps1.
#endif

#define AppName "SetTimer"
#define AppPublisher "ZongxiYangTUT"
#define AppUrl "https://github.com/ZongxiYangTUT/SetTimer"
#define KokoroModelName "kokoro-int8-multi-lang-v1_1"

[Setup]
AppId={{AD98ABF2-1376-4758-9AD6-955DEDBC7155}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}/issues
AppUpdatesURL={#AppUrl}/releases
DefaultDirName={localappdata}\Programs\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
LicenseFile=LICENSE
SourceDir=..\..
OutputDir=release
OutputBaseFilename=SetTimer-{#AppVersion}-windows-x64-setup
SetupIconFile=src\settimer\assets\icon.ico
UninstallDisplayIcon={app}\SetTimer.exe
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
PrivilegesRequired=lowest
CloseApplications=yes
CloseApplicationsFilter=SetTimer.exe
RestartApplications=no
VersionInfoVersion={#AppVersionQuad}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription=SetTimer 安装程序
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#AppVersion}
VersionInfoCopyright=Copyright (c) 2026 {#AppPublisher}

[Languages]
Name: "chinesesimp"; MessagesFile: "packaging\windows\ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "完整安装（推荐）"
Name: "compact"; Description: "精简安装"
Name: "custom"; Description: "自定义安装"; Flags: iscustom

[Components]
Name: "core"; Description: "SetTimer 主程序"; Types: full compact custom; Flags: fixed
Name: "kokoro"; Description: "Kokoro 离线中文声音（约 205 MB）"; Types: full

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "快捷方式："; Flags: unchecked

[InstallDelete]
Type: filesandordirs; Name: "{app}\_internal"

[Files]
Source: "dist\SetTimer\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: core
Source: "LICENSE"; DestDir: "{app}\licenses"; DestName: "SetTimer-LICENSE.txt"; Flags: ignoreversion; Components: core
Source: "packaging\windows\THIRD_PARTY_NOTICES.txt"; DestDir: "{app}\licenses"; Flags: ignoreversion; Components: core
Source: "packaging\windows\licenses\Inno-Setup-Chinese-Simplified-Translation-LICENSE.txt"; DestDir: "{app}\licenses"; Flags: ignoreversion; Components: core
Source: "src\settimer\assets\OFL-NotoSansSC.txt"; DestDir: "{app}\licenses"; Flags: ignoreversion; Components: core
Source: "{#KokoroModelDirectory}\LICENSE"; DestDir: "{app}\licenses"; DestName: "Kokoro-LICENSE.txt"; Flags: ignoreversion; Components: core
Source: "{#KokoroModelDirectory}\*"; DestDir: "{localappdata}\SetTimer\voices\{#KokoroModelName}"; Flags: ignoreversion recursesubdirs createallsubdirs onlyifdoesntexist uninsneveruninstall; Components: kokoro

[Icons]
Name: "{autoprograms}\SetTimer"; Filename: "{app}\SetTimer.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\SetTimer"; Filename: "{app}\SetTimer.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\SetTimer.exe"; Description: "启动 SetTimer"; Flags: nowait postinstall skipifsilent
