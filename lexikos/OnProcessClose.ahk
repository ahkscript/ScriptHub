; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=110691
; Author: lexikos

/*
OnProcessClose:
  Registers *callback* to be called when the process identified by *proc*
  exits, or after *timeout* milliseconds if it has not exited.
@arg proc - A process handle as either an Integer or an object with `.ptr`.
@arg callback - A function with signature `callback(handle, timedOut)`.\
  `handle` is a ProcessHandle with properties `ID`, `ExitCode` and `Ptr` (process handle).\
  `timedOut` is true if the wait timed out, otherwise false.
@arg timeout - The timeout in milliseconds. If omitted or -1, the wait
  never times out. If 0, the callback is called immediately.
@returns {RegisteredWait} - Optionally use the `Unregister()` method
  of the returned object to unregister the callback.
*/
OnProcessClose(proc, callback, timeout?) {
    if !(proc is Integer || proc := ProcessExist(proc))
        throw ValueError("Invalid PID or process name", -1, proc)
    if !proc := DllCall("OpenProcess", "uint", 0x101000, "int", false, "uint", proc, "ptr")
        throw OSError()
    return RegisterWaitCallback(ProcessHandle(proc), callback, timeout?)
}

class ProcessHandle {
    __new(handle) {
        this.ptr := handle
    }
    __delete() => DllCall("CloseHandle", "ptr", this)
    ID => DllCall("GetProcessId", "ptr", this)
    ExitCode {
        get {
            if !DllCall("GetExitCodeProcess", "ptr", this, "uint*", &exitCode:=0)
                throw OSError()
            return exitCode
        }
    }
}

#include RegisterWaitCallback.ahk