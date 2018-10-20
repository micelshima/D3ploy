if ($scope -ne '') {
	$cmdkeyadd = "cmdkey.exe /add:" + $computername + " /user:" + $credsplain.username + " /pass:'" + $credsplain.password + "'"
	invoke-expression $cmdkeyadd
}

$strcommand="$psscriptroot\..\..\_bin\Delprof2.exe /c:$computername /u /ed:Administrator /ed:Public /ed:adm* /ed:Citrix* /ed:ctx* /ed:Default /d:180"
invoke-expression $strcommand|out-textblock

if ($scope -ne '') {
	$cmdkeydelete = "cmdkey.exe /delete:" + $computername
	invoke-expression $cmdkeydelete
}
