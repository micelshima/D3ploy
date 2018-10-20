$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
if (!(test-path $logfile)) {out-file $logfile -input "COMPUTERNAME	EDITION	VERSION	INSTANCE"}
if ($scope -eq '') {$params = @{'computername' = $computername}
}
else {$params = @{'computername' = $computername; 'credential' = $creds}
}
try {
	$reg = gwmi -List -Namespace root\default @params -ea stop| Where-Object {$_.Name -eq "StdRegProv"}
	$HKLM = 2147483650
	foreach ($instance in $reg.Enumvalues($HKLM, "SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL").snames) {
		$instname = $reg.GetStringValue($HKLM, "SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL", $instance).sValue
		$Edition = $reg.GetStringValue($HKLM, "SOFTWARE\Microsoft\Microsoft SQL Server\$instName\Setup", "Edition").sValue
		$Version = $reg.GetStringValue($HKLM, "SOFTWARE\Microsoft\Microsoft SQL Server\$instName\Setup", "Version").sValue
		$instancename = ($instname.split("."))[1]
		out-file $logfile -input "$computername	$Edition	$Version	$instancename" -append
	}
	if ($uihash.objcomputers.count -eq 0) {if([System.Windows.MessageBox]::Show("Quieres abrir el fichero $logfile ?",$uihash.tag,'YesNoCancel','Question') -eq 'Yes'){start-process $logfile}}
}
catch {out-textblock -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageType 'Error' -logfile 'ps1command.log'}









