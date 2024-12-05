:loop
call clear.bat
z80as BENCH.ASM
z80as -x -mBENCH BENCH.ASM
pause
goto :loop
