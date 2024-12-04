#NoEnv
#SingleInstance, Force
SetBatchLines, -1
#NoTrayIcon
SetWorkingDir C:\Users\example\AppData\Local\SourceTree\app-3.4.19

global Ejecutable := "SourceTree.exe"

IfWinExist, ahk_exe %Ejecutable%
{
	WinActivate, ahk_exe %Ejecutable%
}
else
{
	Run, C:\Users\example\AppData\Local\SourceTree\app-3.4.19\SourceTree.exe
}







; **********
#NoEnv
#SingleInstance, Force
SetBatchLines, -1
#NoTrayIcon
SetWorkingDir C:\Users\example\Desktop
Run,  mspaint.exe


; *****************
#NoEnv
#SingleInstance, Force
SetBatchLines, -1
#NoTrayIcon
SetKeyDelay, 50, 20
text =
(
This is a text that will be sent
)
SendRaw, % text


; *******************
#NoEnv
#SingleInstance, Force
SetBatchLines, -1
#NoTrayIcon
Sleep, 25000 ; Initial delay before firing the button combination
Send, {Alt Down}{Control Down}{Shift Down}{LWin Down}
Sleep, 30
Send, {f}
Sleep, 30
Send, {Alt Up}{Control Up}{Shift Up}{LWin Up}
Sleep, 30


; **********************
#NoEnv
#NoTrayIcon
#SingleInstance, Force
SetBatchLines, -1
#Include, <nm_msg>
DetectHiddenWindows, On
IfWinNotExist, ahk_exe obs64.exe
{
	nmMsg("OBS Not Detected!",2)
	ExitApp
}
new LlamadaWS("ws://127.0.0.1:4455/scene/recording_scene")
return

; ************************
; WEB SOCKET STUFF
; ************************
class WebSocket
{
	__New(WS_URL)
	{
		static wb

		; Create an IE instance
		Gui, +hWndhOld
		Gui, New, +hWndhWnd
		this.hWnd := hWnd
		Gui, Add, ActiveX, vWB, Shell.Explorer
		Gui, %hOld%: Default

		; Write an appropriate document
		WB.Navigate("about:<!DOCTYPE html><meta http-equiv='X-UA-Compatible'"
		. "content='IE=edge'><body></body>")
...
...
...