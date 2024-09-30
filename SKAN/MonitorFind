; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=133259
; Author: SKAN

MonitorFind(Query?, Field?)                ;   MonitorFind() v0.24  by SKAN for ah2 on D78U/D79P @ autohotkey.com/r?t=133259
{
    Local  QDC_ALL_PATHS           :=  0x00000001
        ,  QDC_DATABASE_CURRENT    :=  0x00000004
        ,  Topology                :=  { 1:"internal",  2:"clone",  4:"extend",  8:"external" }
        ,  nPath, nMode, nTopology :=  0
        ,  DISPLAYCONFIG_PATH_INFO_Array
        ,  DISPLAYCONFIG_MODE_INFO_Array

    DllCall("User32\GetDisplayConfigBufferSizes", "uint",QDC_DATABASE_CURRENT, "uintp",&nPath := 0, "uintp",&nMode := 0)

    DISPLAYCONFIG_PATH_INFO_Array  :=  Buffer(72 * nPath)   ; 72 = (20 + 48 + 4)
    DISPLAYCONFIG_MODE_INFO_Array  :=  Buffer(64 * nMode)

    DllCall( "User32\QueryDisplayConfig", "uint", QDC_DATABASE_CURRENT
                                        , "uintp",&nPath, "ptr",DISPLAYCONFIG_PATH_INFO_Array
                                        , "uintp",&nMode, "ptr",DISPLAYCONFIG_MODE_INFO_Array
                                        , "uintp",&nTopology )

    MonitorFind.Status :=  Topology.HasProp(nTopology) ? Topology.%nTopology% : "" ;  https://ss64.com/nt/displayswitch.html

    If ( IsSet(Query) and StrLen(Query) < 2 )
         Return (  MonitorFind.Count := 0,  StrLen(Query)=0 ? MonitorFind.Status : "" )

    DllCall("User32\GetDisplayConfigBufferSizes", "uint",QDC_ALL_PATHS, "uintp",&nPath := 0, "uintp",&nMode := 0)

    DISPLAYCONFIG_PATH_INFO_Array  :=  Buffer(72 * nPath)   ; 72 = (20 + 48 + 4)
    DISPLAYCONFIG_MODE_INFO_Array  :=  Buffer(64 * nMode)

    DllCall( "User32\QueryDisplayConfig", "uint", QDC_ALL_PATHS
                                        , "uintp",&nPath, "ptr",DISPLAYCONFIG_PATH_INFO_Array
                                        , "uintp",&nMode, "ptr",DISPLAYCONFIG_MODE_INFO_Array
                                        , "ptr",0 )

    Local  List :=  "`n`n"
        ,  DeviceName,   DevicePath,   AdpID,   TrgID,   SrcID,   DoneID :=  Map(),  Off  := -72
        ,  DISPLAYCONFIG_SOURCE_DEVICE_NAME  :=  Buffer( 84, 0)
        ,  DISPLAYCONFIG_TARGET_DEVICE_NAME  :=  Buffer(420, 0)

    DoneID.Default  :=  0

    Loop ( nPath )
    {
        If  ( NumGet(DISPLAYCONFIG_PATH_INFO_Array, (Off += 72) + 60, "uint") = 0 )   ;  Checking if targetAvailable = false
              Continue

        AdpID   :=   NumGet(DISPLAYCONFIG_PATH_INFO_Array, Off +  0, "int64")
        SrcID   :=   NumGet(DISPLAYCONFIG_PATH_INFO_Array, Off +  8,  "uint")
        TrgID   :=   NumGet(DISPLAYCONFIG_PATH_INFO_Array, Off + 28,  "uint")

        If  ( DoneID[TrgID & 0xFFFF] )
              Continue
        Else  DoneID[TrgID & 0xFFFF] := 1

        NumPut("int",       1,  DISPLAYCONFIG_SOURCE_DEVICE_NAME,  0)     ;  DISPLAYCONFIG_DEVICE_INFO_GET_SOURCE_NAME =   1
        NumPut("int",      84,  DISPLAYCONFIG_SOURCE_DEVICE_NAME,  4)     ;  DISPLAYCONFIG_SOURCE_DEVICE_NAME.Size     =  84
        NumPut("int64", AdpID,  DISPLAYCONFIG_SOURCE_DEVICE_NAME,  8)
        NumPut("uint",  SrcID,  DISPLAYCONFIG_SOURCE_DEVICE_NAME, 16)

        DllCall("User32\DisplayConfigGetDeviceInfo", "ptr",DISPLAYCONFIG_SOURCE_DEVICE_NAME)
        DeviceName  :=  StrGet(DISPLAYCONFIG_SOURCE_DEVICE_NAME.Ptr + 20)

        NumPut("int",       2,  DISPLAYCONFIG_TARGET_DEVICE_NAME,  0)     ;  DISPLAYCONFIG_DEVICE_INFO_GET_TARGET_NAME =   2
        NumPut("int",     420,  DISPLAYCONFIG_TARGET_DEVICE_NAME,  4)     ;  DISPLAYCONFIG_TARGET_DEVICE_NAME.Size     = 420
        NumPut("int64", AdpID,  DISPLAYCONFIG_TARGET_DEVICE_NAME,  8)
        NumPut("uint",  TrgID,  DISPLAYCONFIG_TARGET_DEVICE_NAME, 16)

        DllCall("User32\DisplayConfigGetDeviceInfo", "ptr",DISPLAYCONFIG_TARGET_DEVICE_NAME)
        DevicePath  :=  StrGet(DISPLAYCONFIG_TARGET_DEVICE_NAME.Ptr + 164)

        If ( TrgID > 0xFFFF )
             List := StrReplace(List, DeviceName)

        If ( InStr(List, DeviceName) )
             DeviceName  :=  ""

        List  .=  ParseEDID(DevicePath, TrgID & 0xFFFF, DeviceName) "`n`n"
    }

    MonitorFind.Count := DoneID.Count

    For TrgID in DoneID
        List := StrReplace(List, "8) " TrgID "`n", "8) " A_Index "`n")

    Loop ( MonitorGetCount() )
           DeviceName  :=  MonitorGetName(A_Index)
         , List  :=  StrReplace(List, "5) `n6) " DeviceName, "5) " A_Index "`n6) " DeviceName)

    If ( IsSet(Query) = 0 )
         Return Trim(List, "`n")

    Local  sPos, ePos, Str

    If (  sPos  :=  InStr(List, StrReplace(Query, "`n"), True)  )
          sPos  :=  InStr(List, "`n`n",, sPos, -1) + 2
      ,   ePos  :=  InStr(List, "`n`n",, sPos)
      ,   Str   :=  SubStr(List, sPos, ePos-sPos)
    Else  Return

    Return (  IsSet(Field) = 0  or IsInteger(Field) = 0 or Field > 8 or Field < 1
              ?    Str
              :  ( Str := StrSplit(Str, "`n")[Field]
                 , SubStr(Str, 4) )  )

                    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    ParseEDID(Hex, UniqID := 0, DeviceName := "")
                    {
                        If ( StrLen(Hex) < 256 )
                             Hex  :=  StrSplit(Hex, "#")
                           , Hex  :=  RegRead( "HKLM\SYSTEM\CurrentControlSet\Enum\DISPLAY\"
                                             .  Hex[2] "\" Hex[3] "\Device Parameters", "EDID", "" )

                                        HexToBuf_128(&Hex)
                                        {
                                            Local Buf := Buffer(128, 0)

                                            Loop (  Min(128, StrLen(Hex)//2)  )
                                                    NumPut("char", "0x" . SubStr(Hex, 2*A_Index-1, 2), Buf, A_Index-1)

                                            Return Buf
                                        }

                        EDID :=  HexToBuf_128(&Hex)
                        Manf :=  NumGet(EDID, 8, "ushort")
                        Manf :=  (Manf >> 8) | ((Manf & 0xFF) << 8) ;  convert Manf to BigEndian word

                                        UEFI_PNPID(BigE_word)       ;  https://uefi.org/PNP_ID_List
                                        {
                                            Local  Chars := "0ABCDEFGHIJKLMNOPQRSTUVWXYZ?????"

                                            Return (  SubStr(Chars, (BigE_word >> 10 & 31) + 1, 1)
                                                   .  SubStr(Chars, (BigE_word >> 5  & 31) + 1, 1)
                                                   .  SubStr(Chars, (BigE_word       & 31) + 1, 1)  )
                                        }

                        Local  Manf    :=  UEFI_PNPID(Manf)
                            ,  Prod    :=  NumGet(EDID, 10, "ushort")
                            ,  Serial  :=  NumGet(EDID, 12, "uint")

                        Local  EDID,  Make := "",  Desc := "",  Snid := ""
                        EDID.Ptr2  :=  EDID.Ptr + 54                ;    54 is starting offset of detailed timing descriptor
                                                                    ;  and 72, 90 and 108 are offsets to display descriptors
                        Loop ( 3 )
                               Switch ( NumGet(EDID.Ptr2 += 18, "int64") & 0xFFFFFFFFFF )  ; Read int64 and convert to int40
                               {
                                        Case 0x00FC000000:  Make :=  StrGet(EDID.Ptr2 + 5, 13, "cp437")
                                                         ,  Make :=  RTrim(Make, "`n`s")

                                        Case 0x00FE000000:  Desc :=  StrGet(EDID.Ptr2 + 5, 13, "cp437")
                                                         ,  Desc :=  RTrim(Desc, "`n`s")

                                        Case 0x00FF000000:  Snid :=  StrGet(EDID.Ptr2 + 5, 13, "cp437")
                                                         ,  Snid :=  RTrim(Snid, "`n`s")
                               }

                         Return Format( "1) {1:}`n2) {2:}`n3) {3:}`n"
                                      . "4) {4:}{5:04X}_{6:08X}`n"
                                      . "5) `n6) {7:}`n7) UID{8:}`n8) {8:}"
                                      , Make, Snid, Desc, Manf, Prod, Serial, DeviceName, UniqID )
                    }
} ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

/*

  DISPLAYCONFIG_PATH_INFO                                                                  ;  http://tiny.cc/displayconfig_1
  =======================
   0   20  DISPLAYCONFIG_PATH_SOURCE_INFO *                                                ;  http://tiny.cc/displayconfig_2
  20   48  DISPLAYCONFIG_PATH_TARGET_INFO **                                               ;  http://tiny.cc/displayconfig_3
  68    4  UINT32                                  flags;

  DISPLAYCONFIG_PATH_SOURCE_INFO *                                                         ;  http://tiny.cc/displayconfig_2
  --------------------------------
   0    8  LUID                                    adapterId;
   8    4  UINT32                                  id;
  12    4  UINT32                                  modeInfoIdx
  16    4  UINT32                                  statusFlags;

  DISPLAYCONFIG_PATH_TARGET_INFO **                                                        ;  http://tiny.cc/displayconfig_3
  ---------------------------------
  28    4? LUID                                    adapterId;
  32?   4  UINT32                                  id;
  36    4  DISPLAYCONFIG_VIDEO_OUTPUT_TECHNOLOGY   outputTechnology;
  40    4  DISPLAYCONFIG_ROTATION                  rotation;
  44    4  DISPLAYCONFIG_SCALING                   scaling;
  48    8  DISPLAYCONFIG_RATIONAL                  refreshRate;
  56    4  DISPLAYCONFIG_SCANLINE_ORDERING         scanLineOrdering;
  60    4  BOOL                                    targetAvailable;
  64    4  UINT32                                  statusFlags;

____________________________________________________________________________________________________________________________

  DISPLAYCONFIG_TARGET_DEVICE_NAME                                                         ;  http://tiny.cc/displayconfig_4
  ================================
   0   20  DISPLAYCONFIG_DEVICE_INFO_HEADER *      header;                                 ;  http://tiny.cc/displayconfig_5
  20    4  DISPLAYCONFIG_TARGET_DEVICE_NAME_FLAGS  flags;
  24    4  DISPLAYCONFIG_VIDEO_OUTPUT_TECHNOLOGY   outputTechnology;
  28    2  UINT16                                  edidManufactureId;
  30    3  UINT16                                  edidProductCodeId;
  32    4  UINT32                                  connectorInstance;
  36  128  WCHAR                                   monitorFriendlyDeviceName[64];
 164  256  WCHAR                                   monitorDevicePath[128];

  DISPLAYCONFIG_SOURCE_DEVICE_NAME                                                         ;  http://tiny.cc/displayconfig_6
  ================================
   0   20  DISPLAYCONFIG_DEVICE_INFO_HEADER *      header;                                 ;  http://tiny.cc/displayconfig_5
  20   64  WCHAR                                   viewGdiDeviceName[CCHDEVICENAME];

  DISPLAYCONFIG_DEVICE_INFO_HEADER *                                                       ;  http://tiny.cc/displayconfig_5
  ----------------------------------
   0    4  DISPLAYCONFIG_DEVICE_INFO_TYPE          type;
   4    4  UINT32                                  size;
   8    8  LUID                                    adapterId;
  16    4  UINT32                                  id;

*/