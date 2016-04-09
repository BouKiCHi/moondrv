@echo off

rem
rem make_mdr.bat
rem

rem echo MODE IS %MODE%

SETLOCAL

rem ルート設定
SET MOONDIR=..\

rem 各ディレクトリ設定
SET BINDIR=%MOONDIR%\bin
SET SONGDIR=%MOONDIR%\songs

rem MMLNAME = ディレクトリ名とファイル名（拡張子含まず)
set MMLNAME=%~p1%~n1

%BINDIR%\mmckc -i %MMLNAME%.MML

if not exist %MMLNAME%.h goto failed

rem
rem assemble
rem

%BINDIR%\pceas -raw %SONGDIR%\mdrvhdr.asm

copy %SONGDIR%\mdrvhdr.pce %MMLNAME%.MDR

%BINDIR%\pcmpack %MMLNAME%.MDR

:success_end
echo 正常終了
if "%MODE%" == "DEBUG" goto batch_end
del %MMLNAME%.h
del define.inc
del effect.h
del %SONGDIR%\mdrvhdr.pce
del %SONGDIR%\mdrvhdr.sym

:batch_end
exit /b

:failed
echo コンパイル失敗
exit /b
