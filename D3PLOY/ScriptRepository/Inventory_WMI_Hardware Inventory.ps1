$scriptbasename = $MyInvocation.Mycommand.name.substring(0, $MyInvocation.Mycommand.name.lastindexof('.'))
$HKLM = 2147483650
$logfile = "results\$($scriptbasename).csv"
if (!(test-path $logfile)) {out-file $logfile -input "COMPUTERNAME	HOSTNAME	TYPE	DOMAIN	USERNAME	MANUFACTURER	MODEL	SERIALNUMBER	PARTNUMBER	NPROCESSORS	NCORES	RAM	HDD	OSFAMILY	SP	LASTBOOTUP"}
if ($scope -eq '') {$params = @{'computername' = $computername}
}
else {$params = @{'computername' = $computername; 'credential' = $creds}
}
#WMI computer info
try {
	$reg = gwmi -List -Namespace root\default @params|? {$_.Name -eq "StdRegProv"}
	#COMPUTERSYSTEM
	$result = gwmi Win32_ComputerSystem @params -ea stop
	$hostname = $result.name
	$marca = $result.manufacturer
	$modelo = $result.model
	$nproc = $result.NumberOfProcessors
	$dominio = $result.domain
	$ram = [math]::round($result.TotalPhysicalMemory / 1GB, 1)
	if ($marca -eq "VMware, Inc." -or $marca -eq "Microsoft Corporation") {
		$tipo = "Virtual ($marca)"
		$modelo = $numerodeserie = $partnumber = $null
	}
	else {
		$tipo = "Physical"
		#BIOS
		$result = gwmi Win32_Bios @params
		$numerodeserie = $result.serialnumber
		#PARTNUMBER
		$partnumber = $reg.GetStringValue($HKLM, "HARDWARE\DESCRIPTION\System\BIOS", "SystemSKU").sValue
	}

	#PROCESSOR
	$result = gwmi Win32_processor @params
	$ncores = 0
	Foreach ($processorinfo in $result) {$ncores += $processorinfo.numberofcores}
	#LOGICALDISK
	$result = gwmi win32_logicaldisk @params
	$almacenamiento = 0
	Foreach ($disk in $result) {$almacenamiento += ($Disk.Size / 1GB)}
	$almacenamiento = [math]::round($almacenamiento, 1)
	#OPERATINGSYSTEM
	$result = gwmi Win32_OperatingSystem @params
	$LastBootUpTime = $result.converttodatetime($result.lastbootuptime)
	$LastBootUpTime = "{0:yyyy/MM/dd HH:mm:ss}" -f [datetime]$LastBootUpTime
	$sp = $result.csdversion -replace ("service pack ", "SP")
	$osfamily = $result.caption -replace ("®") -replace ("\(R\)") -replace (',')
	#USERNAME
	$username = $reg.GetStringValue($HKLM, "Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI", "LastLoggedOnUser").sValue
	out-file $logfile -input "$computername	$hostname	$tipo	$dominio	$username	$marca	$modelo	$numerodeserie	$partnumber	$nproc	$ncores	$ram	$almacenamiento	$osfamily	$sp	$LastBootUpTime" -append
	if ($uihash.objcomputers.count -eq 0) {if([System.Windows.MessageBox]::Show("Quieres abrir el fichero $logfile ?",$uihash.tag,'YesNoCancel','Question') -eq 'Yes'){start-process $logfile}}
}
catch {out-textblock -ComputerName $computername -Source $scriptbasename -Message $_.Exception.Message -MessageType 'Error' -logfile 'ps1command.log'}




