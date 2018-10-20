$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
if (!(test-path $logfile)) {out-file $logfile -input "Computername	IPAddress	SubnetMask	DefaultGateway	MACAddress	IsDHCPEnabled	DNSServers"}
if ($scope -eq '') {$params = @{'computername' = $computername}
}
else {$params = @{'computername' = $computername; 'credential' = $creds}
}
try {
	$result = gwmi Win32_NetworkAdapterConfiguration @params -ea stop|? {$_.IPEnabled}
	foreach ($Network in $result) {
		$IPAddress = $Network.IpAddress[0]
		$SubnetMask = $Network.IPSubnet[0]
		$DefaultGateway = $Network.DefaultIPGateway
		$DNSServers = $Network.DNSServerSearchOrder
		$IsDHCPEnabled = $false
		If ($network.DHCPEnabled) {$IsDHCPEnabled = $true}
		$MACAddress = $Network.MACAddress
		out-file $logfile -input "$Computername	$IPAddress	$SubnetMask	$DefaultGateway	$MACAddress	$IsDHCPEnabled	$DNSServers" -append
	}#fin foreach networkadapter
	if ($uihash.objcomputers.count -eq 0) {if([System.Windows.MessageBox]::Show("Quieres abrir el fichero $logfile ?",$uihash.tag,'YesNoCancel','Question') -eq 'Yes'){start-process $logfile}}
}
catch {out-textblock -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageType 'Error' -logfile 'ps1command.log'}
