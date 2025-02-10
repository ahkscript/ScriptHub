; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=133668
; Author: SKAN

RunCMD(P_CmdLine, P_WorkingDir := "", P_Codepage := "cp0", P_Func := 0, P_Slow := 1)
{  ;  RunCMD v1.00.2 for ah2 By SKAN on D67D/D7AF @ autohotkey.com/r/?t=133668
   ;  Based on StdOutToVar.ahk by Sean @ www.autohotkey.com/board/topic/15455-stdouttovar

    Local  hPipeR                :=  0
        ,  hPipeW                :=  0
        ,  PIPE_NOWAIT           :=  1
        ,  HANDLE_FLAG_INHERIT   :=  1
        ,  dwMask                :=  HANDLE_FLAG_INHERIT
        ,  dwFlags               :=  HANDLE_FLAG_INHERIT

    DllCall("Kernel32\CreatePipe", "ptrp",&hPipeR, "ptrp",&hPipeW, "ptr",0, "int",0)
  , DllCall("Kernel32\SetHandleInformation", "ptr",hPipeW, "int",dwMask, "int",dwFlags)

    Local  B_OK                  :=  0
        ,  P8                    :=  A_PtrSize = 8
        ,  STARTF_USESTDHANDLES  :=  0x100
        ,  STARTUPINFO           :=  Buffer(P8 ? 104 : 68, 0)                  ;  STARTUPINFO

    NumPut("uint", P8 ? 104 : 68, STARTUPINFO)                                 ;  STARTUPINFO.cb
  , NumPut("uint", STARTF_USESTDHANDLES, STARTUPINFO, P8 ? 60 : 44)            ;  STARTUPINFO.dwFlags
  , NumPut("ptr",  hPipeW, STARTUPINFO, P8 ? 88 : 60)                          ;  STARTUPINFO.hStdOutput
  , NumPut("ptr",  hPipeW, STARTUPINFO, P8 ? 96 : 64)                          ;  STARTUPINFO.hStdError

    Local  CREATE_NO_WINDOW      :=  0x08000000
        ,  PRIORITY_CLASS        :=  DllCall("Kernel32\GetPriorityClass", "ptr",-1, "uint")
        ,  PROCESS_INFORMATION   :=  Buffer(P8 ?  24 : 16, 0)                  ;  PROCESS_INFORMATION

    RunCMD.PID        :=  0
  , RunCMD.ExitCode   :=  0
  , RunCMD.Iterations :=  0
    
  , B_OK :=  DllCall( "Kernel32\CreateProcessW"
                    , "ptr", 0                                                 ;  lpApplicationName
                    , "ptr", StrPtr(P_CmdLine)                                 ;  lpCommandLine
                    , "ptr", 0                                                 ;  lpProcessAttributes
                    , "ptr", 0                                                 ;  lpThreadAttributes
                    , "int", True                                              ;  bInheritHandles
                    , "int", CREATE_NO_WINDOW | PRIORITY_CLASS                 ;  dwCreationFlags
                    , "int", 0                                                 ;  lpEnvironment
                    , "ptr", DirExist(P_WorkingDir) ? StrPtr(P_WorkingDir) : 0 ;  lpCurrentDirectory
                    , "ptr", STARTUPINFO                                       ;  lpStartupInfo
                    , "ptr", PROCESS_INFORMATION                               ;  lpProcessInformation
                    , "uint" )

    DllCall("Kernel32\CloseHandle", "ptr",hPipeW)

    If (  B_OK = False  
    and   DllCall("Kernel32\CloseHandle", "ptr",hPipeR)  )
          Return 

    RunCMD.PID := NumGet(PROCESS_INFORMATION, P8 ? 16 : 8, "uint")

    Local  FileObj               :=  FileOpen(hPipeR, "h", P_Codepage)
        ,  Line                  :=  ""
        ,  LineNum               :=  1
        ,  sOutput               :=  ""
        ,  CRLF                  :=  "`r`n"
    
    Delay() =>  ( Sleep(P_Slow), RunCMD.Iterations += 1 )

    While   DllCall("Kernel32\PeekNamedPipe", "ptr",hPipeR, "ptr",0, "int",0, "ptr",0, "ptr",0, "ptr",0)
      and   RunCMD.PID and Delay()
            While  (  RunCMD.PID != 0 and FileObj.AtEOF != 1  )
                      Line       :=  FileObj.ReadLine()
                   ,  sOutput    .=  P_Func  ?  P_Func.Call(Line CRLF, LineNum++) 
                                             :  Line CRLF

    Local  hProcess              :=  NumGet(PROCESS_INFORMATION, 0, "ptr")
        ,  hThread               :=  NumGet(PROCESS_INFORMATION, A_PtrSize, "ptr")
        ,  ExitCode              :=  0

    DllCall("Kernel32\GetExitCodeProcess", "ptr",hProcess, "ptrp",&ExitCode)
  , DllCall("Kernel32\CloseHandle", "ptr",hProcess)
  , DllCall("Kernel32\CloseHandle", "ptr",hThread)
  , DllCall("Kernel32\CloseHandle", "ptr",hPipeR)
  , RunCMD.PID                   :=  0
  , RunCMD.ExitCode              :=  ExitCode
  
    Return RTrim(sOutput, CRLF)
}