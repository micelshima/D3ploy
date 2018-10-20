@echo off
set thegroup=DOMAIN\GG_AE_AdminServersComms 
REM ---------------------------------------------

net localgroup administrators %thegroup% /add
rem net localgroup administradores %thegroup% /add
