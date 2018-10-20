import-module "..\_Modules\HPiLOCmdlets"
$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
if (!(test-path $logfile)) {out-file $logfile -input "COMPUTERNAME	FIRMWARE_NAME	FIRMWARE_VERSION	INDEX"}
if ($scope -eq '') {$params = @{'server' = $computername}
}
else {$params = @{'server' = $computername; 'credential' = $creds}
}
$result = Get-HPiLOServerInfo @params -DisableCertificate -category "FirmwareInfo"
$result.firmwareinfo| % {
	$msg = "{0}	{1}	{2}	{3}" -f $computername, $_.firmware_name, $_.firmware_version, $_.index
	out-file $logfile -input $msg -append	
}
if ($uihash.objcomputers.count -eq 0) {if([System.Windows.MessageBox]::Show("Quieres abrir el fichero $logfile ?",$uihash.tag,'YesNoCancel','Question') -eq 'Yes'){start-process $logfile}}
