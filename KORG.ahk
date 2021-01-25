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
add_vmr_function("GetMidiMessage")

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


global playpercent
global playing
global liked
global unliked

solo0state := 0
solo1state := 0
solo2state := 0
solo3state := 0
solo4state := 0
solo5state := 0
solochange := 0
playstate := 0


change := 0
p1state := 0
p2state := 0
p3state := 0
p4state := 0
p5state := 0
p6state := 0
p7state := 0
p8state := 0


#Include Midi Functions.ahk
 
  ;Constants:
  Channel := 1               ;midi channel to send on
  MidiDevice := 1       ;number of midi output device to use.  
  Note := 62            ;midi number for middle C
  NoteDur := 10       ;duration to hold note for (approx.)
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

Loop, 53 {
  midiOutShortMsg(h_midiout, "CC", Channel, A_Index + 10, 127)
}  

  midiOutShortMsg(h_midiout, "CC", Channel, 80, 127)
  midiOutShortMsg(h_midiout, "CC", Channel, 81, 127)


Loop, 53 {
  ; midiOutShortMsg(h_midiout, "CC", Channel, A_Index + 10, 127)


;pause
  Sleep %NoteDur%
 
 ;Send Note-Off command for middle C 
  midiOutShortMsg(h_midiout, "CC", Channel, A_Index + 10, 0)
}  
  Sleep %NoteDur%
  midiOutShortMsg(h_midiout, "CC", Channel, 80, 0)
  Sleep %NoteDur%
  midiOutShortMsg(h_midiout, "CC", Channel, 81, 0)

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


    solo1 := 0
    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[1].Solo", "Float*", solo1)


    solo2 := 0
    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[4].Solo", "Float*", solo2)


    solo3 := 0
    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[5].Solo", "Float*", solo3)


    solo4 := 0
    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[6].Solo", "Float*", solo4)


    solo5 := 0
    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[7].Solo", "Float*", solo5)








    eq := 0
    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Bus[0].EQ.on", "Float*", eq)
    if(eq > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 44, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 44, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Bus[1].EQ.on", "Float*", eq)
    if(eq > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 45, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 45, 0)
    }



    B1 := 0
    
    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[0].B1", "Float*", B1)
    if(B1 > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 38, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 38, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[1].B1", "Float*", B1)
    if(B1 > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 39, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 39, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[4].B1", "Float*", B1)
    if(B1 > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 40, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 40, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[5].B1", "Float*", B1)
    if(B1 > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 41, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 41, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[6].B1", "Float*", B1)
    if(B1 > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 42, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 42, 0)
    }

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Strip[7].B1", "Float*", B1)
    if(B1 > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 43, 127)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 43, 0)
    }

    A1tv := 0

    DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", "Bus[0].mode.normal", "Float*", A1tv)
    if(A1tv > 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 36, 0)
    } else {
      midiOutShortMsg(h_midiout, "CC", Channel, 36, 127)
    }



  } else {
    Sleep, 10
    keepalive += 1
    threshold := 30
    if(keepalive > threshold) {
      midiOutShortMsg(h_midiout, "CC", Channel, 0, 0)
      keepalive := 0
    }




     if(solo0 > 0 and keepalive < threshold / 2) {
        if(solo0state = 0) {
          solo0state := 1
          solochange := 1
        }
      } else {
        if(solo0state = 1) {
          solo0state := 0
          solochange := 1
        }
      }
     if(solo1 > 0 and keepalive < threshold / 2) {
        if(solo1state = 0) {
          solo1state := 1
          solochange := 1
        }
      } else {
        if(solo1state = 1) {
          solo1state := 0
          solochange := 1
        }
      }
     if(solo2 > 0 and keepalive < threshold / 2) {
        if(solo2state = 0) {
          solo2state := 1
          solochange := 1
        }
      } else {
        if(solo2state = 1) {
          solo2state := 0
          solochange := 1
        }
      }
     if(solo3 > 0 and keepalive < threshold / 2) {
        if(solo3state = 0) {
          solo3state := 1
          solochange := 1
        }
      } else {
        if(solo3state = 1) {
          solo3state := 0
          solochange := 1
        }
      }
     if(solo4 > 0 and keepalive < threshold / 2) {
        if(solo4state = 0) {
          solo4state := 1
          solochange := 1
        }
      } else {
        if(solo4state = 1) {
          solo4state := 0
          solochange := 1
        }
      }
     if(solo5 > 0 and keepalive < threshold / 2) {
        if(solo5state = 0) {
          solo5state := 1
          solochange := 1
        }
      } else {
        if(solo5state = 1) {
          solo5state := 0
          solochange := 1
        }
      }

    if(solochange) {
      solochange := 0
      if(solo0state = 1) {
        midiOutShortMsg(h_midiout, "CC", Channel, 29, 127)
      } else if (solo0state = 0) {
        midiOutShortMsg(h_midiout, "CC", Channel, 29, 0)
      }
      if(solo1state = 1) {
        midiOutShortMsg(h_midiout, "CC", Channel, 30, 127)
      } else if (solo1state = 0) {
        midiOutShortMsg(h_midiout, "CC", Channel, 30, 0)
      }
      if(solo2state = 1) {
        midiOutShortMsg(h_midiout, "CC", Channel, 31, 127)
      } else if (solo2state = 0) {
        midiOutShortMsg(h_midiout, "CC", Channel, 31, 0)
      }
      if(solo3state = 1) {
        midiOutShortMsg(h_midiout, "CC", Channel, 33, 127)
      } else if (solo3state = 0) {
        midiOutShortMsg(h_midiout, "CC", Channel, 33, 0)
      }
      if(solo4state = 1) {
        midiOutShortMsg(h_midiout, "CC", Channel, 34, 127)
      } else if (solo4state = 0) {
        midiOutShortMsg(h_midiout, "CC", Channel, 34, 0)
      }
      if(solo5state = 1) {
        midiOutShortMsg(h_midiout, "CC", Channel, 35, 127)
      } else if (solo5state = 0) {
        midiOutShortMsg(h_midiout, "CC", Channel, 35, 0)
      }

    }


    ; if(solo0 > 0 and keepalive < threshold / 2 and solo0state = 0) {
    ;   midiOutShortMsg(h_midiout, "CC", Channel, 29, 127)
    ;   solo0state := 1
    ; } 
    ; if(not solo5 and solo0state = 1) {
    ;   midiOutShortMsg(h_midiout, "CC", Channel, 29, 0)
    ;   solo0state := 0
    ; }

    ; if(solo1 > 0 and keepalive < threshold / 2 and solo1state = 0) {
    ;   midiOutShortMsg(h_midiout, "CC", Channel, 30, 127)
    ;   solo1state := 1
    ; } 
    ; if(not solo5 and solo1state = 1) {
    ;   midiOutShortMsg(h_midiout, "CC", Channel, 30, 0)
    ;   solo1state := 0
    ; }

    ; if(solo2 > 0 and keepalive < threshold / 2 and solo2state = 0) {
    ;   midiOutShortMsg(h_midiout, "CC", Channel, 31, 127)
    ;   solo2state := 1
    ; } 
    ; if(not solo5 and solo2state = 1) {
    ;   midiOutShortMsg(h_midiout, "CC", Channel, 31, 0)
    ;   solo2state := 0
    ; }

    ; if(solo3 > 0 and keepalive < threshold / 2 and solo3state = 0) {
    ;   midiOutShortMsg(h_midiout, "CC", Channel, 33, 127)
    ;   solo3state := 1
    ; } 
    ; if(not solo5 and solo3state = 1) {
    ;   midiOutShortMsg(h_midiout, "CC", Channel, 33, 0)
    ;   solo3state := 0
    ; }

    ; if(solo4 > 0 and keepalive < threshold / 2 and solo4state = 0) {
    ;   midiOutShortMsg(h_midiout, "CC", Channel, 34, 127)
    ;   solo4state := 1
    ; } 
    ; if(not solo5 and solo4state = 1) {
    ;   midiOutShortMsg(h_midiout, "CC", Channel, 34, 0)
    ;   solo4state := 0
    ; }
    
    ; if(solo5 > 0 and keepalive < threshold / 2 and solo5state = 0) {
    ;   midiOutShortMsg(h_midiout, "CC", Channel, 35, 127)
    ;   solo5state := 1
    ; }
    ; if(not solo5 and solo5state = 1) {
    ;   midiOutShortMsg(h_midiout, "CC", Channel, 35, 0)
    ;   solo5state := 0
    ; }

    gdm()
    if(playing and playstate = 0) {
      midiOutShortMsg(h_midiout, "CC", Channel, 55, 127)
      playstate := 1
    }
    if(not playing and playstate = 1) {
      midiOutShortMsg(h_midiout, "CC", Channel, 55, 0)
      playstate := 0      
    }




    if(playing) {



      if(playpercent > 0) {
        if(p1state = 0) {
          p1state := 1
          change := 1
        }
      } else {
        if(p1state = 1) {
          p1state := 0
          change := 1
        }
      }
      if(playpercent > 1) {
        if(p2state = 0) {
          p2state := 1
          change := 1
        }
      } else {
        if(p2state = 1) {
          p2state := 0
          change := 1
        }
      }
      if(playpercent > 2) {
        if(p3state = 0) {
          p3state := 1
          change := 1
        }
      } else {
        if(p3state = 1) {
          p3state := 0
          change := 1
        }
      }
      if(playpercent > 3) {
        if(p4state = 0) {
          p4state := 1
          change := 1
        }
      } else {
        if(p4state = 1) {
          p4state := 0
          change := 1
        }
      }
      if(playpercent > 4) {
        if(p5state = 0) {
          p5state := 1
          change := 1
        }
      } else {
        if(p5state = 1) {
          p5state := 0
          change := 1
        }
      }
      if(playpercent > 5) {
        if(p6state = 0) {
          p6state := 1
          change := 1
        }
      } else {
        if(p6state = 1) {
          p6state := 0
          change := 1
        }
      }
      if(playpercent > 6) {
        if(p7state = 0) {
          p7state := 1
          change := 1
        }
      } else {
        if(p7state = 1) {
          p7state := 0
          change := 1
        }
      }
      if(playpercent > 7) {
        if(p8state = 0) {
          p8state := 1
          change := 1
        }
      } else {
        if(p8state = 1) {
          p8state := 0
          change := 1
        }
      }
      if(liked) {
        midiOutShortMsg(h_midiout, "CC", Channel, 80, 127)
      } else {
        midiOutShortMsg(h_midiout, "CC", Channel, 80, 0)
      }
      if(unliked) {
        midiOutShortMsg(h_midiout, "CC", Channel, 63, 127)
      } else {
        midiOutShortMsg(h_midiout, "CC", Channel, 63, 0)
      }

    }
    if(not playing) {
      if(p1state = 1) {
        p1state = 0
        change = 1
      }
      if(p2state = 1) {
        p2state = 0
        change = 1
      }
      if(p3state = 1) {
        p3state = 0
        change = 1
      }
      if(p4state = 1) {
        p4state = 0
        change = 1
      }
      if(p5state = 1) {
        p5state = 0
        change = 1
      }
      if(p6state = 1) {
        p6state = 0
        change = 1
      }
      if(p7state = 1) {
        p7state = 0
        change = 1
      }
      if(p8state = 1) {
        p8state = 0
        change = 1
      }

    }

    if(change) {
      change := 0
      if(p1state = 1) {
        midiOutShortMsg(h_midiout, "CC", Channel, 46, 127)
      } else if (p1state = 0) {
        midiOutShortMsg(h_midiout, "CC", Channel, 46, 0)
      }

      if(p2state = 1) {
        midiOutShortMsg(h_midiout, "CC", Channel, 47, 127)
      } else if (p2state = 0) {
        midiOutShortMsg(h_midiout, "CC", Channel, 47, 0)
      }

      if(p3state = 1) {
        midiOutShortMsg(h_midiout, "CC", Channel, 48, 127)
      } else if (p3state = 0) {
        midiOutShortMsg(h_midiout, "CC", Channel, 48, 0)
      }

      if(p4state = 1) {
        midiOutShortMsg(h_midiout, "CC", Channel, 49, 127)
      } else if (p4state = 0) {
        midiOutShortMsg(h_midiout, "CC", Channel, 49, 0)
      }

      if(p5state = 1) {
        midiOutShortMsg(h_midiout, "CC", Channel, 50, 127)
      } else if (p5state = 0) {
        midiOutShortMsg(h_midiout, "CC", Channel, 50, 0)
      }

      if(p6state = 1) {
        midiOutShortMsg(h_midiout, "CC", Channel, 51, 127)
      } else if (p6state = 0) {
        midiOutShortMsg(h_midiout, "CC", Channel, 51, 0)
      }

      if(p7state = 1) {
        midiOutShortMsg(h_midiout, "CC", Channel, 52, 127)
      } else if (p7state = 0) {
        midiOutShortMsg(h_midiout, "CC", Channel, 52, 0)
      }

      if(p8state = 1) {
        midiOutShortMsg(h_midiout, "CC", Channel, 53, 127)
      } else if (p8state = 0) {
        midiOutShortMsg(h_midiout, "CC", Channel, 53, 0)
      }
    }
  }
  if(ErrorLevel = -1) {
  	sleep 1000
  	reload
  }
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

  RegExMatch(json, "O).liked.: (true|false)", gdmliked)
  if(gdmliked.1 = "true") {
    liked := 1
  } else if(gdmliked.1 = "false") {
    liked := 0
  }
  RegExMatch(json, "O).unliked.: (true|false)", gdmunliked)
  if(gdmunliked.1 = "true") {
    unliked := 1
  } else if(gdmunliked.1 = "false") {
    unliked := 0
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



