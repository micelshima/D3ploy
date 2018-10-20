$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$pendingreboot = $false
$HKLM = 2147483650
if ($scope -eq '') {$reg = gwmi -List -Namespace root\default -ComputerName $computername | Where-Object {$_.Name -eq "StdRegProv"}}
else {$reg = gwmi -List -Namespace root\default -ComputerName $computername -Credential $creds | Where-Object {$_.Name -eq "StdRegProv"}}

if ($reg.Enumkey($HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update").snames -contains "RebootRequired") {$pendingreboot = $true}
elseif ($reg.Enumkey($HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing").snames -contains "RebootPending") {$pendingreboot = $true}
elseif ($reg.GetStringValue($HKLM, "SYSTEM\CurrentControlSet\Control\Session Manager", "PendingFileRenameOperations").sValue) {$pendingreboot = $true}
elseif ($reg.GetStringValue($HKLM, "SOFTWARE\Wow6432Node\Sophos\AutoUpdate\UpdateStatus\VolatileFlags", "RebootRequired").sValue) {$pendingreboot = $true}

if ($pendingreboot -eq $true) {
	out-textblock -ComputerName $computername -Source $scriptbasename -Message "Reiniciando $computername" -logfile 'ps1command.log'
	if ($scope -eq '') {restart-computer -computername $computername -force -confirm:$false}
	else {restart-computer -computername $computername -credential $creds -force -confirm:$false}
}
else {
	out-textblock -ComputerName $computername -Source $scriptbasename -Message "No es necesario reiniciar $computername" -MessageType 'OK' -logfile 'ps1command.log'
}