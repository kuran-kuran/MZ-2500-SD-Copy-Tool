:loop
call clear.bat
z80as BENCH2000.ASM
z80as -x -mBENCH2000 BENCH2000.ASM
pause
goto :loop
