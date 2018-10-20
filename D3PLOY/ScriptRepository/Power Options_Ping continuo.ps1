
$strscript = @"
	do
	{
	if ((Test-Connection -ComputerName $computername -Count 1 -BufferSize 16 -erroraction "SilentlyContinue" -quiet))
	{write-host $('Ping {0} Success' -f  $computername) -fore white}
	else{write-host $(' Ping {0} TimedOut' -f  $computername) -fore darkgray}
	start-sleep -s 2
	}
	while (1 -eq 1)
"@

start-process -filepath powershell.exe -ArgumentList "-command ""& {$strscript}"""

#start-process -filepath powershell.exe -ArgumentList "-command ""& {test-connection $computername -count 1000}"""