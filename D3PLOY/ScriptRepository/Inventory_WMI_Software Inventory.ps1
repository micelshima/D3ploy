$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$HKLM = 2147483650
$logfile = "results\$($scriptbasename).csv"
if ($scope -eq '') {$params = @{'computername' = $computername}
}
else {$params = @{'computername' = $computername; 'credential' = $creds}
}
if (!(test-path $logfile)) {out-file $logfile -input "Computername	displayname	uninstallstring"}
try {
	$reg = gwmi -List -Namespace root\default @params|? {$_.Name -eq "StdRegProv"}
	foreach ($key in $reg.Enumkey($HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall").snames) {
		$displayname = $reg.GetStringValue($HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$key", "Displayname").svalue
		$uninstallstring = $reg.GetStringValue($HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$key", "uninstallstring").svalue
		if ($displayname -notmatch "Update for " -and $displayname -notmatch "Hotfix for " -and $displayname -ne $null) {
			out-file $logfile -input "$computername	$displayname	$uninstallstring" -append
		}
	}
	if ($uihash.objcomputers.count -eq 0) {if([System.Windows.MessageBox]::Show("Quieres abrir el fichero $logfile ?",$uihash.tag,'YesNoCancel','Question') -eq 'Yes'){start-process $logfile}}
}
catch {out-textblock -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageType 'Error' -logfile 'ps1command.log'}
