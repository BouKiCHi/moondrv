@ECHO OFF

SETLOCAL

REM ルート設定
SET MOONDIR=%~dp0\..\

SET BINDIR=%MOONDIR%\bin

REM BASENAME = ディレクトリ名とファイル名（拡張子含まず)
set BASENAME=%~p1%~n1

%BINDIR%\pcmtool %1
