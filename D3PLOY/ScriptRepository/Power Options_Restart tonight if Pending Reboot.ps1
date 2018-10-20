$scriptbasename=$MyInvocation.Mycommand.name.substring(0,$MyInvocation.Mycommand.name.lastindexof('.'))
if($scope -ne ''){$credsplain=select-MiCredential -scope $scope -plain}

$pendingreboot=$false
$HKLM = 2147483650
if($scope -eq ''){$reg = gwmi -List -Namespace root\default -ComputerName $computername | Where-Object {$_.Name -eq "StdRegProv"}}
else{$reg = gwmi -List -Namespace root\default -ComputerName $computername -Credential $creds | Where-Object {$_.Name -eq "StdRegProv"}}

if($reg.Enumkey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update").snames -contains "RebootRequired"){$pendingreboot=$true}
elseif($reg.Enumkey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing").snames -contains "RebootPending"){$pendingreboot=$true}
elseif($reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\Session Manager","PendingFileRenameOperations").sValue){$pendingreboot=$true}
elseif($reg.GetStringValue($HKLM,"SOFTWARE\Wow6432Node\Sophos\AutoUpdate\UpdateStatus\VolatileFlags","RebootRequired").sValue){$pendingreboot=$true}

if ($pendingreboot -eq $true)
{
out-textblock -ComputerName $computername -Source $scriptbasename -Message "Programando reinicio nocturno" -logfile 'ps1command.log'
if($scope -eq ''){schtasks /create /S $computername /RU SYSTEM /SC ONCE /TN ReinicioEstaNoche /TR "shutdown.exe /r /t 0 /f" /ST 23:00 /F}
else{schtasks /create /S $computername /U $credsplain.username /P "$($credsplain.password)" /RU SYSTEM /SC ONCE /TN ReinicioEstaNoche /TR "shutdown.exe /r /t 0 /f" /ST 23:00 /F}
}
else{out-textblock -ComputerName $computername -Source $scriptbasename -Message "No es necesario reiniciarlo" -MessageType 'OK' -logfile 'ps1command.log'}