@echo off
set theuser=LocalUser

echo delete local user %theuser%
net user %theuser% /delete
