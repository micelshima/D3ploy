$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
if (!(test-path $logfile)) {out-file $logfile -input "COMPUTERNAME	SIZEMB	AVAILABLEMB	USEDMB	PERCENTUSED"}
if ($scope -eq '') {$params = @{'computername' = $computername}
}
else {$params = @{'computername' = $computername; 'credential' = $creds}
}
try {
	$result = gwmi Win32_PerfRawData_PerfOS_Memory @params -ea stop
	$FreeMB = $result.availableMBytes
	$result2 = gwmi Win32_ComputerSystem @params -ea stop
	$totalMB = $result2.TotalPhysicalMemory / 1MB
	$UsedMB = $totalMB - $FreeMB
	out-textblock -ComputerName $computername -Source $scriptbasename -Message 'RAM retrieved successfully' -logfile 'ps1command.log'
	$line = '{0}	{1:N0}	{2:N0}	{3:N0}	{4:P}' -f $computername, $totalMB, $FreeMB, $UsedMB, ($UsedMB / $totalMB)
	out-file $logfile -input $line -append
	$line|out-host
	out-textblock -ComputerName $computername -Source $scriptbasename -Message $line
	if ($uihash.objcomputers.count -eq 0) {if([System.Windows.MessageBox]::Show("Quieres abrir el fichero $logfile ?",$uihash.tag,'YesNoCancel','Question') -eq 'Yes'){start-process $logfile}}
}
catch {out-textblock -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageType 'Error' -logfile 'ps1command.log'}