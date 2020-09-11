@echo off
set theuser=Administrator
WMIC USERACCOUNT WHERE "Name='%theuser%'" SET PasswordExpires=FALSE
REM ---------------------------------------------

set theuser=LocalAdmin1
set thepass=password1

echo create local user %theuser%
net user %theuser% %thepass% /add 

net localgroup administrators %theuser% /add
rem net localgroup administradores %theuser% /add

WMIC USERACCOUNT WHERE "Name='%theuser%'" SET PasswordExpires=FALSE

REM ---------------------------------------------

set theuser=LocalAdmin2
set thepass=password2

echo create local user %theuser%
net user %theuser% %thepass% /add 

net localgroup administrators %theuser% /add
net localgroup administradores %theuser% /add

WMIC USERACCOUNT WHERE "Name='%theuser%'" SET PasswordExpires=FALSE
REM ---------------------------------------------
:fin
del "Accounts_Crear Admin Local.bat"
exit
