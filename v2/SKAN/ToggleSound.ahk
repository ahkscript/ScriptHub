; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=131731
; Author: SKAN

ToggleSound(ID1, ID2)                                      ;  MMDevice.ah2 v0.22 by SKAN for ah2 on D771/D77D @ autohotkey.com/r?t=131731
{
    ToggleSound.Mode        :=  SubStr(ID1, 1, 16) = "{0.0.0.00000000}" ? "Render" : "Capture"
    ToggleSound.DefaultID   :=  MMDevice_GetDefaultID( ToggleSound.Mode )
    ToggleSound.DefaultName :=  MMDevice_GetName( ToggleSound.DefaultID, True )

    ToggleSound.DeviceID    :=  ToggleSound.DefaultID = ID1 ? ID2 : ID1
    ToggleSound.DeviceName  :=  MMDevice_GetName(  ToggleSound.DeviceID, True )
    ToggleSound.State       :=  MMDevice_GetState( ToggleSound.DeviceID )

    Return ToggleSound.State = 1  ?  IPolicyConfig_SetDefaultEndpoint(ToggleSound.DeviceID)  :  0
} ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

; Dependencies  (All functions standalone!)
; -----------------------------------------

MMDevice_GetID(DeviceName, Mode := "Render")                                   ;  Mode: "Render" or "Capture"
{
    Mode := SubStr(Mode, 1, 1) = "R" ? "Render" : "Capture"

    Local  RegView    :=  SetRegView(64)
        ,  RegPath    :=  "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\" Mode
        ,  IDPrefix   :=  Mode="Render" ? "{0.0.0.00000000}." : "{0.0.1.00000000}."
        ,  DeviceID   :=  ""
        ,  Name1      :=  ""  ;  PKEY_Device_DeviceDesc
        ,  Name2      :=  ""  ;  PKEY_DeviceInterface_FriendlyName
        ,  Name3      :=  ""  ;  PKEY_Device_FriendlyName
        ,  Found      :=  0

    Loop   Reg, RegPath, "K"
    {
           DeviceID   :=  IDPrefix . A_LoopRegName
           Name1      :=  RegRead(RegPath "\" A_LoopRegName "\Properties", "{a45c254e-df1c-4efd-8020-67d146a850e0},2")
           Name2      :=  RegRead(RegPath "\" A_LoopRegName "\Properties", "{b3f8fa53-0004-438e-9003-51a46e139bfc},6")
           Name3      :=  Name1 " (" Name2 ")"
           If ( Found := DeviceName = Name3 Or DeviceName = Name1 )
                Break
    }

    SetRegView(RegView)
    Return Found ? DeviceID : ""
}


MMDevice_GetName(DeviceID, Full:=0)
{
    Local  RegView    :=  SetRegView(64)
        ,  Part       :=  StrSplit(DeviceID . "}.{" , "}.{", "{}")
        ,  Mode       :=  Part[1] = "0.0.0.00000000" ? "Render" : "Capture"
        ,  RegPath    :=  "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\" Mode "\{" Part[2] "}\Properties"
        ,  Name       :=  ""

    Try {
           Name       :=  RegRead(RegPath , "{a45c254e-df1c-4efd-8020-67d146a850e0},2")           ;  PKEY_Device_DeviceDesc
           If ( Full )
                Name  .=  " (" RegRead(RegPath , "{b3f8fa53-0004-438e-9003-51a46e139bfc},6") ")"  ;  PKEY_DeviceInterface_FriendlyName
        }

    SetRegView(RegView)
    Return Name
}


MMDevice_GetDefaultID(Mode := "Render", Role := 0)                             ;  Mode: "Render" or "Capture"
{                                                                              ;  Role: eConsole=0, eMultimedia=1, eCommunications=2
    Mode := SubStr(Mode, 1, 1) = "R" ? 0 : 1

    Local  CLSID_MMDeviceEnumerator :=   "{bcde0395-e52f-467c-8e3d-c4579291692e}"
        ,  IID_IMMDeviceEnumerator  :=   "{a95664d2-9614-4f35-a746-de8db63617e6}"
        ,  IMMDeviceEnumerator      :=   ComObject(CLSID_MMDeviceEnumerator, IID_IMMDeviceEnumerator)
        ,  GetDefaultAudioEndpoint  :=   4
        ,  IMMDevice                :=   0
        ,  pBuffer                  :=   0
        ,  GetId                    :=   5
        ,  DeviceID                 :=   ""

    Try    ComCall(GetDefaultAudioEndpoint, IMMDeviceEnumerator, "uint",Mode, "uint",Role, "ptrp",&IMMDevice)
    Catch
           Return ""

    ComCall(GetId, IMMDevice, "ptrp",&pBuffer)
    DeviceID  :=  StrGet(pBuffer, "utf-16")
    DllCall("Ole32\CoTaskMemFree", "ptr",pBuffer)
    ObjRelease(IMMDevice)

    Return DeviceID
}


MMDevice_GetState(DeviceID)                                                                                ;  Return values:
{                                                                                                          ;
    Local  CLSID_MMDeviceEnumerator :=   "{bcde0395-e52f-467c-8e3d-c4579291692e}"                          ;  DEVICE_STATE_ACTIVE     = 1
        ,  IID_IMMDeviceEnumerator  :=   "{a95664d2-9614-4f35-a746-de8db63617e6}"                          ;  DEVICE_STATE_DISABLED   = 2
        ,  IMMDeviceEnumerator      :=   ComObject(CLSID_MMDeviceEnumerator, IID_IMMDeviceEnumerator)      ;  DEVICE_STATE_NOTPRESENT = 4
        ,  GetDevice                :=   5                                                                 ;  DEVICE_STATE_UNPLUGGED  = 8
        ,  IMMDevice                :=   0
        ,  GetState                 :=   6
        ,  pdwState                 :=   0

    Try   ComCall(GetDevice, IMMDeviceEnumerator, "str",DeviceID, "ptrp",&IMMDevice)
    Catch
          Return 0

    ComCall(GetState, IMMDevice, "ptrp",&pdwState)
    ObjRelease(IMMDevice)
    Return pdwState
}


IPolicyConfig_SetDefaultEndpoint(DeviceID, Role := 0x1|0x2|0x4)                ;  Set a default sound device
{                                                                              ;  Credit: Flipeador @ autohotkey.com/r?p=387886
    Local  CLSID_IPolicyConfig      :=  "{870af99c-171d-4f9e-af0d-e63df40c2bc9}"
        ,  IID_IPolicyConfig        :=  "{f8679f50-850a-41cf-9c72-430f290290c8}"
        ,  IPolicyConfig            :=  ComObject(CLSID_IPolicyConfig, IID_IPolicyConfig)
        ,  SetDefaultEndpoint       :=  13

    If ( Role & 0x7 )
    Try {
            If ( Role & 0x1 )
                 ComCall(SetDefaultEndpoint, IPolicyConfig, "str",DeviceID, "uint",1)  ;  eMultimedia

            If ( Role & 0x2 )
                 ComCall(SetDefaultEndpoint, IPolicyConfig, "str",DeviceID, "uint",2)  ;  eCommunications (Default Communications Device)

            If ( Role & 0x4 )
                 ComCall(SetDefaultEndpoint, IPolicyConfig, "str",DeviceID, "uint",0)  ;  eConsole (Default Device)

            Return 1
        }

    Return 0
}


IPolicyConfig_SetEndpointVisibility(DeviceID, Visible := 0)                    ;  Disable / Enable a sound device |  Disable=0 / Enable=1
{                                                                              ;  Credit:  Capn Odin/qwerty12 @ autohotkey.com/r?p=102496
    Local  CLSID_IPolicyConfig      :=  "{870af99c-171d-4f9e-af0d-e63df40c2bc9}"
        ,  IID_IPolicyConfig        :=  "{f8679f50-850a-41cf-9c72-430f290290c8}"
        ,  IPolicyConfig            :=  ComObject(CLSID_IPolicyConfig, IID_IPolicyConfig)
        ,  SetEndpointVisibility    :=  14

    Try {
            ComCall(SetEndpointVisibility, IPolicyConfig, "str",DeviceID, "uint",!!Visible)
            Return 1
        }

    Return 0
}
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -