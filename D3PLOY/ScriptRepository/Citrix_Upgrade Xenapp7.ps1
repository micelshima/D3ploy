$source = '\\svpnassclfs01.acciona.int\doc_citrix$\Software\Xen7.15_ltsr CU1'
$destination = 'c:\setup'
$files = 'VDAServerSetup_7_15_1000.exe'
$commands = @()
$robocommand = 'robocopy "{0}" "\\{1}\{2}" "{3}" /w:1 /r:1 /xo /e /tee /np' -f $source, $computername, ($destination -replace (':', '$')), $files
if ($scope -eq '') {
	$params = @{'computername' = $computername}
	$commands += $robocommand
}
else {
	$credsplain = select-MiCredential -scope $scope -plain
	$commands += "cmdkey.exe /add:" + $computername + " /user:" + $credsplain.username + " /pass:'" + $credsplain.password + "'"
	$commands += $robocommand
	$commands += "cmdkey.exe /delete:" + $computername
	$params = @{'computername' = $computername; 'credential' = $creds}
}
foreach ($command in $commands) {
	invoke-expression $command
	if ($command -eq $robocommand) {
		if ($lastexitcode -gt 8) {$color = 'Error'; $premsg = "Error copying $source to $destination"; $success = $false}
		else {$color = 'OK'; $premsg = "Upgrading to $files"; $success = $true}
		out-textblock -ComputerName $computername -Source $scriptbasename -Message $premsg  -MessageType $color -logfile 'ps1command.log'
		if ($success) {
			#$session = New-PSSession @params
			#Copy-Item –Path "\\Svpnapsdsc01.acciona.int\repository$\Packages\CitrixXenapp\VDAServerSetup_7_15_1000.exe" –Destination 'C:\setup' –ToSession $session
			invoke-command @params -arg $destination, $files -scriptblock {
				param($destination, $files)
				#fix Regedit ACL
				$acl = get-acl HKLM:\SOFTWARE\Wow6432Node\citrix\Euem\LoggedEvents
				$inherit = [system.security.accesscontrol.InheritanceFlags]"ContainerInherit, ObjectInherit"
				$propagation = [system.security.accesscontrol.PropagationFlags]"None"
				"Administrators", "SYSTEM"| % {
					$rule = New-Object System.Security.AccessControl.RegistryAccessRule ($_, "FullControl", $inherit, $propagation, "Allow")
					$acl.SetAccessRule($rule)
					$acl |Set-Acl
				}
				#install new version
				$command = 'cmd /c {0}\{1} /passive' -f $destination, $files
				invoke-expression $command
				remove-item "$destination\$files"
			}
			#$session | Remove-PSSession
			restart-computer @params -confirm:$true
		}
	}
}

