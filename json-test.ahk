#Include %A_ScriptDir%\AutoHotkey-JSON\JXON.ahk
FileRead, playback, %A_AppData%\Google Play Music Desktop Player\json_store\playback.json

obj := Jxon_Load( playback )

potato := obj["playing"]
ListVars
; WinWaitActive ahk_class AutoHotkey
; ControlSetText Edit1, [PARSED]`r`n%parsed_out%`r`n`r`n[STRINGIFIED]`r`n%stringified%
WinWaitClose




Pause




exit