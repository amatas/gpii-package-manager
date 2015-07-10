# GPII Windows install and upgrade

## 1. Packages

GPII for windows is installed using some "msi" packages. These packages must have the following features:

* Can be installed and uninstalled silently, without user interaction.
* Can be upgraded from previous versions silently.

[this section can be extended with the build process of the GPII msi package]

## 2. Package manager

### Server side

Chocolatey needs a server to store the .nupkg packages and the files that downloads in a installation procedure.

The Nuget server provides an API to push, search and download the packages. In this case we are going to use a simple server:

(https://github.com/Daniel15/simple-nuget-server)

It can run in Linux and only needs a Nginx with PHP, uses a sqlite database to store the metadata of the packages.

The steps to install the server are in the [README.md](https://github.com/Daniel15/simple-nuget-server/blob/master/README.md) of that the repository. Then, we only need to configure our Chocolatey instance to push the generated packages:

```
choco setApiKey -Source "https://choco.gpii.net/" ApiKeySettedOnServer
```

### Client side

The packages can be installed and upgraded using Chocolatey. To do so, we need to create the Chocolatey packages that wrap the install, uninstall and upgrade processes of msi packages.

A Chocolatey package source needs 3 files:

#### 1. [package.nuspec](Templates/package.nuspec)

 This file contains the metadata of the package. The version and the name of the package shown in the Chocolatey database are set here, among other fields like authors, lincense data,..
 
 ```
 chocolatey install -y gpii
 chocolatey upgrade -y --clean gpii
 ```
 
 Chocolatey uses the version field of this file to decide if a package should be upgraded. It assumes that the msi package associated will upgrade the application when the installation command is launched.

#### 2. [chocolateyinstall.ps1](Templates/tools/chocolateyinstall.ps1)

 Is the script that Chocolatey will run to install the package. It's a powershell script so, in the theory, we can exec additional commands in the case we need them.

 The most important command is [Install-ChocolateyPackage](https://github.com/chocolatey/choco/wiki/HelpersInstallChocolateyPackage) that downloads and install the msi package using some parameters.

#### 3. [chocolateyuninstall.ps1](Templates/tools/chocolateyuninstall.ps1)

 This script is similar to chocolateyinstall.ps1, but in this case it's used to uninstall the application. It uses the GUID of the installed msi ($msiProductCodeGuid variable) to call the uninstall command.

 A tip to know the GUID of a msi installed can be:
 ```
 get-wmiobject Win32_Product -Filter "name='GPII'" | Format-Table IdentifyingNumber, Name
 ```
 Once all the files are setted, we need to run:
 ```
 PS C:\chocolate\gpii> ls

    Directory: C:\chocolate\gpii

 Mode                LastWriteTime     Length Name
 ----                -------------     ------ ----
 d----          7/8/2015   7:23 PM            tools
 -a---         7/10/2015   1:16 PM       2065 gpii.nuspec

 PS C:\chocolate\gpii> cpack.exe
 Chocolatey v0.9.9.8
 Attempting to build package from 'gpii.nuspec'.
 Successfully created package 'gpii.1.0.0.nupkg'
 ```

 Then we push the package to the Chocolatey private server:
 ```
 choco push .\gpii.1.0.0.nupkg -source "https://choco.gpii.net/"
 ```

## 3. Installation and upgrade

1. Install Chocolatey
```
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
```

2. Configure Chocolatey
```
$chocoConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<chocolatey xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <cacheLocation />
  <containsLegacyPackageInstalls>true</containsLegacyPackageInstalls>
  <commandExecutionTimeoutSeconds>2700</commandExecutionTimeoutSeconds>
  <sources>
    <source id="chocolatey" value="https://chocolatey.org/api/v2/" disabled="false" />
    <source id="gpii" value="http://choco.gpii.net/" disabled="false" />
  </sources>
  <features>
    <feature name="checksumFiles" enabled="true" setExplicitly="false" />
    <feature name="autoUninstaller" enabled="true" setExplicitly="true" />
    <feature name="allowGlobalConfirmation" enabled="false" setExplicitly="false" />
    <feature name="failOnAutoUninstaller" enabled="false" setExplicitly="false" />
  </features>
</chocolatey>
"@
set-content C:\ProgramData\chocolatey\config\chocolatey.config $chocoConfig
```

3. Install nodejs
```
$ChocoExe = '{0}\ProgramData\chocolatey\bin\choco.exe' -f $env:SystemDrive;
Start-Process -NoNewWindow -Wait $ChocoExe -ArgumentList "install -y vcredist2010 -forcex86"
Start-Process -NoNewWindow -Wait $ChocoExe -ArgumentList "install -y npm -forcex86"
Start-Process -NoNewWindow -Wait $ChocoExe -ArgumentList "install -y nodejs -version 0.10.36 -forcex86"
```

4. Set firewall rule
```
$NodeExe = '{0}\ProgramData\chocolatey\bin\node.exe' -f $env:SystemDrive;
New-NetFirewallRule -DisplayName "NodeJS" -action allow -Direction Inbound -Program $NodeExe;
Enable-NetFirewallRule -DisplayName "NodeJS";
```

5. Install GPII packages
```
$ChocoExe = '{0}\ProgramData\chocolatey\bin\choco.exe' -f $env:SystemDrive;
Start-Process -NoNewWindow -Wait $ChocoExe -ArgumentList "install -y gpii --version 1.0.0"
```

6. Set scheduled task that calls the upgrade command
```
$jobname = "Update GPII Task";
$sb = {
  Start-Process -NoNewWindow -Wait 'C:\ProgramData\chocolatey\bin\choco.exe' -ArgumentList 'upgrade -y -clean all'
}
$trigger = New-JobTrigger -AtStartup -RandomDelay 00:01:00;
$options = New-ScheduledJobOption -RequireNetwork -RunElevated;
$result = Get-ScheduledJob | Where { $_.Name -eq "$jobName" } ;
if ($result) {
  Unregister-ScheduledJob -Name "$jobName" ;
}
Register-ScheduledJob -Name $jobname -ScriptBlock $sb -Trigger $trigger -ScheduledJobOption $options;
```

All these steps are in the [install.ps1](install.ps1) script

## 4. Testing

It's recommended to do some tests when a new package is built. Some of the recommended tests are:

* Install msi package using the command line:
```
msiexec /i package.msi /qn
```
* Uninstall the msi package using the command line:
```
msiexec /X{GUID} /qn
```
* Install an old version of the package and try to upgrade with the command line:
```
msiexec /i new_version_package.msi /qn
```
* Install the Chocolatey package
* Remove the Chocolatey package
* Install an old version of the Chocolatey package and try to upgrade
* Remove the package once has been upgraded.
* Test automatic upgrade
