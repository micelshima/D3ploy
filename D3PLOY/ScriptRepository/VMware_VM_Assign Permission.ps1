$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
try {
	Add-PSSnapin VMware.VimAutomation.Core -ea SilentlyContinue # add VMware PS snapin
	if (!$?) {import-module "VMware.VimAutomation.Core" -ea stop} #cargo el modulo de powercli 6.5
}
catch {out-textblock -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageType 'Error'}
$VCenter = "SERVERVCENTER.domain.local"
Set-PowerCLIConfiguration -DefaultVIServerMode Single -Scope 'Session' -InvalidCertificateAction 'Ignore' -Confirm:$false
if ($scope -eq '') {$params = @{'server' = $VCenter}
}
else {$params = @{'server' = $VCenter; 'credential' = $creds}
}
$VCServer = Connect-VIserver @params
if (![bool]$groupname) {$groupname = show-inputbox -message "Usuario/Grupo? (ejemplo DOMAIN\GS_systems_admins)"}
if (![bool]$VIrole) {$VIrole = Get-VIRole|out-gridview -passthru -title "Elige el rol a asignar a $groupname"}
if ([bool]$VIrole -and [bool]$groupname) {
	if ($vm = get-vm -name $computername) {
		$vm|New-VIPermission -Role $VIrole -Principal $groupname
	}
	else {out-textblock -ComputerName $computername -Source $scriptbasename -Message "No encontrado" -MessageType 'Error'}
}
Disconnect-VIServer $VCenter -Confirm:$False