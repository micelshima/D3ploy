@echo off
set ruta=%~dp0
set unidad=%ruta:~0,2%
%unidad%
cd %ruta%
:inicio
powershell -executionpolicy unrestricted -noprofile -file .\Deploy.ps1
pause
goto inicio
