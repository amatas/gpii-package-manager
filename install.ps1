# Install Chocolatey
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

# Configure Chocolatey
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

# Install nodejs

$ChocoExe = '{0}\ProgramData\chocolatey\bin\choco.exe' -f $env:SystemDrive;
Start-Process -NoNewWindow -Wait $ChocoExe -ArgumentList "install -y vcredist2010 -forcex86"
Start-Process -NoNewWindow -Wait $ChocoExe -ArgumentList "install -y npm -forcex86"
Start-Process -NoNewWindow -Wait $ChocoExe -ArgumentList "install -y nodejs -version 0.10.36 -forcex86"

# Set firewall rule

$NodeExe = '{0}\ProgramData\chocolatey\bin\node.exe' -f $env:SystemDrive;
New-NetFirewallRule -DisplayName "NodeJS" -action allow -Direction Inbound -Program $NodeExe;
Enable-NetFirewallRule -DisplayName "NodeJS";

# Install GPII packages

$ChocoExe = '{0}\ProgramData\chocolatey\bin\choco.exe' -f $env:SystemDrive;
Start-Process -NoNewWindow -Wait $ChocoExe -ArgumentList "install -y gpii --version 1.0.0"

# Set scheduled task that calls the upgrade command

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