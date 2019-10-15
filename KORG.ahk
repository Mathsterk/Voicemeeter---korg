 ;Routine to send a single middle C note by using the midiOutShortMsg function.
  ;Note that the timing of the note-off command cannot be precisely controlled using this method
  ;since AHK's Sleep command doesn't always sleep for the specified duration.
  ;The midiOutShortMsg command is better used for sending single events, such as program changes or control changes
  ;To send a series of events that require precise timing, use the MidiStream functions instead.
  ;This script provides an example of the correct order and format that the functions need to be called in to send a midi event.


#Persistent
#SingleInstance force
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn ; Recommended for catching common errors.
#MaxHotkeysPerInterval 99000000
#HotkeyInterval 99000000
#KeyHistory 0
#UseHook
ListLines Off
Process, Priority, , H
SetBatchLines, -1
SetKeyDelay, -1, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetWinDelay, -1
SetControlDelay, -1
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.


OnExit("cleanup_before_exit")
SetFormat, Float, 0.3
global volLvlB0 = -36.0
global VMR_FUNCTIONS := {}
global VMR_DLL_DRIVE := "C:"
global VMR_DLL_DIRPATH := "Program Files (x86)\VB\Voicemeeter"
global VMR_DLL_FILENAME_32 := "VoicemeeterRemote.dll"
global VMR_DLL_FILENAME_64 := "VoicemeeterRemote64.dll"
global VMR_DLL_FULL_PATH := VMR_DLL_DRIVE . "\" . VMR_DLL_DIRPATH . "\"
Sleep, 500
if (A_Is64bitOS) {
VMR_DLL_FULL_PATH .= VMR_DLL_FILENAME_64
} else {
VMR_DLL_FULL_PATH .= VMR_DLL_FILENAME_32
}

; global muted = 0


global VMR_MODULE := DllCall("LoadLibrary", "Str", VMR_DLL_FULL_PATH, "Ptr")
if (ErrorLevel || VMR_MODULE == 0)
die("Attempt to load VoiceMeeter Remote DLL failed.")

; Populate VMR_FUNCTIONS
add_vmr_function("Login")
add_vmr_function("Logout")
add_vmr_function("RunVoicemeeter")
add_vmr_function("SetParameterFloat")
add_vmr_function("GetParameterFloat")
add_vmr_function("IsParametersDirty")

; "Login" to Voicemeeter, by calling the function in the DLL named 'VBVMR_Login()'...
login_result := DllCall(VMR_FUNCTIONS["Login"], "Int")
if (ErrorLevel || login_result < 0)
die("VoiceMeeter Remote login failed.")

; If the login returns 1, that apparently means that Voicemeeter isn't running,
; so we start it; pass 1 to run Voicemeeter, or 2 for Voicemeeter Banana:
if (login_result == 1) {
DllCall(VMR_FUNCTIONS["RunVoicemeeter"], "Int", 2, "Int")
if (ErrorLevel)
die("Attempt to run VoiceMeeter failed.")
Sleep 2000
}



#Include Midi Functions.ahk
 
  ;Constants:
  Channel := 1               ;midi channel to send on
  MidiDevice := 1       ;number of midi output device to use.  
  Note := 62            ;midi number for middle C
  NoteDur := 30       ;duration to hold note for (approx.)
  NoteVel := 127        ;velocity of note to send
  
  ;See if user wants to pick an output
  ; MsgBox, 4, Enumerate Midi Outputs?
  ;   , Do you want to select from a list of midi outputs on this system, and their associated IDs?`n`nIf you select NO, the default midi output will be used.                        
  ; IfMsgBox Yes
  ; {
  ;   NumPorts := MidiOutsEnumerate()     ;function that fills an global array called MidiOutPortName and returns the number of ports
  ;   Loop, % NumPorts
  ;   {
  ;     Port := A_Index -1
  ;     msg := msg . "ID: " . Port . " --> " . MidiOutPortName%Port% . "`n"
  ;   }
  ;   InputBoxH := 100 + NumPorts * 35
  ;   InputBox, MidiDevice, Select Midi Port, Enter the number of the port you would like to use`n`n%msg%,, 350, % (NumPorts * 35 + 100),,,,, 0
  ;   if (errorlevel)
  ;       exit
  ; }
   
  ;Open the Windows midi API dll
  hModule := OpenMidiAPI()
;pause
  ;Open the midi port
  h_midiout := midiOutOpen(MidiDevice)
;pause
;-------------Send middle C-----------------------------------------------------
; "N1" is shorthand for "NoteOn". See comments in midiOutShortMsg for a full list of allowable event types 

; Loop, 53 {
;   midiOutShortMsg(h_midiout, "CC", Channel, A_Index + 10, 127)


; ;pause
;   Sleep %NoteDur%
 
;  ;Send Note-Off command for middle C 
;   ; midiOutShortMsg(h_midiout, "CC", Channel, A_Index + 10, 0)
; }  

;   midiOutShortMsg(h_midiout, "CC", Channel, 80, 127)
;   Sleep %NoteDur%
;   midiOutShortMsg(h_midiout, "CC", Channel, 81, 127)


; Loop, 53 {
;   ; midiOutShortMsg(h_midiout, "CC", Channel, A_Index + 10, 127)


; ;pause
;   Sleep %NoteDur%
 
;  ;Send Note-Off command for middle C 
;   midiOutShortMsg(h_midiout, "CC", Channel, A_Index + 10, 0)
; }  
;   Sleep %NoteDur%
;   midiOutShortMsg(h_midiout, "CC", Channel, 80, 0)
;   Sleep %NoteDur%
;   midiOutShortMsg(h_midiout, "CC", Channel, 81, 0)

keepalive := 0

Loop {
  isDirty := DLLCall(VMR_FUNCTIONS["IsParametersDirty"], "Int")
  if(isDirty > 0) {

    muted := 0

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[0].Mute", "Float*", muted)
    if(muted > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 21, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 21, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[1].Mute", "Float*", muted)
    if(muted > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 22, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 22, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[4].Mute", "Float*", muted)
    if(muted > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 23, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 23, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[5].Mute", "Float*", muted)
    if(muted > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 24, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 24, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[6].Mute", "Float*", muted)
    if(muted > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 25, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 25, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[7].Mute", "Float*", muted)
    if(muted > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 26, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 26, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Bus[0].Mute", "Float*", muted)
    if(muted > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 27, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 27, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Bus[1].Mute", "Float*", muted)
    if(muted > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 28, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 28, 0)
    }








    solo0 := 0
    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[0].Solo", "Float*", solo0)
    if(solo0 > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 29, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 29, 0)
    }

    solo1 := 0
    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[1].Solo", "Float*", solo1)
    if(solo1 > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 30, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 30, 0)
    }

    solo1 := 0
    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[4].Solo", "Float*", solo1)
    if(solo1 > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 31, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 31, 0)
    }

    solo1 := 0
    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[5].Solo", "Float*", solo1)
    if(solo1 > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 33, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 33, 0)
    }

    solo1 := 0
    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[6].Solo", "Float*", solo1)
    if(solo1 > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 34, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 34, 0)
    }

    solo1 := 0
    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[7].Solo", "Float*", solo1)
    if(solo1 > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 35, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 35, 0)
    }

    eq := 0
    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Bus[0].EQ.on", "Float*", eq)
    if(eq > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 36, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 36, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Bus[1].EQ.on", "Float*", eq)
    if(eq > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 37, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 37, 0)
    }



    B1 := 0
    
    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[0].Mute", "Float*", muted)
    if(muted > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 21, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 21, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[1].Mute", "Float*", muted)
    if(muted > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 22, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 22, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[4].Mute", "Float*", muted)
    if(muted > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 23, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 23, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[5].Mute", "Float*", muted)
    if(muted > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 24, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 24, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[6].Mute", "Float*", muted)
    if(muted > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 25, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 25, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[7].Mute", "Float*", muted)
    if(muted > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 26, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 26, 0)
    }





  } else {
    Sleep, 10
    keepalive := keepalive + 1
    if(keepalive > 100) {
      midiOutShortMsg(h_midiout, "CC", Channel, 0, 0)
      keepalive := 0
    }
  }

}





readVolLvl(){
statusLvlB0 = DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Bus[0].Gain", "Ptr", &volLvlB0, "Int")
if (statusLvlB0 < 0){
MsgBox, Error: %statusLvlB0%
} else {
SetFormat, Float, 0.3
MsgBox, %volLvlB0%
}
}

add_vmr_function(func_name) {
VMR_FUNCTIONS[func_name] := DllCall("GetProcAddress", "Ptr", VMR_MODULE, "AStr", "VBVMR_" . func_name, "Ptr")
if (ErrorLevel || VMR_FUNCTIONS[func_name] == 0)
die("Failed to register VMR function " . func_name . ".")
}

cleanup_before_exit(exit_reason, exit_code) {
DllCall(VMR_FUNCTIONS["Logout"], "Int")
; OnExit functions must return 0 to allow the app to exit.
return 0
}

die(die_string:="UNSPECIFIED FATAL ERROR.", exit_status:=254) {
MsgBox 16, FATAL ERROR, %die_string%
ExitApp exit_status
}

; FHex( int, pad=8 ) { ; Function by [VxE]. Formats an integer (decimals are truncated) as hex. NOT IN USE FOR NOW
; ; "Pad" may be the minimum number of digits that should appear on the right of the "0x".
; Static hx := "0123456789ABCDEF"
; If !( 0 < int |= 0 )
; Return !int ? "0x0" : "-" FHex( -int, pad )
; s := 1 + Floor( Ln( int ) / Ln( 16 ) )
; h := SubStr( "0x0000000000000000", 1, pad := pad < s ? s + 2 : pad < 16 ? pad + 2 : 18 )
; u := A_IsUnicode = 1
; Loop % s
; NumPut( *( &hx + ( ( int & 15 ) << u ) ), h, pad - A_Index << u, "UChar" ), int >>= 4
; Return h
; }


