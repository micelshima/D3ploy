$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
$line="COMPUTERNAME	DRIVE	SIZEGB	FREEGB	USEDGB	PERCENTUSED	INCREMENTGB80PERCENTUSED"
if (!(test-path $logfile)) {out-file $logfile -input $line}
if ($scope -eq '') {$params = @{'computername' = $computername}
}
else {$params = @{'computername' = $computername; 'credential' = $creds}
}
try {
	$result = gwmi win32_logicaldisk -filter "drivetype=3" @params -ea stop
	$line|out-host
	foreach ($Disk in $result) {
		$Used = [int64]$Disk.size - [int64]$Disk.freespace
		$increment80percentused = ([int64]$Disk.size - 5 * [int64]$Disk.freespace) / 4
		$line = '{0}	{1}	{2:N1}	{3:N1}	{4:N1}	{5:P}	{6}' -f $computername, $Disk.deviceid, ($Disk.Size / 1GB), ($Disk.FreeSpace / 1GB), ($used / 1GB), ($Used / $Disk.Size), [math]::Round($increment80percentused / 1GB, 0)
		out-file $logfile -input $line -append
		$line|out-host
		out-textblock -ComputerName $computername -Source $scriptbasename -Message $line
	}
	#out-textblock -ComputerName $computername -Source $scriptbasename -Message 'HDD retrieved successfully' -logfile 'ps1command.log'
	$objcomputers.count|out-host
	if ($uihash.objcomputers.count -eq 0) {if([System.Windows.MessageBox]::Show("Quieres abrir el fichero $logfile ?",$uihash.tag,'YesNoCancel','Question') -eq 'Yes'){start-process $logfile}}
}
catch {out-textblock -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageType 'Error' -logfile 'ps1command.log'}