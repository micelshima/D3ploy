$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$logfile = "results\$($scriptbasename).csv"
if (!(test-path $logfile)){out-file $logfile -input "COMPUTERNAME	GROUPNAME	MEMBER	CLASS"}
$objects=invoke-command -computername $computername -credential $creds -scriptblock {
$computer = [ADSI]("WinNT://localhost,computer")
$Groups = $Computer.psbase.Children | Where {$_.psbase.schemaClassName -eq "group"}
$objects=@()
	foreach($group in $groups){	
	$Members = @($Group.psbase.Invoke("Members"))
		ForEach ($Member In $Members)
		{
		$object=""|select localgroupname,member,class
		$object.localgroupname=$Group.Name
		$object.Class = $Member.GetType().InvokeMember("Class", 'GetProperty', $Null, $Member, $Null)
		$object.member = $Member.GetType().InvokeMember("Name", 'GetProperty', $Null, $Member, $Null)
		$objects+=$object
		}
	}
return $objects
}
$objects|out-host
foreach($object in $objects)
{
out-file $logfile -input "$computername	$($object.localgroupname)	$($object.member)	$($object.class)" -append
}