global playpercent
global playing

loop {
	gdm()
	sleep 100
}

gdm() {
	FileRead, json, %A_AppData%\Google Play Music Desktop Player\json_store\playback.json

	RegExMatch(json, "O).playing.: (true|false)", gdmplaying)

	if(gdmplaying.1 = "true") {
		playing := 1
	} else if(gdmplaying.1 = "false") {
		playing := 0
	}

	RegExMatch(json, "O).current.: (\d*)", current)
	RegExMatch(json, "O).total.: (\d*)", total)

	playpercent := (current.1 / total.1)*8
}

; ListVars
; WinWaitActive ahk_class AutoHotkey
; ControlSetText Edit1, [PARSED]`r`n%parsed_out%`r`n`r`n[STRINGIFIED]`r`n%stringified%
; WinWaitClose

Pause

exit