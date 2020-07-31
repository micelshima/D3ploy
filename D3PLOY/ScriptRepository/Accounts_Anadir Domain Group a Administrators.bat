@echo off
set thegroup=DOMAIN\GAdminServersComms 
REM ---------------------------------------------

net localgroup administrators %thegroup% /add
rem net localgroup administradores %thegroup% /add
