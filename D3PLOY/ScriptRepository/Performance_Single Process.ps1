$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
$line="COMPUTERNAME	PROCESSNAME	MEM(KB)"
if (!(test-path $logfile)) {out-file $logfile -input $line}
if ($scope -eq '') {$params = @{'computername' = $computername}
}
else {$params = @{'computername' = $computername; 'credential' = $creds}
}
if (![bool]$processname) {$processname = show-inputbox -message "ProcessName?"}

$result=invoke-command @params -args $processname -scriptblock {
	param($processname)
	return get-process -name $processname| Group-Object -Property ProcessName | select name, @{n='MemKB';e={'{0:N0}' -f (($_.Group|Measure-Object WorkingSet -Sum).Sum / 1KB)}}
}
if([bool]$result){
	out-file $logfile -input "$computername	$processname	$($result.memKB)" -append
}
if ($uihash.objcomputers.count -eq 0) {if([System.Windows.MessageBox]::Show("Quieres abrir el fichero $logfile ?",$uihash.tag,'YesNoCancel','Question') -eq 'Yes'){start-process $logfile}}