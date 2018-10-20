$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
if (!(test-path $logfile)) {out-file $logfile -input "Computername	DisplayName	Name	Installed	InstallState"}
$feature = "FS-SMB1"
if ($scope -eq '') {$params = @{'computername' = $computername}
}
else {$params = @{'computername' = $computername; 'credential' = $creds}
}
try{
	$result=get-WindowsFeature @params -name $feature -ea stop
	if([bool]$result.installed){$type='OK'}
	else{$type='Error'}
	Out-TextBlock -ComputerName $computername -Source $scriptbasename -Message "$feature $($result.installed)" -Messagetype $type
	'{0}	{1}	{2}	{3}	{4}' -f $computername, $result.displayname,$result.name, $result.installed,$result.installstate|out-file $logfile -append
}
catch{Out-TextBlock -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -Messagetype 'Error'}

if ($uihash.objcomputers.count -eq 0) {
if([System.Windows.MessageBox]::Show("Quieres abrir el fichero $logfile ?",$uihash.tag,'YesNoCancel','Question') -eq 'Yes'){
start-process $logfile}
}
