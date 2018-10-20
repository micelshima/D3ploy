$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
import-module "..\_Modules\ScheduledTask"
if ($scope -ne '') {
	$cmdkeyadd = "cmdkey.exe /add:" + $computername + " /user:" + $credsplain.username + " /pass:'" + $credsplain.password + "'"
	invoke-expression $cmdkeyadd
}
$tasks2delete = Get-ScheduledTask -RootFolder -ComputerName $computername|select name, enabled, numberofmissedruns, lastruntime, lasttaskresult, path|out-gridview -passthru -title "Tareas a Borrar de $computername"
foreach ($task2delete in $tasks2delete) {
	out-textblock -ComputerName $computername -Source $scriptbasename -Message "Borrando $($task2delete.name) en $computername" -logfile 'ps1command.log'
	remove-scheduledtask -computername $computername -path $task2delete.path|out-textblock
}
if ($scope -ne '') {
	$cmdkeydelete = "cmdkey.exe /delete:" + $computername
	invoke-expression $cmdkeydelete
}