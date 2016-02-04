rem
rem make_mdr.bat
rem

@echo off


..\bin\mmckc -i %~n1.MML

if not exist %~n1.h goto fail_compile

rem
rem assemble
rem

..\bin\pceas -raw mdrvhdr.asm

copy mdrvhdr.pce %~n1.MDR

:success_end
echo 正常終了
del %~n1.h
del define.inc
del effect.h
del mdrvhdr.pce
del mdrvhdr.sym
exit /b


:fail_compile
echo コンパイル失敗
exit /b

end

