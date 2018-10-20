$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
if (!(test-path $logfile)) {out-file $logfile -input "COMPUTERNAME	LOGNAME	TIMECREATED	ID	MESSAGE	PROPERTIES"}
if ($scope -eq '') {$params = @{'computername' = $computername}
}
else {$params = @{'computername' = $computername; 'credential' = $creds}
}
if (![bool]$logname) {$logname = show-inputbox -message "Logname? (System, Security, Application)"}
if (![bool]$eventid) {
	$eventid = show-inputbox -message "EventIDs?"
	$eventid = $eventid -split ","
}
if (![bool]$dias) {
	$dias = show-inputbox -message "Dias antiguedad?"
	$haceunrato = (get-date).adddays(-$dias)
}

try {
	get-winevent @params -FilterHashTable @{LogName = $logname; StartTime = $haceunrato; ID = $eventid} -erroraction stop| % {
		$msg = '{0}	{1}	{2}	{3}	{4} {5} {6}' -f	$computername, $_.logname, $_.TimeCreated, $_.id, ($_.message -join (". ")), $_.Properties[0].Value, $_.Properties[1].Value, $_.Properties[2].Value
		out-file $logfile -input $msg -append
	}
}
catch {
	$msg = '{0}	{1}' -f	$computername, $_.Exception.Message
	out-file $logfile -input $msg -append
}
if ($uihash.objcomputers.count -eq 0) {if([System.Windows.MessageBox]::Show("Quieres abrir el fichero $logfile ?",$uihash.tag,'YesNoCancel','Question') -eq 'Yes'){start-process $logfile}}