$scriptbasename=$MyInvocation.Mycommand.name.substring(0,$MyInvocation.Mycommand.name.lastindexof('.'))
if ($scope -ne '') {
	$cmdkeyadd = 'cmdkey.exe /add:{0} /user:{1} /pass:"{2}"' -f $computername,$credsplain.username,$credsplain.password
	invoke-expression $cmdkeyadd
}
if (![bool]$account) {
$account = show-inputbox -message "Username?"
$PlainPassword = show-inputbox -message "Password?"
}
$ADS_UF_DONT_EXPIRE_PASSWD = 0x10000
try {
	$adsi = [ADSI]"WinNT://$ComputerName"
	if([adsi]::Exists("WinNT://$ComputerName/$account")){
		out-textblock -ComputerName $computername -Source $scriptbasename -Message "User $account already exists." -MessageType 'OK' -logfile 'ps1command.log'
	}
	else{
		$NewObj = $adsi.Create("User",$account)
		$NewObj.SetPassword($PlainPassword)
		$NewObj.userflags = $NewObj.userflags[0] -bor $ADS_UF_DONT_EXPIRE_PASSWD
		$NewObj.SetInfo()		
		#Lo añado a Administradores
		$group="Administrators"
		$adsi = [ADSI]"WinNT://$ComputerName/$group,Group"
		$adsi.add("WinNT://$account,User")
		out-textblock -ComputerName $computername -Source $scriptbasename -Message "$account created successfully and added to $group" -MessageType 'OK' -logfile 'ps1command.log'	
		}	
	}
catch {
	out-textblock -ComputerName $computername -Source $scriptbasename -Message $_.exception.message -MessageType 'Error' -logfile 'ps1command.log'
}

if ($scope -ne '') {
	$cmdkeydelete = 'cmdkey.exe /delete:{0}' -f $computername
	invoke-expression $cmdkeydelete
}