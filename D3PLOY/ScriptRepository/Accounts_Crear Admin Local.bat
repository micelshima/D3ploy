@echo off
set theuser=Administrator
WMIC USERACCOUNT WHERE "Name='%theuser%'" SET PasswordExpires=FALSE
REM ---------------------------------------------

set theuser=EricssonAdmin
set thepass=4N9XK9AO

echo create local user %theuser%
net user %theuser% %thepass% /add 

net localgroup administrators %theuser% /add
rem net localgroup administradores %theuser% /add

WMIC USERACCOUNT WHERE "Name='%theuser%'" SET PasswordExpires=FALSE

REM ---------------------------------------------

set theuser=VmwareNavigator
set thepass=A12345678b

echo create local user %theuser%
net user %theuser% %thepass% /add 

net localgroup administrators %theuser% /add
net localgroup administradores %theuser% /add

WMIC USERACCOUNT WHERE "Name='%theuser%'" SET PasswordExpires=FALSE
REM ---------------------------------------------
:fin
del "Accounts_Crear Admin Local.bat"
exit