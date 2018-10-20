$feature = "FS-SMB1"
if ($scope -eq '') {$params = @{'computername' = $computername}
}
else {$params = @{'computername' = $computername; 'credential' = $creds}
}
try{
	Add-WindowsFeature @params -name $feature -restart:$false -confirm:$false -ea stop
	Out-TextBlock -ComputerName $computername -Source $scriptbasename -Message "Installed Windows Feature $feature on $computername" -Messagetype 'OK' -logfile 'ps1command.log'
}
catch{Out-TextBlock -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -Messagetype 'Error' -logfile 'ps1command.log'}
