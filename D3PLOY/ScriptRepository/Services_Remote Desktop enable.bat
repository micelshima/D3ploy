REM Arrancando servicio 'Registro Remoto'
sc config RemoteRegistry start= AUTO
net start remoteregistry

REM Habilitando 'Terminal Server'
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
net stop TermService
net start TermService

