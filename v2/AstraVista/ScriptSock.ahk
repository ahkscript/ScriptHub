; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=126320
; Author: AstraVista

#Requires AutoHotkey v2

; ----------------------------------------------------------------------------------------------------------------------------------
; ScriptSock
; Communication Between AutoHotkey Scripts
;
; AutoHotkey V2 (2.0.11)
;
; Author: AstraVista
; Version: 2014.02.21
;
; Originated from talk class:
;	https://www.autohotkey.com/board/topic/94321-talk-interscript-communication-provider-and-more/
;	https://github.com/aviaryan/autohotkey-scripts/blob/master/Functions/talk.ahk
; ----------------------------------------------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------------------------------------------
; ScriptSock Help
;
; - There are two ways to set variable in target script.
;
;	(1) SetVar()
;		: Replace target script's variable with sending data.
;
;	(2) PostVar()
;		: Send and save value to target script's message storage, which is awating fetched from the script.
;
; - There are two ways to get variable from target script.
;
;	(1) GetVar()
;		: Get value from target script directly.
;
;	(2) FetchVar()
;		: Fetch value from script's message storage saved by target script
;
; - Etc
;
; 	- PushVar()
;		: Change value in own's message storage, after data is set by other scripts.
;-----------------------------------------------------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------------------------------------------------
; SendMessage() Help
;
; * When Sender() calls SendMessage()...
;
;		: SendMessage() always returns when a result is received or when an error such as timeout.
;		: Default waiting time is 5000ms.
;		: If there is no error, SendMessage() always returns after receiving and processing data in Receiver() which is OnMessage()'s callback.
;
;	- When SendMessage() returns normally...
;		: Then Sender() returns.
;		-> Since the results have already been saved, return immediately without any longer.
;
;	- When SendMessage() returns with an error
;		1. If an error occurs due to an abnormality such as an internal error or target window error...
;			: Sender() returns immediately.
;			: Result values cannot be received from Receiver() which is OnMessage()'s callback.
;			-> Therefore, return the error immediately.
;
;		2. In case of TimeoutError...
;			(1) There are two ways, when the result value is delayed due to MsgBox() in debugging...
;				- After Sender() returns, wait significant time for a message to come in and then return when time is out.
;				- Increase the default waiting time of SendMessage() significantly and return immediately when an error occurs.
;				: Both are similar method (The code adopts the later)
;
;			(2) OnMessage() cannot receive message due to lag or delays in the script.
;				: Since the default waiting time of SendMessage() is 5000ms, it is sufficient enough unless the script stops.
;				-> Therefore, if an error occurs, return immediately.
;
;			: In Receiver() which is OnMessage()'s callback, it is not possible to know whether data will be received or not.
;				- Wait longer after Sender() returns
;					: Even though, still may not receive message
;				- Wait longer before SendMessage() returns
;					: Even though, still may not receive message
; ----------------------------------------------------------------------------------------------------------------------------------

; **********************************************************************************************************************************
; ScriptSock Class
; **********************************************************************************************************************************

class ScriptSock
{
	; Variable storage
	static aVar := Map()

	static sTargetScript := ""
	static sSourceScript := ""

	; Error Message
	static sMsgError := "^Error^"

	; When put this sign to end of variable when querying, script automatically enters to debug mode!
	static sDebugSign := "#"
	static bDebug := false
	static bDebugBeep := true
	; Debug message when successful return of SendMessage()
	static bDebugSuccess := false

	; Standard waiting time after return of static Sender() in normal runs (Not require)
	static iWaitTimeAfterReturn := 0
	; Default = 5000, 0 = Forever waiting
	static iWaitTimeNormalSend := 30 * 1000
	; Extended waiting time after return of SendMessage() in debug mode
	static iWaitTimeDebugSend := 600 * 1000

	static __New()
	{
		; WM_COPYDATA = 0x004A
		; Only static function can be callback function.
		; Class instances can register different names of callback function (%Callback Function Name%)
		; All registering callback functions of OnMessage() receive message at the same time.

		this.ReceiverProc := ObjBindMethod(ScriptSock, "Receiver")
		OnMessage(0x004A, this.ReceiverProc)
	}

	__New(sTargetScript)
	{
		; Target script to send
		; Add "\" in the head of script name for avoiding duplication of other windows.
		; If "\" is ommited, SendMessege() would send messages to active window of similar name like '???.ahk - SciTE4AutoHotkey'.
		ScriptSock.sTargetScript := (InStr(sTargetScript, "\")) ? sTargetScript : "\" sTargetScript

		; Source script to send
		ScriptSock.sSourceScript := "\" A_ScriptName

		try
		{
			iPrevDetectHiddenWindows := A_DetectHiddenWindows
			iPrevTitleMatchMode := A_TitleMatchMode
			DetectHiddenWindows(True)
			SetTitleMatchMode(2)

			sTitle := WinGetTitle("ahk_id " A_ScriptHwnd)
			sTitle := StrSplit(sTitle, " - AutoHotkey v")[1]
			if (InStr(sTitle, "\"))
			{
				ScriptSock.sSourceScript := "\" SubStr(sTitle, InStr(sTitle, "\", , -1) + 1)
			}
			else
			{
				ScriptSock.sSourceScript := "\" sTitle
			}

			DetectHiddenWindows(iPrevDetectHiddenWindows)
			SetTitleMatchMode(iPrevTitleMatchMode)
		}
	}

	Call(sTargetScript)
	{
		this.__New(sTargetScript)
		return (this)
	}

	__Item[sVarName := ""]
	{
		get
		{
			sVarName := StrReplace(sVarName, ScriptSock.sDebugSign)
			return (ScriptSock.aVar[sVarName])
		}
		set
		{
			sVarName := StrReplace(sVarName, ScriptSock.sDebugSign)
			ScriptSock.aVar[sVarName] := Value
		}
	}

	; ------------------------------------------------------------------------------------------------------------------------------
	; GetVar() Method
	; ------------------------------------------------------------------------------------------------------------------------------

	GetVar(sVarName)
	{
		ScriptSock.aVar[sVarName] := ScriptVar(ScriptSock.sSourceScript, "GetVar", sVarName)
		oSendVar := ScriptSock.aVar[sVarName].Clone()

		if (InStr(sVarName, ScriptSock.sDebugSign))
		{
			sVarName := StrReplace(sVarName, ScriptSock.sDebugSign)
			oSendVar.sVarName := sVarName
			oSendVar.bDebug := true
			ScriptSock.bDebug := true
		}
		else
		{
			ScriptSock.bDebug := false
		}

		; Waiting until return of SendMessage()
		vResult := ScriptSock.Sender(ScriptSock.sTargetScript, oSendVar)

		; Return of Sender() - 0: Success, Others: Error
		iLoopMaxTime := (vResult) ? 0 : ScriptSock.iWaitTimeAfterReturn

		; SendMessage() always return after bReceive is set, if not an error.
		; Therefore, this routine would not be required.
		iLoopTiming := 10
		iLoopCount := iLoopMaxTime / iLoopTiming
		Loop (iLoopCount)
		{
			if (ScriptSock.aVar[sVarName].bReceive)
			{
				break
			}

			Sleep(iLoopTiming)
		}

		if (ScriptSock.aVar.Has(sVarName))
		{
			if (ScriptSock.bDebug)
			{
				MsgBox("ScriptSock GetVar() `n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`n•   Packet = [" ScriptSock.aVar[sVarName].Packet() "]`n`n← [" ScriptSock.sTargetScript "]", , "4096")
			}

			if (ScriptSock.aVar[sVarName].bReceive)
			{
				vReturn := ScriptSock.aVar[sVarName].vData
				sMsgError := this.ExceptionStr("GetVar", sVarName, ScriptSock.sMsgError, ScriptSock.aVar[sVarName].vArg)
			}
			else
			{
				vReturn := ScriptSock.sMsgError
				sMsgError := this.ExceptionStr("GetVar", sVarName, ScriptSock.sMsgError, vResult)
			}

			ScriptSock.aVar[sVarName].bReceive := false
		}
		else
		{
			if (ScriptSock.bDebug)
			{
				MsgBox("ScriptSock GetVar() `n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`n•   Packet = [" "]`n`n← [" ScriptSock.sTargetScript "]", , "4096")
			}

			vReturn := ScriptSock.sMsgError
			sMsgError := this.ExceptionStr("GetVar", sVarName, ScriptSock.sMsgError, vResult)
		}

		ScriptSock.bDebug := false

		if (vReturn = ScriptSock.sMsgError)
		{
			throw(Error(sMsgError))
		}

		return (vReturn)
	}

	; ------------------------------------------------------------------------------------------------------------------------------
	; SetVar() Method
	; ------------------------------------------------------------------------------------------------------------------------------

	SetVar(sVarName, vSetValue)
	{
		ScriptSock.aVar[sVarName] := ScriptVar(ScriptSock.sSourceScript, "SetVar", sVarName, vSetValue)
		oSendVar := ScriptSock.aVar[sVarName].Clone()

		if (InStr(sVarName, ScriptSock.sDebugSign))
		{
			sVarName := StrReplace(sVarName, ScriptSock.sDebugSign)
			oSendVar.sVarName := sVarName
			oSendVar.bDebug := true
			ScriptSock.bDebug := true
		}
		else
		{
			ScriptSock.bDebug := false
		}

		; Waiting until return of SendMessage()
		vResult := ScriptSock.Sender(ScriptSock.sTargetScript, oSendVar)

		; Returns of ScriptSock.Sender() - 0: success, others: error
		iLoopMaxTime := (vResult) ? 0 : ScriptSock.iWaitTimeAfterReturn

		; SendMessage() always return after bReceive is set, if not an error.
		; Therefore, this routine would not be required.
		iLoopTiming := 10
		iLoopCount := iLoopMaxTime / iLoopTiming
		Loop (iLoopCount)
		{
			if (ScriptSock.aVar[sVarName].bReceive)
			{
				break
			}

			Sleep(iLoopTiming)
		}

		if (ScriptSock.aVar.Has(sVarName))
		{
			if (ScriptSock.bDebug)
			{
				MsgBox("ScriptSock SetVar() `n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`n•   Packet = [" ScriptSock.aVar[sVarName].Packet() "]`n`n← [" ScriptSock.sTargetScript "]", , "4096")
			}

			if (ScriptSock.aVar[sVarName].bReceive)
			{
				vReturn := (ScriptSock.aVar[sVarName].vData = vSetValue) ? true : false
				sMsgError := this.ExceptionStr("SetVar", sVarName, ScriptSock.sMsgError, ScriptSock.aVar[sVarName].vArg)
			}
			else
			{
				vReturn := ScriptSock.sMsgError
				sMsgError := this.ExceptionStr("SetVar", sVarName, ScriptSock.sMsgError, vResult)
			}

			ScriptSock.aVar[sVarName].bReceive := false
		}
		else
		{
			if (ScriptSock.bDebug)
			{
				MsgBox("ScriptSock SetVar() `n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`n•   Packet = [" "]`n`n← [" ScriptSock.sTargetScript "]", , "4096")
			}

			vReturn := ScriptSock.sMsgError
			sMsgError := this.ExceptionStr("SetVar", sVarName, ScriptSock.sMsgError, vResult)
		}

		if (ScriptSock.bDebug)
		{
			MsgBox("ScriptSock SetVar() `n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`n•   Packet = [" ScriptSock.aVar[sVarName].Packet() "]`n`n← [" ScriptSock.sTargetScript "]", , "4096")
		}

		ScriptSock.aVar[sVarName].bReceive := false
		ScriptSock.bDebug := false

		if (vReturn = ScriptSock.sMsgError)
		{
			throw(Error(sMsgError))
		}

		return (vReturn)
	}

	; ------------------------------------------------------------------------------------------------------------------------------
	; FetchVar() Method
	; ------------------------------------------------------------------------------------------------------------------------------

	FetchVar(sVarName, vDefault := ScriptSock.sMsgError)
	{
		if (ScriptSock.aVar.Has(sVarName))
		{
			if (ScriptSock.aVar[sVarName].bReceive)
			{
				ScriptSock.aVar[sVarName].bReceive := false
			}

			vReturn := ScriptSock.aVar[sVarName].vData
		}
		else
		{
			vReturn := vDefault
		}

		sMsgError := this.ExceptionStr("FetchVar", sVarName, vReturn, "Error: Variable not found.")

		if (vReturn = ScriptSock.sMsgError)
		{
			throw(Error(sMsgError))
		}

		return (vReturn)
	}

	; ------------------------------------------------------------------------------------------------------------------------------
	; PushVar() Method
	; ------------------------------------------------------------------------------------------------------------------------------

	PushVar(sVarName, vSetValue, vDefault := ScriptSock.sMsgError)
	{
		if (ScriptSock.aVar.Has(sVarName))
		{
			if (!ScriptSock.aVar[sVarName].bReceive)
			{
				ScriptSock.aVar[sVarName].vData := vSetValue
				vReturn := (!vDefault)
			}
			else
			{
				vReturn := vDefault
			}
		}
		else
		{
			vReturn := vDefault
		}

		sMsgError := this.ExceptionStr("PushVar", sVarName, vReturn, "Error: Variable not found.")

		if (vReturn = ScriptSock.sMsgError)
		{
			throw(Error(sMsgError))
		}

		return (vReturn)
	}

	; ------------------------------------------------------------------------------------------------------------------------------
	; PostVar() Method
	; ------------------------------------------------------------------------------------------------------------------------------

	PostVar(sVarName, vSetValue, vDefault := ScriptSock.sMsgError)
	{
		ScriptSock.aVar[sVarName] := ScriptVar(ScriptSock.sSourceScript, "PostVar", sVarName, vSetValue)
		oSendVar := ScriptSock.aVar[sVarName].Clone()

		if (InStr(sVarName, ScriptSock.sDebugSign))
		{
			sVarName := StrReplace(sVarName, ScriptSock.sDebugSign)
			oSendVar.sVarName := sVarName
			oSendVar.bDebug := true
			ScriptSock.bDebug := true
		}
		else
		{
			ScriptSock.bDebug := false
		}

		; Waiting until return of SendMessage()
		vResult := ScriptSock.Sender(ScriptSock.sTargetScript, oSendVar)

		; Returns of ScriptSock.Sender() - 0: success, others: error
		iLoopMaxTime := (vResult) ? 0 : ScriptSock.iWaitTimeAfterReturn

		; SendMessage() always will return after setting of .bReceive, if not error.
		; So, this routine would not be required.
		iLoopTiming := 10
		iLoopCount := iLoopMaxTime / iLoopTiming
		Loop (iLoopCount)
		{
			if (ScriptSock.aVar[sVarName].bReceive)
			{
				break
			}

			Sleep(iLoopTiming)
		}

		if (ScriptSock.aVar.Has(sVarName))
		{
			if (ScriptSock.bDebug)
			{
				MsgBox("ScriptSock PostVar() `n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`n•   Packet = [" ScriptSock.aVar[sVarName].Packet() "]`n`n← [" ScriptSock.sTargetScript "]", , "4096")
			}

			if (ScriptSock.aVar[sVarName].bReceive)
			{
				vReturn := (ScriptSock.aVar[sVarName].vData = vSetValue) ? true : false
				sMsgError := this.ExceptionStr("PostVar", sVarName, ScriptSock.sMsgError, ScriptSock.aVar[sVarName].vArg)
			}
			else
			{
				vReturn := ScriptSock.sMsgError
				sMsgError := this.ExceptionStr("PostVar", sVarName, ScriptSock.sMsgError, vResult)
			}

			ScriptSock.aVar[sVarName].bReceive := false
		}
		else
		{
			if (ScriptSock.bDebug)
			{
				MsgBox("ScriptSock PostVar() `n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`n•   Packet = [" "]`n`n← [" ScriptSock.sTargetScript "]", , "4096")
			}

			vReturn := ScriptSock.sMsgError
			sMsgError := this.ExceptionStr("PostVar", sVarName, ScriptSock.sMsgError, vResult)
		}

		if (ScriptSock.bDebug)
		{
			MsgBox("ScriptSock PostVar() `n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`n•   Packet = [" ScriptSock.aVar[sVarName].Packet() "]`n`n← [" ScriptSock.sTargetScript "]", , "4096")
		}

		ScriptSock.aVar[sVarName].bReceive := false
		ScriptSock.bDebug := false

		if (vReturn = ScriptSock.sMsgError)
		{
			throw(Error(sMsgError))
		}

		return (vReturn)
	}

	; ------------------------------------------------------------------------------------------------------------------------------
	; Suspend() Method
	; ------------------------------------------------------------------------------------------------------------------------------

	Suspend(iSuspendTime)
	{
		vReturn := ScriptSock.Sender(ScriptSock.sTargetScript, ScriptVar(ScriptSock.sSourceScript, "Suspend", , iSuspendTime))

		return (vReturn)
	}

	; ------------------------------------------------------------------------------------------------------------------------------
	; Terminate() Method
	; ------------------------------------------------------------------------------------------------------------------------------

	Terminate()
	{
		vReturn := ScriptSock.Sender(ScriptSock.sTargetScript, ScriptVar(ScriptSock.sSourceScript, "Terminate"))

		return (vReturn)
	}

	; ------------------------------------------------------------------------------------------------------------------------------
	; ExceptionStr() Method
	; ------------------------------------------------------------------------------------------------------------------------------

	ExceptionStr(sFuncName, sVarName, vData, sErrorMessage)
	{
		sSeperator := "―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――"
		sMsgError := "ScriptSock " sFuncName "()`n" sSeperator "`n[" LTrim(ScriptSock.sSourceScript, "\") "] → [" ScriptSock.sTargetScript "]`n•    [" StrReplace(sVarName, ScriptSock.sDebugSign) "]`n•    [" vData "]`n" sErrorMessage "`n" sSeperator

		return (sMsgError)
	}

; **********************************************************************************************************************************
; Receiver() Method
; **********************************************************************************************************************************

	static Receiver(wParam, lParam, msg, hwnd)
	{
		global

		sReceivePacket := StrGet(NumGet(lParam + 2 * A_PtrSize, 0, "Ptr"))
		oReceiveVar := ScriptVar()
		oReceiveVar.Packet(sReceivePacket)

		ScriptSock.bDebug := oReceiveVar.bDebug

		if (ScriptSock.bDebug)
		{
			MsgBox("Receiver()`n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`nPacket :`n•    Script: [" oReceiveVar.sSenderScript "]`n•    Command: [" oReceiveVar.sCommand "]`n•    VarName:  [" oReceiveVar.sVarName "]`n•    ArgA: [" oReceiveVar.vData "]`n•    ArgB: [" oReceiveVar.vArg "]`n•    Process: [" oReceiveVar.bProcess "]`n•    Debug: [" oReceiveVar.bDebug "]`n`n← [" oReceiveVar.sSenderScript "]", , "4096")
		}

		; --------------------------------------------------------------------------------------------------------------------------
		; GetVar Receiver()
		; --------------------------------------------------------------------------------------------------------------------------
		if (oReceiveVar.sCommand = "GetVar")
		{
			oSendVar := ScriptVar(ScriptSock.sSourceScript, "Output")
			oSendVar.bDebug := oReceiveVar.bDebug ; Important !!

			try
			{
				if (ScriptSock.bDebug)
				{
					MsgBox("Receiver() GetVar `n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`n•    " oReceiveVar.sVarName " = [" %oReceiveVar.sVarName% "]`n•    → [" %oReceiveVar.sVarName% "]", , "4096")
				}

				oSendVar.sVarName := oReceiveVar.sVarName
				oSendVar.vData := %oReceiveVar.sVarName%
				oSendVar.vArg := ""
			}
			catch as oError
			{
				oSendVar.sVarName := oReceiveVar.sVarName
				oSendVar.vData := ScriptSock.sMsgError
				oSendVar.vArg := Type(oError) ": " oError.Message " (Line: " SubStr(oError.File, InStr(oError.File, "\", , -1) + 1) ", "  oError.Line ")"
			}

			if (oSendVar.sVarName = ScriptSock.sMsgError)
			{
				if (ScriptSock.bDebug)
				{
					MsgBox("Receiver() GetVar `n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`n•    " Type(oError) ": " oError.Message " (Line: " oError.Line ")", , "4096")
				}
			}

			ScriptSock.Sender(oReceiveVar.sSenderScript, oSendVar)

			return
		}

		; --------------------------------------------------------------------------------------------------------------------------
		; SetVar Receiver()
		; --------------------------------------------------------------------------------------------------------------------------
		if (oReceiveVar.sCommand = "SetVar")
		{
			oSendVar := ScriptVar(ScriptSock.sSourceScript, "Output")
			oSendVar.bDebug := oReceiveVar.bDebug ; Important !!

			try
			{
				if (ScriptSock.bDebug)
				{
					MsgBox("Receiver() SetVar `n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`n•    " oReceiveVar.sVarName " = [" %oReceiveVar.sVarName% "]`n•    ← " "[SetVar]" " ← [" oReceiveVar.vData "]", , "4096")
				}

				; Dymimic variable input needs to declare global in the top of function
				%oReceiveVar.sVarName% := oReceiveVar.vData

				oSendVar.sVarName := oReceiveVar.sVarName
				oSendVar.vData := %oReceiveVar.sVarName%
				oSendVar.vArg := ""
			}
			catch as oError
			{
				oSendVar.sVarName := oReceiveVar.sVarName
				oSendVar.vData := ScriptSock.sMsgError
				oSendVar.vArg := Type(oError) ": " oError.Message " (Line: " SubStr(oError.File, InStr(oError.File, "\", , -1) + 1) ", "  oError.Line ")"
			}

			if (oSendVar.vData = ScriptSock.sMsgError)
			{
				if (ScriptSock.bDebug)
				{
					MsgBox("Receiver() SetVar `n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`n•    " ((oReceiveVar.bProcess) ? "[Post]": "[Replace]") "`n•    " Type(oError) " : " oError.Message " (Line: " SubStr(oError.File, InStr(oError.File, "\", , -1) + 1) ", "  oError.Line ")", , "4096")
				}
			}

			ScriptSock.Sender(oReceiveVar.sSenderScript, oSendVar)

			return
		}

		; --------------------------------------------------------------------------------------------------------------------------
		; PostVar Receiver()
		; --------------------------------------------------------------------------------------------------------------------------
		if (oReceiveVar.sCommand = "PostVar")
		{
			oSendVar := ScriptVar(ScriptSock.sSourceScript, "Output")
			oSendVar.bDebug := oReceiveVar.bDebug ; Important !!

			try
			{
				if (!ScriptSock.aVar.Has(oReceiveVar.sVarName))
				{
					ScriptSock.aVar[oReceiveVar.sVarName] := ScriptVar()
				}

				if (ScriptSock.bDebug)
				{
					MsgBox("Receiver() PostVar `n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`n•    " oReceiveVar.sVarName " = [" ScriptSock.aVar[oReceiveVar.sVarName].vData "]`n•    ← " "[PostVar]" " [" oReceiveVar.vData "]", , "4096")
				}

				ScriptSock.aVar[oReceiveVar.sVarName].Packet(sReceivePacket)
				ScriptSock.aVar[oReceiveVar.sVarName].bReceive := true

				oSendVar.sVarName := oReceiveVar.sVarName
				oSendVar.vData := ScriptSock.aVar[oReceiveVar.sVarName].vData
				oSendVar.vArg := ""
			}
			catch as oError
			{
				oSendVar.sVarName := oReceiveVar.sVarName
				oSendVar.vData := ScriptSock.sMsgError
				oSendVar.vArg := Type(oError) ": " oError.Message " (Line: " SubStr(oError.File, InStr(oError.File, "\", , -1) + 1) ", "  oError.Line ")"
			}

			if (oSendVar.vData = ScriptSock.sMsgError)
			{
				if (ScriptSock.bDebug)
				{
					MsgBox("Receiver() PostVar `n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`n•    " "[PostVar]" "`n•    " Type(oError) ": " oError.Message " (Line: " SubStr(oError.File, InStr(oError.File, "\", , -1) + 1) ", "  oError.Line ")", , "4096")
				}
			}

			ScriptSock.Sender(oReceiveVar.sSenderScript, oSendVar)

			return
		}

		; --------------------------------------------------------------------------------------------------------------------------
		; Output Receiver()
		; --------------------------------------------------------------------------------------------------------------------------
		if (oReceiveVar.sCommand = "Output")
		{
			if (!ScriptSock.aVar.Has(oReceiveVar.sVarName))
			{
				ScriptSock.aVar[oReceiveVar.sVarName] := ScriptVar()
			}
			ScriptSock.aVar[oReceiveVar.sVarName].Packet(sReceivePacket)
			ScriptSock.aVar[oReceiveVar.sVarName].bReceive := true

			if (ScriptSock.bDebug)
			{
				MsgBox("Receiver() Output `n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`n•   sVarName = [" oReceiveVar.sVarName "]`n•   vData = [" oReceiveVar.vData "]`n•   vArg = [" oReceiveVar.vArg "]`n•   bReceive = [" ScriptSock.aVar[oReceiveVar.sVarName].bReceive "]`n•    → Save" , , "4096")
			}

			return
		}

		; --------------------------------------------------------------------------------------------------------------------------
		; Suspend Receiver()
		; --------------------------------------------------------------------------------------------------------------------------
		if (oReceiveVar.sCommand = "Suspend")
		{
			Suspend()
			Sleep(oReceiveVar.vData)
			Suspend()

			return
		}

		; --------------------------------------------------------------------------------------------------------------------------
		; Terminate Receiver()
		; --------------------------------------------------------------------------------------------------------------------------
		if (oReceiveVar.sCommand = "Terminate")
		{
			ExitApp
		}
	}

; **********************************************************************************************************************************
; Sender() Method
; **********************************************************************************************************************************

	static Sender(sReceiverScript, oSendVar)
	{
		sPacket := oSendVar.Packet()

		oCopyDataStruct := Buffer(3 * A_PtrSize)
		iSize := (StrLen(sPacket) + 1) * 2

		NumPut("Ptr", iSize, "Ptr", StrPtr(sPacket), oCopyDataStruct, A_PtrSize)

		iPrevDetectHiddenWindows := A_DetectHiddenWindows
		iPrevTitleMatchMode := A_TitleMatchMode
		DetectHiddenWindows(True)
		SetTitleMatchMode(2)

		; Make MsgBox() sub window of Receiver() script, otherwise SendMessage() will make OSError(0) error.
		if (ScriptSock.bDebug)
		{
			if (WinExist(sReceiverScript))
			{
				;  (0) = OSError test
				iOwnerID := (1) ? WinGetID(sReceiverScript) : ""
			}
			else
			{
				iOwnerID := 0
			}

			MsgBox("Sender()`n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`nPacket :`n•    Script: [" oSendVar.sSenderScript "]`n•    Command: [" oSendVar.sCommand "]`n•    VarName:  [" oSendVar.sVarName "]`n•    ArgA: [" oSendVar.vData "]`n•    ArgB: [" oSendVar.vArg "]`n•    Process: [" oSendVar.bProcess "]`n•    Debug: [" oSendVar.bDebug "]`n`n→ [" sReceiverScript "]", , "4096 Owner" iOwnerID)
		}

		iWaitTime := (ScriptSock.bDebug) ? ScriptSock.iWaitTimeDebugSend : ScriptSock.iWaitTimeNormalSend

		try
		{
			; WM_COPYDATA = 0x004A
			; SendMessage() returns after end of receiving and processing message of OnMessage() callback function of target script.
			; SendMessage() returns 0 if success.
			; SendMessage() does not send message and return immediately, when an error occurs.
			; Do not use PostMessage().
			vResultValue := SendMessage(0x004A, 0, oCopyDataStruct, , sReceiverScript, , , , iWaitTime)
			vReturn := 0
		}
		catch as oError
		{
			vResultValue := ScriptSock.sMsgError
			vReturn := Type(oError) ": " oError.Message
		}

		if (vResultValue = ScriptSock.sMsgError)
		{
			if (ScriptSock.bDebug)
			{
				if (ScriptSock.bDebugBeep)
				{
					SoundBeep(9000, 50)
					SoundBeep(9000, 50)
				}

				MsgBox("Sender() SendMessage()`n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`n•    Return " Type(oError) ": " oError.Message "`n•    Target Win: [" sReceiverScript "]", , "4096")
			}
		}
		else
		{
			if (ScriptSock.bDebug)
			{
				if (ScriptSock.bDebugSuccess)
				{
					MsgBox("Sender() SendMessage()`n[" LTrim(ScriptSock.sSourceScript, "\") "]`n`n•    Return Success: [" vResultValue "]`n•    Target Win: [" sReceiverScript "]", , "4096")
				}
			}
		}

		DetectHiddenWindows(iPrevDetectHiddenWindows)
		SetTitleMatchMode(iPrevTitleMatchMode)

		return (vReturn)
	}
}

; **********************************************************************************************************************************
; ScriptVar Class
; **********************************************************************************************************************************

class ScriptVar
{
	__New(sSenderScript := "", sCommand := "", sVarName := "", vData := "", vArg := "", bProcess := false, bDebug := false, bReceive := false)
	{
		this.sSenderScript := sSenderScript ; Sender of Message
		this.sCommand := sCommand ; What to do in Receiver()
		this.sVarName := sVarName ; Variable name
		this.vData := vData ; Setting value or getting value
		this.vArg := vArg ; for message
		this.bProcess := bProcess ; for process
		this.bDebug := bDebug ; for debug script
		this.bReceive := bReceive ; for receiving packet

		this.sPacketSeperatorSign := ";" ; Packet seperator
		this.sReplaceSeperatorSign := "^Semicolon^" ; replace packet seperator found in data with this text.
	}

	Call(sPacket := "")
	{
		if (sPacket)
		{
			return(this.Packet(sPacket))
		}
		else
		{
			return (this)
		}
	}

	Packet(sPacket := "")
	{
		SS := this.sPacketSeperatorSign
		SR := this.sReplaceSeperatorSign

		if (sPacket)
		{
			aMessage := StrSplit(sPacket, SS)
			for sItem in aMessage
			{
				aMessage[A_Index] := StrReplace(sItem, SR, SS)
			}

			this.sSenderScript :=(aMessage.Has(1)) ? aMessage[1] : ""
			this.sCommand := (aMessage.Has(2)) ? aMessage[2] : ""
			this.sVarName := (aMessage.Has(3)) ? aMessage[3] : ""
			this.vData := (aMessage.Has(4)) ? aMessage[4] : ""
			this.vArg := (aMessage.Has(5)) ? aMessage[5] : ""
			this.bProcess := (aMessage.Has(6)) ? aMessage[6] : false
			this.bDebug := (aMessage.Has(7)) ? aMessage[7] : false
			this.bReceive := (aMessage.Has(8)) ? aMessage[8] : false

			return (this)
		}
		else
		{
			vNewVarName := StrReplace(this.sVarName, SS, SR)
			sNewArgA := StrReplace(this.vData, SS, SR)
			sNewArgB := StrReplace(this.vArg, SS, SR)

			Return(this.sSenderScript SS this.sCommand SS vNewVarName SS sNewArgA SS sNewArgB SS this.bProcess SS this.bDebug SS this.bReceive)
		}
	}
}