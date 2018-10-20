if ($scope -ne '') {
	$cmdkeyadd = "cmdkey.exe /add:" + $computername + " /user:" + $credsplain.username + " /pass:'" + $credsplain.password + "'"
	invoke-expression $cmdkeyadd
}
if (![bool]$account) {$account = show-inputbox -message "Grupo? (ejemplo DOMAIN\GS_Server_Admins)"
$account=$account -replace ("\\","/")
}
$adsi = [ADSI]"WinNT://$ComputerName/administrators,group"
$adsi.add("WinNT://$account,group")

if ($scope -ne '') {
	$cmdkeydelete = "cmdkey.exe /delete:" + $computername
	invoke-expression $cmdkeydelete
}
