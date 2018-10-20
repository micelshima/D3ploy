$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
if (!(test-path $logfile)){out-file $logfile -input "COMPUTERNAME	GROUPNAME	MEMBER	CLASS"}
if(![bool]$localgroupname){
out-textblock -ComputerName $computername -Source $scriptbasename -Message 'Rellena los campos solicitados de la consola de comandos' -MessageType 'Warning' -logfile 'ps1command.log'
$localgroupname=show-inputbox -message "Grupo a consultar?"
}
$objects=invoke-command -computername $computername -credential $creds -arg $localgroupname -scriptblock {
param($localgroupname)

$computer = [ADSI]("WinNT://localhost,computer")
$Group = $computer.psbase.children.find($localgroupname)
$objects=@()
$members = $Group.psbase.invoke("Members")
	foreach($member in $members){
	$object=""|select localgroupname,member,class
	$object.localgroupname=$localgroupname
	$object.Class = $Member.GetType().InvokeMember("Class", 'GetProperty', $Null, $Member, $Null)
	$object.member=	$member.GetType().InvokeMember("Name", 'GetProperty', $null, $member, $null)
	$objects+=$object
	}
return $objects
}
foreach($object in $objects)
{

out-file $logfile -input "$computername	$($object.localgroupname)	$($object.member)	$($object.class)" -append
}