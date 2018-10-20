$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
#### Origen y Destino ####
if (![bool]$source) {$source = show-inputbox -message "Carpeta Origen?"}
if (![bool]$destination) {$destination = show-inputbox -message "Carpeta Destino?"}
if (![bool]$files) {$files = show-inputbox -message "Ficheros? (ejemplo *.*)"}

##########################
if ($scope -ne '') {
	$cmdkeyadd = "cmdkey.exe /add:" + $computername + " /user:" + $credsplain.username + " /pass:'" + $credsplain.password + "'"
	invoke-expression $cmdkeyadd
}
$robocommand = 'robocopy "{0}" "\\{1}\{2}" "{3}" /w:1 /r:1 /xo /tee /np /LOG+:".\logs\{4}.log"' -f $source, $computername, ($destination -replace (':', '$')), $files,$scriptbasename
invoke-expression $robocommand|out-textblock
if ($lastexitcode -gt 8) {$premsg = 'Error'}
else {$premsg = 'OK'}
out-textblock -ComputerName $computername -Source $scriptbasename -Message "$premsg copiando $source a $destination"  -MessageType $premsg -logfile 'ps1command.log'
if ($scope -ne '') {
	$cmdkeydelete = "cmdkey.exe /delete:" + $computername
	invoke-expression $cmdkeydelete
}
