if ($scope -ne '') {
	$cmdkeyadd = "cmdkey.exe /add:" + $computername + " /user:" + $credsplain.username + " /pass:'" + $credsplain.password + "'"
	invoke-expression $cmdkeyadd
}
$strcommand="$psscriptroot\..\..\_bin\Delprof2.exe /c:$computername /u /ed:Administrator /ed:Public /ed:adm* /ed:Citrix* /ed:ctx* /ed:Default"
invoke-expression $strcommand

if ($scope -ne '') {
	$cmdkeydelete = "cmdkey.exe /delete:" + $computername
	invoke-expression $cmdkeydelete
}
