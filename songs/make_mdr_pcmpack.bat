@echo off

rem
rem make_mdr.bat
rem

rem echo MODE IS %MODE%

SETLOCAL

rem ���[�g�ݒ�
SET MOONDIR=..\

rem �e�f�B���N�g���ݒ�
SET BINDIR=%MOONDIR%\bin
SET SONGDIR=%MOONDIR%\songs

rem MMLNAME = �f�B���N�g�����ƃt�@�C�����i�g���q�܂܂�)
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
echo ����I��
if "%MODE%" == "DEBUG" goto batch_end
del %MMLNAME%.h
del define.inc
del effect.h
del %SONGDIR%\mdrvhdr.pce
del %SONGDIR%\mdrvhdr.sym

:batch_end
exit /b

:failed
echo �R���p�C�����s
exit /b
