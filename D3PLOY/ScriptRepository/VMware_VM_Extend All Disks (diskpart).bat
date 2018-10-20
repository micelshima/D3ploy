for %%N in (0 1 2 3) do (
echo rescan > c:\windows\temp\diskpart.txt
echo select volume %%N >> c:\windows\temp\diskpart.txt
echo extend >> c:\windows\temp\diskpart.txt
echo exit >> c:\windows\temp\diskpart.txt
diskpart /s c:\windows\temp\diskpart.txt
)

