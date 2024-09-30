; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=132507
; Author: SKAN

MapFile(FileObj, Open:=True)  ; MapFile() v0.45 by SKAN on D459/D78G @ autohotkey.com/r?p=581962
{
    If ( Type(FileObj) != "File" )
         Return ( MapFile.Status       :=  "Invalid file object.",  0 )

    If ( FileObj.Handle = -1 )
         Return ( MapFile.Status       :=  "Invalid file handle.",  0 )

    If ( FileObj.Length < 1   Or FileObj.Length > 512 * 1024 * 1024 ) ; Filesize limit 512 MB
         Return ( MapFile.Status       :=  "Invalid file size.`tBytes: " FileObj.Length,  0 )

    If ( Open = False )

         If ( FileObj.HasProp("MapFile") )
              Return (  DllCall("Kernel32\UnmapViewOfFile", "ptr",FileObj.DeleteProp("Ptr"))
                     ,  DllCall("Kernel32\CloseHandle", "ptr",FileObj.DeleteProp("MapFile"))
                     ,  FileObj.DeleteProp("Size")
                     ,  MapFile.Status := "MapView closed."
                     ,  0 )
         Else Return ( MapFile.Status  := "File object doesn't have MapView.",  0 )

    Else If ( FileObj.HasProp("Ptr") )
              Return (  MapFile.Status := "File memory pointer: " FileObj.Ptr
                     ,  FileObj.Ptr )

    Local  IoStatusBlock               :=  Buffer(A_PtrSize * 2, 0)
        ,  ACCESS_MASK                 :=  0
        ,  FileAccessInformation       :=  8

    DllCall("Ntdll\NtQueryInformationFile", "ptr",FileObj.Handle, "ptr",IoStatusBlock
                                          , "intp",&ACCESS_MASK, "int",4
                                          , "int",FileAccessInformation)

    Local  READ_ACCESS                 :=  (ACCESS_MASK)      & 1
        ,  WRITE_ACCESS                :=  (ACCESS_MASK >> 1) & 1

    If ( READ_ACCESS = 0 )
         Return ( MapFile.Status       :=  "File object doesn't have read access.",  0 )

    Local  PAGE_READWRITE              :=  0x4
        ,  PAGE_READONLY               :=  0x2

    FileObj.MapFile  :=   DllCall("Kernel32\CreateFileMapping", "ptr",FileObj.Handle, "ptr",0
                                , "int",WRITE_ACCESS ? PAGE_READWRITE : PAGE_READONLY
                                , "int",0, "int",0, "ptr",0, "ptr")

    If ( FileObj.MapFile = 0 )
         Return (  MapFile.Status      :=  "CreateFileMapping failed!.`tLastError: " A_LastError
                ,  FileObj.DeleteProp("MapFile")
                ,  0 )

    Local  FILE_MAP_ALL_ACCESS         :=  0x000F001F
        ,  FILE_MAP_READ               :=  0x00000004

    FileObj.Ptr  :=  DllCall("Kernel32\MapViewOfFile", "ptr",FileObj.MapFile
                           , "int",WRITE_ACCESS ? FILE_MAP_ALL_ACCESS : FILE_MAP_READ
                           , "int",0, "int",0, "ptr",0, "ptr")
    If ( FileObj.Ptr = 0 )
         Return (  MapFile.Status      :=  "MapViewOfFile failed!.`tLastError: " A_LastError
                ,  FileObj.DeleteProp("Ptr")
                ,  DllCall("Kernel32\CloseHandle", "ptr",FileObj.DeleteProp("MapFile"))
                ,  0 )

    Return (  FileObj.Size   :=  FileObj.Length
           ,  MapFile.Status :=  "File memory pointer: " FileObj.Ptr
           ,  FileObj.Ptr )
}