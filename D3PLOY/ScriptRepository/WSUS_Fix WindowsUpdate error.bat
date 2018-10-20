@echo off
net stop wuauserv
net stop bits
del c:\windows\windowsupdate.log /q
rd %systemroot%\SoftwareDistribution\Datastore /q /s
rd %systemroot%\SoftwareDistribution\Download /q /s
REG DELETE "HKLM\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v LastWaitTimeout /f
REG DELETE "HKLM\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v DetectionStartTime /f
Reg Delete "HKLM\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v NextDetectionTime /f
net start bits
net start wuauserv
wuauclt.exe /resetauthorization /detectnow