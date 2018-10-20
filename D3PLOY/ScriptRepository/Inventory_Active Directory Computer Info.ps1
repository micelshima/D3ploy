$scriptbasename=$MyInvocation.Mycommand.name.substring(0,$MyInvocation.Mycommand.name.lastindexof('.'))
$logfile= "results\$($scriptbasename).csv"
if (!(test-path $logfile)){out-file $logfile -input "NAME	DOMAIN	OS	SP	WHENCREATED	WHENCHANGED	LASTLOGONTIMESTAMP	PATH	DN"}
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = New-Object ADSI("GC://SERVERDC01/dc=domain,dc=local")
$objSearcher.Filter ="(&(objectcategory=Computer)(name=$computername))"
$Result1=$objSearcher.findone()
if ($Result1 -ne $NULL) {
	$domain = $lastlogontimestamp = $whenCreated = $whenChanged = $null
	$objcomputer = $Result1.path -replace ("GC://", "LDAP://")
	$domain = $Result1.path.substring($Result1.path.indexof("DC="))
	$Result2 = New-Object System.DirectoryServices.DirectoryEntry $objcomputer
	$lastlogontimestamp = '{0:dd/MM/yyyy HH:mm:ss}' -f [DateTime]::FromFileTime([Int64]::Parse($Result1.properties.lastlogontimestamp))
	$whenCreated = '{0:dd/MM/yyyy HH:mm:ss}' -f [datetime][string]$Result1.properties.whencreated
	$whenChanged = '{0:dd/MM/yyyy HH:mm:ss}' -f [datetime][string]$Result1.properties.whenchanged
	$path = $Result1.properties.distinguishedname -replace ("CN=$($Result1.properties.name),")
	out-textblock -message "$computername $domain" -messagetype 'OK'
	out-file $logfile -input "$computername	$domain	$($Result2.properties.operatingsystem)	$($Result2.properties.operatingsystemservicepack)	$whenCreated	$whenChanged	$lastlogontimestamp	$path	$($Result1.properties.distinguishedname)" -append
}
else {
out-textblock -message "$computername no encontrado" -messagetype 'Error'
	out-file $logfile -input $computername -append
}
if ($uihash.objcomputers.count -eq 0) {if([System.Windows.MessageBox]::Show("Quieres abrir el fichero $logfile ?",$uihash.tag,'YesNoCancel','Question') -eq 'Yes'){start-process $logfile}}
