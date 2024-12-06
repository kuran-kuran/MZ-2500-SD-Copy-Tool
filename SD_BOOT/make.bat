:loop
call clear.bat
z80as SD_BOOT.ASM
z80as -x -mSD_BOOT SD_BOOT.ASM
ren SD_BOOT.bin MZ-1R12.BIN
rem z80as test.asm
pause
goto :loop
