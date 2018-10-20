$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
try {
	Add-PSSnapin VMware.VimAutomation.Core -ea SilentlyContinue # add VMware PS snapin
	if (!$?) {import-module "VMware.VimAutomation.Core" -ea stop} #cargo el modulo de powercli 6.5
}
catch {out-textblock -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageType 'Error' -logfile 'ps1command.log'}
$VCenter = "SERVERVCENTER.domain.local"
Set-PowerCLIConfiguration -DefaultVIServerMode Single -Scope 'Session' -InvalidCertificateAction 'Ignore' -Confirm:$false
$VCServer = Connect-VIserver -server $VCenter

if ($vm = get-vm -name $computername) {
	if (![bool]$scriptchoice) {
		out-textblock -ComputerName $computername -Source $scriptbasename -Message 'Elige es Script de la ventana emergente' -MessageType 'Warning'
		$scriptchoice = get-childitem $PSscriptroot\*.bat|select name, fullname|out-gridview -title "Elige BAT" -passthru
	}
	if ([bool]$scriptchoice) {
		if ($scope -ne '') {
			$credsplain = select-MiCredential -scope $scope -plain
			$cmdkeyadd = "cmdkey.exe /add:" + $computername + " /user:" + $credsplain.username + " /pass:'" + $credsplain.password + "'"
			invoke-expression $cmdkeyadd
			#$robocommand = 'robocopy "{0}" "\\{1}\C$\WINDOWS\TEMP" "{2}" /w:1 /r:1 /xo /np /log+:".\logs\Invoke BAT Robocopy.log"' -f $scriptchoice.fullname, $computername, $scripchoice.name
			#invoke-expression $robocommand
			$scriptchoice.fullname
			copy-item $scriptchoice.fullname "\\$computername\c$\Windows" -force -confirm:$false
			$cmdkeydelete = "cmdkey.exe /delete:" + $computername
			invoke-expression $cmdkeydelete
			$vm|invoke-VMscript -scripttype BAT -guestcredential $creds -scripttext "C:\WINDOWS\$($scriptchoice.name)"
		}
		else {
			#$robocommand = 'robocopy "{0}" "\\{1}\C$\WINDOWS\TEMP" "{2}" /w:1 /r:1 /xo /np' -f $scriptchoice.fullname, $computername, $scripchoice.name
			#invoke-expression $robocommand
			copy-item $scriptchoice.fullname "\\$computername\c$\Windows" -force -confirm:$false
			$vm|invoke-VMscript -scripttype BAT -scripttext "C:\WINDOWS\$($scriptchoice.name)"
		}
	}
}
else {out-textblock -ComputerName $computername -Source $scriptbasename -Message "No encontrado" -MessageType 'Error' -logfile 'ps1command.log'}
Disconnect-VIServer $VCenter -Confirm:$False