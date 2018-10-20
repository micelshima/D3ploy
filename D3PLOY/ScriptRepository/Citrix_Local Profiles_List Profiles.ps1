$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
if (!(test-path $logfile)) {out-file $logfile -input "COMPUTERNAME	USERPROFILE	LASTWRITETIME	NTUSER.DAT	DAYS OLD"}
if ($scope -ne '') {
	$cmdkeyadd = "cmdkey.exe /add:" + $computername + " /user:" + $credsplain.username + " /pass:'" + $credsplain.password + "'"
	invoke-expression $cmdkeyadd
}
$ahora=get-date
gci "\\$computername\c$\Users"| % {
	$days=$null
	$ntuserdat=gci "\\$computername\c$\Users\$($_.basename)\ntuser.dat" -force|select -expand lastwritetime
	$days=new-timespan -start $ntuserdat -end $ahora|select -expand totaldays
	'{0}	{1}	{2}	{3}	{4:N0}' -f $computername, $_.basename, $_.lastwritetime,$ntuserdat,$days|out-file $logfile -append
}

if ($scope -ne '') {
	$cmdkeydelete = "cmdkey.exe /delete:" + $computername
	invoke-expression $cmdkeydelete
}

if ($uihash.objcomputers.count -eq 0) {if ([System.Windows.MessageBox]::Show("Quieres abrir el fichero $logfile ?", $uihash.tag, 'YesNoCancel', 'Question') -eq 'Yes') {start-process $logfile}}