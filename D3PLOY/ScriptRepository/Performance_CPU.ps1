Function PercentProcessorTime($params) {
	$result = gwmi Win32_PerfRawData_PerfOS_Processor @params -Filter "Name='_Total'" -ea stop|select PercentProcessorTime, timestamp_sys100ns
	return $result
}
$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
#PercentProcessorTime	DPCsQueuedPerSec	Frequency_PerfTime	InterruptsPerSec
if (!(test-path $logfile)) {out-file $logfile -input "COMPUTERNAME	PERCENTPROCESSORTIME"}
if ($scope -eq '') {$params = @{'computername' = $computername}
}
else {$params = @{'computername' = $computername; 'credential' = $creds}
}
try {
	$result1 = PercentProcessorTime $params
	start-sleep -s 5
	$result2 = PercentProcessorTime $params
	$ProcessorTime = 1 - (($result2.percentprocessortime - $result1.percentprocessortime) / ($result2.timestamp_sys100ns - $result1.timestamp_sys100ns))
	out-textblock -ComputerName $computername -Source $scriptbasename -Message 'CPU retrieved successfully' -logfile 'ps1command.log'
	$line = '{0}	{1:P}' -f $computername, $ProcessorTime
	out-file $logfile -input $line -append
	$line|out-host
	out-textblock -ComputerName $computername -Source $scriptbasename -Message $line
	if ($uihash.objcomputers.count -eq 0) {if([System.Windows.MessageBox]::Show("Quieres abrir el fichero $logfile ?",$uihash.tag,'YesNoCancel','Question') -eq 'Yes'){start-process $logfile}}
}
catch {out-textblock -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageType 'Error' -logfile 'ps1command.log'}