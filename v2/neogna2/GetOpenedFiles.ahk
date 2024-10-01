; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=110405
; Author: neogna2

#Requires AutoHotkey v2
;GetOpenedFiles(PID): return a Map with all filepaths opened in a process (PID)
;  2020-05-31 v1 teadrinker                               https://www.autohotkey.com/r?p=332647
;  2022-11-12 v2.beta14 neogna2                           https://www.autohotkey.com/r?p=490815
GetOpenedFiles(PID) {
    FilesMap := Map()
    static PROCESS_DUP_HANDLE := 0x0040
    hProcess := DllCall("OpenProcess"
        , "UInt", PROCESS_DUP_HANDLE
        , "UInt", 0
        , "UInt", PID
        , "Ptr")

    ;https://learn.microsoft.com/en-us/windows/win32/api/winternl/nf-winternl-ntquerysysteminformation
    ;https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-erref/596a1078-e883-4972-9bbc-49e60bebca55
    ;https://www.geoffchappell.com/studies/windows/km/ntoskrnl/api/ex/sysinfo/handle_ex.htm
    ;https://www.geoffchappell.com/studies/windows/km/ntoskrnl/api/ex/sysinfo/handle_table_entry_ex.htm
    static SystemExtendedHandleInformation := 0x40
    NTSTATUS := BufSize := 1
    while NTSTATUS != 0 
    {
        oBuffer := Buffer(BufSize, 0)
        NTSTATUS := DllCall("ntdll\NtQuerySystemInformation"
            , "Int"  , SystemExtendedHandleInformation
            , "Ptr"  , oBuffer    ;increasingly written until NTSTATUS = 0 (STATUS_SUCCESS)
            , "UInt" , BufSize    ;in
            , "UIntP", &BufSize   ;out
            , "UInt")
    }
  
    ;SYSTEM_HANDLE_INFORMATION_EX struct
    ;---------------------------        offset dec (x64)
    ;ULONG_PTR NumberOfHandles;         0
    ;ULONG_PTR Reserved;                8
    ;SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX  16  (size 40)
    ;SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX  56  
    ;SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX  96  
    ;...                                
    ;---------------------------    size 16 + 40*NumberOfHandles
    
    ;SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX struct
    ;---------------------------    offset dec (x64)
    ;PVOID Object;                  0
    ;ULONG_PTR UniqueProcessId;     8
    ;ULONG_PTR HandleValue;         16
    ;...
    ;---------------------------    size 40

    NumberOfHandles := NumGet(oBuffer, "UInt")
    BufFilePath := Buffer(1026)
    static StructSize := A_PtrSize*3 + 16 ;SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX
    static DUPLICATE_SAME_ACCESS := 0x2
    static FILE_TYPE_DISK := 1

    Loop NumberOfHandles
    {
        StructOffset := A_PtrSize*2 + StructSize*(A_Index - 1)
        UniqueProcessId := NumGet(oBuffer, StructOffset + A_PtrSize, "UInt")
        if (UniqueProcessId = PID)
        {
            HandleValue := NumGet(oBuffer, StructOffset + A_PtrSize*2, "Ptr")
            ;https://learn.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-duplicatehandle
            DllCall("DuplicateHandle" 
                , "Ptr" , hProcess
                , "Ptr" , HandleValue
                , "Ptr" , DllCall("GetCurrentProcess")
                , "PtrP", &lpTargetHandle := 0
                , "UInt", 0
                , "UInt", 0
                , "UInt", DUPLICATE_SAME_ACCESS)
            ;https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-getfiletype
            ;get filepath if FILE_TYPE_DISK (not type pipe, char, remote)
            if DllCall("GetFileType", "Ptr", lpTargetHandle) = FILE_TYPE_DISK
            && DllCall("GetFinalPathNameByHandle"
                , "Ptr" , lpTargetHandle
                , "Ptr" , BufFilePath
                , "UInt", 512
                , "UInt", 0)
            {
                FilePath := StrGet(BufFilePath) ;prefix "\\?\"
                FilesMap[A_Index] :=  RegExReplace(FilePath, "^\\\\\?\\")
            }
            DllCall("CloseHandle", "Ptr", lpTargetHandle)
        }
    }
    DllCall("CloseHandle", "Ptr", hProcess)
    return FilesMap
}