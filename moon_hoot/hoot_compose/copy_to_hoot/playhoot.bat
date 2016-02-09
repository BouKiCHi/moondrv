%~d0
cd %~p0

if exist msx goto del_pack

mkdir msx
goto pack

:del_pack
if not exist msx\moondrv.zip goto pack
del msx\moondrv.zip

:pack
copy %1 SONG.MDR

7za a msx\moondrv.zip ..\moon_hoot\LOADER ..\moon_hoot.bin SONG.MDR

hootwait --reload
hootwait --play 0 hoot.exe
