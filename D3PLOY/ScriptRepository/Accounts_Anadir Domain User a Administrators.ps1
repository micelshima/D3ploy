if ($scope -ne '') {
	$cmdkeyadd = "cmdkey.exe /add:" + $computername + " /user:" + $credsplain.username + " /pass:'" + $credsplain.password + "'"
	invoke-expression $cmdkeyadd
}
if (![bool]$account) {$account = show-inputbox -message "Usuario? (ejemplo DOMAIN\admmvalencia)"
$account=$account -replace ("\\","/")
}
$adsi = [ADSI]"WinNT://$ComputerName/administrators,group"
$adsi.add("WinNT://$account,user")

if ($scope -ne '') {
	$cmdkeydelete = "cmdkey.exe /delete:" + $computername
	invoke-expression $cmdkeydelete
}
