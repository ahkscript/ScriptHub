; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=126579
; Author: Flipeador

; -----------------------------        WinCloseEx          -----------------------------
;author:	Flipeador
;forum:		https://www.autohotkey.com/boards/viewtopic.php?p=119186&sid=a23658e68fed5bb77cf5268cada39404#p119186
/*
hWnd: Window ID.
Force:
			0 = WM_CLOSE.
			1 = TerminateThread.
			2 = TerminateProcess.
			3 = if TerminateThread fails, try TerminateProcess.
*/

WinCloseEx(hWnd := 0, Force := false) {
	if !StrLen(hWnd)
		hWnd := WinExist(hWnd)

	if (Force = 1) || (Force = 2) || (Force = 3) {
		if !(ThreadId := DllCall("User32.dll\GetWindowThreadProcessId", "Ptr", hWnd, "UIntP", &ProcessId, "UInt"))
			return false

		;maybe you could try terminate the thread...
		if (Force = 1) || (Force = 3)
			hThread := DllCall("Kernel32.dll\OpenThread", "UInt", 0x0001, "Int", false, "UInt", ThreadId, "Ptr")			, Result := DllCall("Kernel32.dll\TerminateThread", "Ptr", hThread, "UInt", 0)			, DllCall("Kernel32.dll\CloseHandle", "Ptr", hThread)

		;this is how winkill works if WM_CLOSE fail.
		if (Force = 2) || ((Force = 3) && !(Result))
			hProcess := DllCall("Kernel32.dll\OpenProcess", "UInt", 0x0001, "Int", false, "UInt", ProcessId, "Ptr")			, Result := DllCall("Kernel32.dll\TerminateProcess", "Ptr", hProcess, "UInt", 0)			, DllCall("Kernel32.dll\CloseHandle", "Ptr", hProcess)

		return Result
		}

	if !DllCall("User32.dll\IsWindow", "Ptr", hWnd) || DllCall("User32.dll\IsHungAppWindow", "Ptr", hWnd)
		return false

	;normal method
	Result := DllCall("User32.dll\PostMessageW", "Ptr", hWnd, "UInt", 0x0002, "Ptr", 0, "Ptr", 0)
	DllCall("User32.dll\PostMessageW", "Ptr", hWnd, "UInt", 0x112, "Ptr", 0xF060, "Ptr", 0)
	return Result
	}