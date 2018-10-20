rem for %%N in (0 1 2 3) do (
rem echo rescan > c:\windows\temp\diskpart.txt
rem echo select volume %%N >> c:\windows\temp\diskpart.txt
rem echo extend >> c:\windows\temp\diskpart.txt
rem echo exit >> c:\windows\temp\diskpart.txt
rem diskpart /s c:\windows\temp\diskpart.txt
rem )

echo rescan > c:\windows\temp\diskpart.txt
echo select volume C >> c:\windows\temp\diskpart.txt
echo extend >> c:\windows\temp\diskpart.txt
echo exit >> c:\windows\temp\diskpart.txt
diskpart /s c:\windows\temp\diskpart.txt
del c:\windows\temp\diskpart.txt /q