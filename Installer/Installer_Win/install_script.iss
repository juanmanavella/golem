; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "Golem"
#define MyAppPublisher "Golem Factory GmbH"
#define MyAppURL "https://golem.network"
#define MyAppExeName "golemapp.exe"
; NOTE: if compilation failed, make sure that this variable are set properly and golem is installed from wheel
; NOTE 2: make sure that you've got in {#Repository}\Installer\Inetaller_Win\deps:
; https://www.microsoft.com/en-us/download/details.aspx?id=40784 vcredist_x86.exe
; https://www.microsoft.com/en-us/download/details.aspx?id=44266
; https://download.docker.com/win/stable/InstallDocker.msi
#define Repository "C:\golem"
#expr Exec("powershell.exe python setup.py pyinstaller", "", Repository, 1)
#expr Exec("powershell.exe python Installer\Installer_Win\version.py", "", Repository, 1)
#define MyAppVersion ReadIni(Repository+"\\.version.ini", "version", "version", "0.1.0")
#expr Exec("powershell.exe Remove-Item .version.ini", "", Repository, 1)
#define AppIcon "favicon.ico"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{C8E494CC-06C7-40CB-827A-20D07903013F}
AppName={#MyAppName}
AppPublisher={#MyAppPublisher}
AppVersion={#MyAppVersion}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DisableProgramGroupPage=yes
LicenseFile={#Repository}\LICENSE.txt
OutputDir={#Repository}\Installer\Installer_Win
OutputBaseFilename=setup
SetupIconFile={#Repository}\Installer\{#AppIcon}
Compression=lzma
SolidCompression=yes

[Registry]
; Set environment variable to point to company installation
Root: "HKLM64"; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: string; ValueName: "GOLEM"; ValueData: "{sd}\Python27\Scripts\golemapp.exe"; Flags: uninsdeletevalue;
 
; Append Docker to PATH
Root: "HKLM64"; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: expandsz; ValueName: "PATH"; ValueData: "{olddata};{sd}\Program Files\Docker Toolbox";

; Add OpenSSL to the PATH
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: expandsz; ValueName: "PATH"; ValueData: "{olddata};{sd}\OpenSSL"; Check: NeedsAddPath('{sd}\OpenSSL')

; @todo do we need any more languages? It can be confusing
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 0,6.1
                                               
[Files]
Source: "{#Repository}\dist\*"; DestDir: {app};
Source: "{#Repository}\Installer\Installer_Win\deps\DockerToolbox.exe"; DestDir: "{tmp}"; Flags: ignoreversion; 
Source: "{#Repository}\Installer\Installer_Win\deps\geth-windows-amd64-1.5.9-a07539fb.exe"; DestDir: "{tmp}"; Flags: ignoreversion;      
Source: "{#Repository}\Installer\Installer_Win\deps\vcredist_x86.exe"; DestDir: "{tmp}"; Flags: ignoreversion;
Source: "{#Repository}\Installer\Installer_Win\deps\OpenSSL\HashInfo.txt"; DestDir: "{sd}\OpenSSL"; Flags: ignoreversion;
Source: "{#Repository}\Installer\Installer_Win\deps\OpenSSL\libeay32.dll"; DestDir: "{sd}\OpenSSL"; Flags: ignoreversion;
Source: "{#Repository}\Installer\Installer_Win\deps\OpenSSL\OpenSSL License.txt"; DestDir: "{sd}\OpenSSL"; Flags: ignoreversion;
Source: "{#Repository}\Installer\Installer_Win\deps\OpenSSL\ReadMe.txt"; DestDir: "{sd}\OpenSSL"; Flags: ignoreversion;   
Source: "{#Repository}\Installer\Installer_Win\deps\OpenSSL\ssleay32.dll"; DestDir: "{sd}\OpenSSL"; Flags: ignoreversion;
Source: "{#SetupSetting("SetupIconFile")}"; DestDir: "{app}"; Flags: ignoreversion;

[Icons]
Name: "{commonprograms}\{#MyAppName}"; Filename: "{app}\golemapp.exe"; IconFilename: "{app}\{#AppIcon}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\golemapp.exe"; IconFilename: "{app}\{#AppIcon}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\golemapp.exe"; IconFilename: "{app}\{#AppIcon}"; Tasks: quicklaunchicon

[Run]
; Install runtime
Filename: "{tmp}\vcredist_x86.exe"; StatusMsg: "Installing runtime"; Description: "Install runtime"
                                     
; Install Docker @todo is this check enough
Filename: "{tmp}\DockerToolbox.exe"; Parameters: "/SILENT"; StatusMsg: "Installing Docker Toolbox"; Description: "Install Docker Toolbox"; Check: IsDockerInstalled 
; @todo how to install ipfs

; Install geth
Filename: "{tmp}\geth-windows-amd64-1.5.9-a07539fb.exe"; StatusMsg: "Installing geth"; Description: "Install geth"       

[Code]
                                                                              
// This function checks the registry for an existing Docker installation
function IsDockerInstalled: boolean;
begin
   Result := not RegKeyExists(HKCU64, 'Environment\DOCKER_TOOLBOX_INSTALL_PATH' );                                                                                                                         
end;
 
// This function will return True if the Param already exists in the system PATH
function NeedsAddPath(Param: String): Boolean;
var
  OrigPath: String;
 
begin
  if not RegQueryStringValue(HKLM64, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 'PATH', OrigPath) then
  begin
    Result := True;
    exit;
  end;
  
  // look for the path with leading and trailing semicolon; Pos() returns 0 if not found
  Result := Pos(';' + Param + ';', ';' + OrigPath + ';') = 0;
end;
 
 
// Check for working internet connection
function CheckInternetConnection(Param: String) : Boolean;
 
var
  WinHttpReq : Variant;
 
begin
  try
    // Create COM object to handle net connection attempt
    WinHttpReq := CreateOleObject('WinHttp.WinHttpRequest.5.1');
    WinHttpReq.Open('GET', Param, false);
    WinHttpReq.Send();
  except
    MsgBox('Could not connect to: ' + Param + '!' + #13#10 + 'Ensure that this computer has a working internet connection!', mbError, MB_OK);
end;
 
 // Check for timeout
 if WinHttpReq.Status <> 200 then begin
    MsgBox('Could not connect to' + Param + '! Connection timed out!', mbError, MB_OK);
    Result := False;
  end;
 
 if Length(WinHttpReq.ResponseText) > 0 then begin
    Result := True;
 end;
 
end;
 
 
// This method checks for presence of uninstaller entries in the registry and returns the path to the uninstaller executable.
function GetUninstallString: String;
 
var
  uninstallerPath: String;
  uninstallerString: String;
 
begin
  Result := '';
  // Get the uninstallerPath from the registry
  uninstallerPath := ExpandConstant('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{{C8E494CC-06C7-40CB-827A-20D07903013F}_is1');
  uninstallerString := '';
  // Check if uninstaller entries in registry have values in them
  if not RegQueryStringValue(HKLM64, uninstallerPath, 'UninstallString', uninstallerString) then
    RegQueryStringValue(HKCU, uninstallerPath, 'UninstallString', uninstallerString);
    // Return path of uninstaller to run  
    Result := uninstallerString;
 
end;


// This function install dependencies which couldn't be normally installed via pip on Windows
 
 
// This method checks if a previous version has been installed
function PreviousInstallationExists : Boolean;
begin
  // Check if not equal '<>' to empty string and return result
  Result := (GetUninstallString() <> '');
end;

// This Event function runs before setup is initialized
function InitializeSetup(): Boolean;

var
  checkNetCxn : Boolean;
  uninstallChoiceResult: Boolean;
  uninstallPath : String;
  iResultCode : Integer;
  previouslyInstalledCheck : Boolean;

begin
  // Connect to Python package dist server
  checkNetCxn := CheckInternetConnection('https://pypi.python.org/pypi');
  if not checkNetCxn then
  begin
    MsgBox('Please ensure that this computer has a working internet connection and try again!', mbError, MB_OK)
    Result := False;
    Exit;
  end;
 
  // Now check if previous version was installed
  previouslyInstalledCheck := PreviousInstallationExists;
  if previouslyInstalledCheck then
  begin
    uninstallChoiceResult := MsgBox('A previous installation was detected. Do you want to uninstall the previous version first? (Recommended)', mbInformation, MB_YESNO) = IDYES;
   
    // If user chooses, uninstall the previous version and wait until it has finished before allowing installation to proceed
    if uninstallChoiceResult then
    begin
      uninstallPath := RemoveQuotes(GetUninstallString());
      Exec(ExpandConstant(uninstallPath), '', '', SW_SHOW, ewWaitUntilTerminated, iResultCode);
 
      Result := True;
    end
 
    else
    begin
      Result := True;
      Exit;
    end;
  end
 
  else
    Result := True;
 
end;