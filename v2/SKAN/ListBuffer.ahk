; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=101121
; Author: SKAN

ListBuffer(Bin, Title := "", AlwaysOnTop := 0, *)         ;   v0.63 by SKAN for ah2 on D52L/D78R @ autohotkey.com/r?t=101121
{
    Bin := Type(Bin) = "VarRef" ? %Bin% : Bin

    If  ( IsObject(Bin) = 0  or  HasProp(Bin, "Ptr") = 0  or  HasProp(Bin, "Size") = 0 )
    and ( MsgBox("Not a Buffer-like Object", "ListBuffer", "T3 Icon? 0x1000") )
          Return ( ListBuffer.Pos := 0 )

                    QPC(R := 0)                           ;  By SKAN  for ah2 on CT91/D497 @ autohotkey.com/r?p=419443
                    {
                        Static   P := 0,  F := 0, Q := DllCall("Kernel32\QueryPerformanceFrequency", "int64p",&F)
                        Return ( DllCall("Kernel32\QueryPerformanceCounter","int64p",&Q) * 0 + (R ? (P:=Q)*0 : (Q-P)/F) )
                    }

    Local  TickCount      :=  QPC(1)
        ,  RetVal         :=  0                           ;  The return value of this function
        ,  Loading        :=  True                        ;  Disallow GuiClose() until GUI fully loaded
        ,  ReverseSearch  :=  0                           ;  Default Checkbox value
        ,  BigE           :=  0                           ;  Default Checkbox value (BigEndian)
        ,  LoadDelay      :=  Bin.HasProp("LoadDelay") and Bin.LoadDelay

    If (  Bin.HasProp("Reverse") and Bin.Reverse  )
          ReverseSearch   :=  1

    If (  Bin.HasProp("BigEndian") and Bin.BigEndian  )
          BigE            :=  1

    If (  Bin.HasProp("Title") and StrLen(Bin.Title)  )
          Title           :=  Bin.Title

   Local   hMod1          :=  DllCall("Kernel32\LoadLibrary", "str","RichEd20.dll", "ptr")
        ,  hMod2          :=  DllCall("Kernel32\LoadLibrary", "str","Crypt32.dll",  "ptr")

        ,  HexL           :=  Bin.Size * 3                ;  Hex buffer len at 3x size of original
        ,  Hex                                            ;  Hex buffer
        ,  CRLF           :=  "`r`n"
        ,  LF             :=  "`n"

    Local  MyGui
        ,  ChkB1,  ChkB2                                  ;  Reverse, BigEndian
        ,  Text1,  Text2,  Text3,  Text4,  TextB          ;  Offset, Search, Values, Hex data, BinText
        ,  Text5,  Text6,  TextL                          ;  Pointer (Type/Pointer), Text (of BinText), LoadDelay
        ,  Edit1,  Edit2,  Edit3                          ;  Offset, Search, Values
        ,  UpDn1                                          ;  Attached to Offset
        ,  Rich1                                          ;  Hex data
        ,  MySB                                           ;  StatusBar
        ,  SB_Text        :=  ""                          ;  StatusBar text

    AlwaysOnTop := AlwaysOnTop ? " +AlwaysOnTop" : ""

    MyGui   :=   Gui("+DpiScale " AlwaysOnTop, "ListBuffer" (Strlen(Title) ? " - " : "") Title)
  ,              MyGui.MarginX  :=  20
  ,              MyGui.MarginY  :=  16

                    GetSysColor(n)
                    {
                        Return  Format( "{5:}{6:}{3:}{4:}{1:}{2:}"
                                      , StrSplit( Format("{:06X}", DllCall("User32\GetSysColor", "int",n)) )*
                                      )
                    }

    ;  Edit3 (Values Edit Control) will be flagged 'Readonly' and loses its default color.
    ;  So, find/apply default foreground/background color. (COLOR_WINDOWTEXT := 8, COLOR_WINDOW := 5)

    Local  ColorOption :=  "c" GetSysColor(8) " Background" GetSysColor(5)
        ,  Bytes       :=  0
        ,  X, Y, W, H                                     ;  W = Width of Edit3 (Values Edit Control)

                 MyGui.SetFont("s11", "Courier New")
  , Edit3   :=   MyGui.AddEdit("xm ym R5 +ReadOnly -Tabstop " ColorOption, Format("{:48}",""))         ; Values Edit Control
  ,              Edit3.GetPos(,,&W)                       ;  To apply same width (48 characters) to RichEdit control
  ,              Edit3.Text := ""

  ,              MyGui.SetFont("s10", "Segoe UI")
  , Text1   :=   MyGui.AddText("xm y8 0x100 w124", "Offset")                               ;  SS_NOTIFY := 0x100

  , Text2   :=   MyGui.AddText("x160 yp w80 0x100", "Search")                              ;  SS_NOTIFY := 0x100
  ,              Text2.OnEvent("Click", (*) => TrySearch())

  , ChkB1   :=   MyGui.AddCheckbox("x240 yp -Tabstop Right w" w-240+MyGui.MarginX " Checked" ReverseSearch, "Reverse")
  ,              ChkB1.OnEvent("Click", (*) => (ReverseSearch := ChkB1.Value))

                    SelectOffset(*)  ;     Called when Edit1 (Offset) changes with Mouse wheel / Up Down
                    {                ;     arrow keys. Selects appropriate Hex, 3 times value of Offset.
                        PostMessage(0xB1, UpDn1.Value*3, UpDn1.Value*3+2, Rich1)           ;  EM_SETSEL
                    }

                    SelectOffsetEnable(Enable := True)
                    {
                        Edit1.OnEvent("Change", SelectOffset, Enable)
                    }

                 MyGui.SetFont("s11", "Consolas")
  , Edit1   :=   MyGui.AddEdit("xm y+4 w124 Number Right", 0)        ;  Offset Edit Control
  ,              SelectOffsetEnable(True)

  , UpDn1   :=   MyGui.AddUpDown("Left Wrap 0x80 Range" (Bin.Size>0 ? Bin.Size-1 : 0) "-0", 1)

                    SelectOffset0(Len)                            ; for Edit2
                    {
                        If ( UpDn1.Value = 0 or UpDn1.Value = Bin.Size-1 )
                             RichSelectChars(Len ? 0 : 1)
                    }

    Edit2   :=   MyGui.AddEdit("x160 yp vSearch w" w-160+MyGui.MarginX)                               ;  Search Edit Control
  ,              Edit2.OnEvent("Change", (*) => SelectOffset0( StrLen(Edit2.Text) ))

  ,              MyGui.SetFont("s10", "Segoe UI")
  , Text4   :=   MyGui.AddText("xm y+12 0x100 w256", "Hex data of " Bin.Size " bytes")       ;  SS_NOTIFY := 0x100
  , Text5   :=   MyGui.AddText("x280 yp 0x100 Right w" w-280+MyGui.MarginX, (A_PtrSize=8 ? "x64" : "x86") " @ " Bin.Ptr)

    Local  Needle        :=  Buffer(0)                                         ;  Common buffer for TrySearch() and Search()
        ,  CHARRANGE     :=  Buffer(8)                                                       ;  for TrySearch()
        ,  Selection     :=  0                                                               ;  for GetSelChars()
        ,  SelBytes      :=  1                                                               ;  for EN_SELCHANGE()
        ,  pCHARRANGE                                                                        ;  for EN_SELCHANGE()
        ,  Rich1_Min     :=  0                                                               ;  for EN_SELCHANGE()
        ,  Rich1_Max     :=  0                                                               ;  for EN_SELCHANGE()
        ,  Rich1_Options :=  ( 0x200000    ;  WS_VSCROLL
                             | 0x000100    ;  ES_NOHIDESEL
                             | 0x000800    ;  ES_READONLY
                             | 0x008000 )  ;  ES_SAVESEL
                          .  " E0x20000 "  ;  WS_EX_STATICEDGE

  , TextL   :=   MyGui.AddText("xm y+4 h24 E0x20000 0x201 w" W)
                 MyGui.SetFont("s11", "Courier New")
  , Rich1   :=   MyGui.AddCustom("ClassRichEdit20A xp yp  R8  w" W " " Rich1_Options)        ;  Same width as Edit3 (Values)
  ,              Rich1.GetPos(,,&W, &H)
  ,              TextL.Move(,, W, H)
  ,              DllCall("User32\ShowScrollBar", "ptr",Rich1.Hwnd, "int",1, "int",True)      ;  SB_VERT := 1

                    RichEdit_SetPropertyBits(Ctrl)   ;               How to eliminate MessageBeep from the RICHEDIT control?
                    {                                ;                                            autohotkey.com/r/?t=091105

                        Local  OnTxPropertyBitsChange  :=  19               ; <= Thanks swagfag @ autohotkey.com/r/?p=402594
                            ,  Unknown
                            ,  pUnknown
                            ,  TxtSrv
                            ,  IID_ITextServices       :=  "{8D33F740-CF58-11CE-A89D-00AA006CADC5}"

                        SendMessage(0x43C, 0, Unknown  :=  Buffer(8), Ctrl)                 ;  EM_GETOLEINTERFACE := 0x43C
                   ,    pUnknown  :=  NumGet(Unknown, "ptr")
                   ,    TxtSrv    :=  ComObjQuery(pUnknown, IID_ITextServices)
                   ,    ObjRelease(pUnknown)

                        If ( A_Ptrsize = 8 )                                                ; tiny.cc/OnTxPropertyBitsChange
                            Return ComCall(OnTxPropertyBitsChange, TxtSrv, "int",0x802, "int",0x2)

                                                                            ;    Thanks lexikos @ autohotkey.com/r/?p=402798
                        Local  vtbl                    :=  NumGet(TxtSrv.Ptr, "ptr")
                            ,  pOnTxPropertyBitsChange :=  NumGet(vtbl + (19 * A_PtrSize), "ptr")

                        Static thiscall_thunk
                        If ( IsSet(thiscall_thunk) = 0 )
                        {
                            thiscall_thunk  :=  Buffer(8)
                        ,   NumPut("int64", 0xE2FF50595A58, thiscall_thunk)
                        ,   DllCall("Kernel32\VirtualProtect", "ptr",thiscall_thunk, "ptr",8, "int",0x40, "intp",0)
                        }

                        DllCall(thiscall_thunk, "ptr",pOnTxPropertyBitsChange, "ptr",TxtSrv, "int",0x802, "int",0x2)
                    }

                 RichEdit_SetPropertyBits(Rich1)

                 MyGui.SetFont("s10", "Segoe UI")
  , Text6   :=   MyGui.AddText("xm y+12 0x100", "Text")                                    ;  SS_NOTIFY := 0x100
  ,              MyGui.SetFont("s11", "Courier New")
  ,              MyGui.AddText("r5 y+4 Center E0x20000 w" W)
  , TextB   :=   MyGui.AddText("xp+16 yp+8 r4 w" W-20)                                     ;  Display Bin converted to Text

    Local  EditMargins  :=  Format("0x{1:04X}{1:04X}", 8*(A_ScreenDPI/96))

                 PostMessage(0xD3, 0x3, EditMargins, Edit1)                                ;  EM_SETMARGINS := 0xD3
  ,              PostMessage(0xD3, 0x3, EditMargins, Edit2)                                ;  ( EC_LEFTMARGIN
  ,              PostMessage(0xD3, 0x3, EditMargins, Edit3)                                ;    | EC_RIGHTMARGIN ) := 0x3
  ,              PostMessage(0xD3, 0x3, EditMargins, Rich1)

  ,              MyGui.SetFont("s10", "Segoe UI")
  , Text3   :=   MyGui.AddText("xm y+20 0x100 w240", "Unsigned/signed values")             ;  SS_NOTIFY := 0x100
  , ChkB2   :=   MyGui.AddCheckbox("x280 yp hp -Tabstop Right w" w-280+MyGui.MarginX " Checked" BigE,"Convert to BigEndian")

                    ToggleEndian(*)                       ;  Toggles value between Little Endian and Big Endian
                    {
                        BigE   :=  ChkB2.Value
                        NumValues(Bin, UpDn1.Value, Bytes)                         ;  Update Values
                    }

                 ChkB2.OnEvent("Click", ToggleEndian)

    MyGui.AddText("xm y+4 w0 h0").GetPos(&X, &Y)          ;  Dummy text control for place allocation
  , Edit3.Move(X, Y)                                      ;  Move Edit3 (Values Edit Control) to allocated place

  , X       :=   MyGui.MarginX
  , MySB    :=   MyGui.AddStatusBar()
  ,              MySB.SetParts(X, W, X)                   ;  Set active status bar centered to Edit3 (Value Edit Control)

    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    Local  FileMenu    :=  Menu()                         ;           ----------------   Gui MenuBar for Accelerators ------
        ,  FocusMenu   :=  Menu()
        ,  HexMenu     :=  Menu()
        ,  ToggleMenu  :=  Menu()
        ,  SearchFill  :=  Menu()
        ,  IntMenu     :=  Menu()
        ,  HexInt      :=  Menu()
        ,  Unsigned    :=  Menu()
        ,  Signed      :=  Menu()
        ,  Menus       :=  MenuBar()

                    OpenTextInNotepad(Filename)
                    {
                        TickCount   :=  QPC(1)
                        Local  Text :=  BinToTxt(Bin.Ptr, Bin.Size)
                        TickCount   :=  QPC(0)

                        Try    FileDelete(Filename)
                        Try    FileAppend(Text, Filename, "RAW")
                          ,    MySB_Tip("Text conversion in " Round(TickCount*1000, 1) "ms.  Opening text in Notepad", 5000)
                          ,    Run('Notepad.exe /A "' Filename '"',, "Max")
                        Catch
                               MySB_Tip("[File creation/open failed] : " Filename, 5000)
                    }

    FileMenu.Add("Open text in &Notepad    " A_Tab "Alt+N",      (*) => OpenTextInNotepad(A_Temp "\ListBuffer.txt"))
  , FileMenu.Add("Always on &Top           " A_Tab "Alt+T",      (*) => WinSetAlwaysOnTop(-1, MyGui.Hwnd))
  , FileMenu.Add("Search                   " A_Tab "Enter",      (*) => TrySearch())
  , FileMenu.Add()
  , FileMenu.Add("Return -2                " A_Tab "Alt+Home",   (*) => (RetVal := -2,  GuiClose()))
  , FileMenu.Add("Return -1                " A_Tab "Alt+PgUp",   (*) => (RetVal := -1,  GuiClose()))
  , FileMenu.Add("Return  0                " A_Tab "Alt+Escape", (*) => (RetVal :=  0,  GuiClose()))
  , FileMenu.Add("Return  1                " A_Tab "Alt+Enter",  (*) => (RetVal :=  1,  GuiClose()))
  , FileMenu.Add("Return  2                " A_Tab "Alt+PgDn",   (*) => (RetVal :=  2,  GuiClose()))
  , FileMenu.Add("Return  3                " A_Tab "Alt+End",    (*) => (RetVal :=  3,  GuiClose()))
  , FileMenu.Add()
  , FileMenu.Add("E&xit                    " A_Tab "Alt+X",      (*) => ExitApp())

  , FocusMenu.Add("&Offset" A_Tab "Ctrl+O",(*) => Edit1.Focus())
  , FocusMenu.Add("&Search" A_Tab "Ctrl+S",(*) => Edit2.Focus())
  , FocusMenu.Add("&Hex   " A_Tab "Ctrl+H",(*) => Rich1.Focus())
  , FocusMenu.Add("Val&ues" A_Tab "Ctrl+U",(*) => Edit3.Focus())

  , ToggleMenu.Add("&Reverse search      " A_Tab "Ctrl+R", (*) => (ChkB1.Value:=!ChkB1.Value, ReverseSearch := ChkB1.Value))
  , ToggleMenu.Add("Convert to &BigEndian" A_Tab "Ctrl+B", (*) => (ChkB2.Value:=!ChkB2.Value, ToggleEndian()))

                    SearchItemFill(ItemName, ItemPos, MyMenu)
                    { ; Uncommon Menu ItemName like Int32, Int24 etc., will be translated by Search()
                        Local Len  :=  StrLen(ItemName) + 1
                        Edit2.Text :=  ItemName ":<value>"
                        Edit2.Focus()
                        SendMessage(0xB1, Len, Len+8, Edit2)                                     ;  EM_SETSEL := 0xB1
                    }

   Loop Parse "hex||char|short"
             . "||int8|int16|int24|int32|int40|int48|int56|int64"
             . "||float|double"
             . "||cp0|utf-8|utf-16|cp936"
             . "||1|2|3|4|5|6|7|8"
             , "|"
          If ( A_LoopField )
               SearchFill.Add( A_LoopField, SearchItemFill)
        Else   SearchFill.Add()

                    RichSelectChars(Bytes := 1, Post := False)
                    {
                          Local  bChar :=  UpDn1.Value * 3
                              ,  eChar :=  bChar + (Bytes * 3) - 1

                          If ( Post)
                               PostMessage(0xB1, bChar, Bytes=0 ? bChar : eChar, Rich1)         ;  EM_SETSEL := 0xB1
                             , Sleep(1)

                          Else SendMessage(0xB1, bChar, Bytes=0 ? bChar : eChar, Rich1)         ;  EM_SETSEL := 0xB1
                    }


                    GetSelChars(Ctrl)
                    {
                        NumPut("int64", 0, CHARRANGE)

                        If  ( Ctrl.Type = "Custom" )
                              SendMessage(0x434, 0, CHARRANGE, Ctrl)                  ;  EM_EXGETSEL := 0x434
                        Else  SendMessage(0xB0, CHARRANGE.Ptr, CHARRANGE.Ptr+4, Ctrl) ;  EM_GETSEL   := 0xB0

                        Selection := NumGet(CHARRANGE, 4, "uint") - NumGet(CHARRANGE, 0, "uint")
                        Return Selection
                    }


                    CopyToClipboard(Ctrl)
                    {
                        If ( Bin.Size < 1 or GetSelChars(Ctrl) < 1 )
                             Return MySB_Tip("", 0)

                        SendMessage(0x301, 0,0, Ctrl)                                 ;  WM_COPY     := 0x301

                        Local  Length := StrLen(A_Clipboard)
                        MySB_Tip("[Copied " Length " chars] : " SubStr(A_Clipboard, 1,47), 0)
                    }


                    CopyAsBase64()
                    {
                        Local  Offset  :=  UpDn1.Value
                            ,  Base64  :=  ""
                            ,  Reqd    :=  0

                        DllCall("Crypt32\CryptBinaryToString"
                              , "ptr",Bin.Ptr+Offset, "int",SelBytes, "int",0x40000001, "ptr",0, "intp",&Reqd)

                        VarSetStrCapacity(&Base64, Reqd)

                        DllCall("Crypt32\CryptBinaryToString"
                              , "ptr",Bin.Ptr+Offset, "int",SelBytes, "int",0x40000001, "str",Base64, "intp",&Reqd)

                        A_Clipboard  :=  Base64

                        If ( Reqd )
                             MySB_Tip("[Copied " SelBytes " bytes] : " SubStr(Base64, 1,47), 0)
                    }


                    CopyGUID()
                    {
                        If ( SelBytes > 1 )
                             RichSelectChars(0, True)

                        If ( Bin.Size-UpDn1.Value < 16 )
                             Return Bin.Size ? MySB_Tip("[Copy failed] : GUID requires 16 bytes", 5000) : ""

                                        StrFmGuid(Ptr)                                 ; By SKAN @ autohotkey.com/r?p=581620
                                        {
                                            Local  GUID := "{"
                                            Ptr := Type(Ptr) = "Buffer" ? Ptr.Ptr : Ptr

                                            Loop Parse, "3210-54-76-89-ABCDEF"
                                                 GUID .=  A_LoopField != "-"
                                                       ?  Format("{:02x}", NumGet(Ptr, "0x" A_LoopField, "uchar"))
                                                       :  "-"
                                            Return GUID  . "}"
                                        }

                        RichSelectChars(16, True)
                        A_Clipboard  := StrFmGuid(Bin.Ptr + UpDn1.Value)
                        MySB_Tip("[Copied GUID] : " A_Clipboard, 0)
                    }


                    CopyText(Encoding)
                    {
                        If ( Bin.Size < 1 )
                             Return

                        If ( SelBytes > 1 )
                             RichSelectChars(0, True)

                        If ( ! SubStr(Edit3.Text, 16, 2) )
                               Return MySB_Tip("[Copy failed] : Begin byte cannot be null", 5000)

                        Local  Offset  :=  Edit1.Value
                            ,  EncSz   :=  (Encoding="UTF-16" ? 2 : 1)
                            ,  Length  :=  (Bin.Size - Offset) // EncSz

                        A_Clipboard  :=  StrGet(Bin.Ptr+Offset, Length, Encoding)

                        Length       :=  (StrPut(A_Clipboard, Encoding) - EncSz)
                        RichSelectChars(Length, True)

                        MySB_Tip("[Copied " Length // EncSz " chars] : " SubStr(A_Clipboard, 1,47), 0)
                    }


                    CopyInteger(ItemName, Bytes, MyMenu)
                    {
                        Rich1.OnNotify(0x700, EN_MSGFILTER, 0)                       ;  Monitor number key press in Hex data

                        If ( Bytes > (Bin.Size-UpDn1.Value) )
                             Return

                        RichSelectChars(Bytes, True)

                        Local  Buf     :=  Buffer(8, 0)
                            ,  Val     :=  0
                            ,  Ptr     :=  Bin.Ptr + UpDn1.Value
                            ,  IntType :=  InStr(ItemName,"Alt+",   True, -1) ? "Unsigned"
                                       :   InStr(ItemName,"Shift+", True, -1) ? "Signed"
                                                                              : "Hex"
                        Loop ( Bytes ) ;   instead of RtlMoveMemory()
                               Val := BigE ? NumGet(Ptr, Bytes - A_Index, "char")
                                           : NumGet(Ptr, A_Index - 1, "char")
                             , NumPut("char", Val, Buf, A_Index-1)

                        Val  :=  NumGet(Buf, "int64")

                                        Signed(Val := 0, Bits := 32)   ; By SKAN for ah2 on D65F @ autohotkey.com/r?p=521661
                                        {
                                            Bits //= 4
                                            Local  Len  :=  Bits<2 ? 2 : Bits>15 ? 15 : Bits
                                                ,  Hex  :=  Format("{:016X}", Val)
                                                ,  Det  :=  Format("0x8{:0" Len-1 "}", "")
                                                   Val  :=  ("0x" SubStr(Hex,-Len)) + 0
                                            Return Val<Det ? Val : (Val & (Det-1)) - Det
                                        }

                        If ( IntType  = "Signed" and Bytes<8 )
                             Val     :=  Signed(Val, Bytes*8)

                        Else
                        If ( IntType  =  "Hex"  )
                             Val     :=  Format("0x{:0"  (Bytes*2) "X}", Val)

                        Else
                        If ( Val < 0 )
                             IntType := "Signed"

                        A_Clipboard  :=  Val
                        MySB_Tip("[Copied " StrLower(IntType) " integer" (BigE ? " *BigE*" : "") "] " Bytes " :    " Val, 0)

                        Rich1.OnNotify(0x700, EN_MSGFILTER, 1)                       ;  Monitor number key press in Hex data
                    }

    Loop ( 8 )
           HexInt.Add(   A_Index " byte" A_Tab "Ctrl+"       A_Index, CopyInteger)
         , Unsigned.Add( A_Index " byte" A_Tab "Alt+"        A_Index, CopyInteger)
         , Signed.Add(   A_Index " byte" A_Tab "Shift+Ctrl+" A_Index, CopyInteger)

    IntMenu.Add("&Hex", HexInt)
  , IntMenu.Add("&Unsigned", Unsigned)
  , IntMenu.Add("&Signed"  , Signed)

  , HexMenu.Add("&Copy to clipboard    "  A_Tab "Ctrl+C", (*) => CopyToClipboard(MyGui.FocusedCtrl))
  , HexMenu.Add()
  , HexMenu.Add("Copy as &Integer", IntMenu)
  , HexMenu.Add("Co&py as Base64       "  A_Tab "Ctrl+P", (*) => CopyAsBase64())
  , HexMenu.Add()
  , HexMenu.Add("Copy &GUID            "  A_Tab "Ctrl+G", (*) => CopyGUID())
  , HexMenu.Add("Copy &Text (unicode)  "  A_Tab "Ctrl+T", (*) => CopyText("UTF-16"))
  , HexMenu.Add("Cop&y Text (utf-8)    "  A_Tab "Ctrl+Y", (*) => CopyText("UTF-8"))
  , HexMenu.Add()

                    HexDataGoTo(Pos)
                    {
                        If ( Rich1.Focused = 0 )
                             Rich1.Focus()

                        If ( Pos = -1 )
                             PostMessage(0xB1, UpDn1.Value*3, UpDn1.Value*3  + 2, Rich1)
                        Else
                        If ( Pos =  0 )
                             PostMessage(0xB1, Pos, Pos, Rich1)
                        Else PostMessage(0xB1, Pos+2, Pos+2, Rich1)
                    }

    HexMenu.Add("Goto &First offset"     A_Tab "Ctrl+F",(*) => HexDataGoTo(     0))
  , HexMenu.Add("Goto &Last offset "     A_Tab "Ctrl+L",(*) => HexDataGoTo(HexL-3))
  , HexMenu.Add("Select Curre&nt offset" A_Tab "Ctrl+N",(*) => HexDataGoTo(    -1))

  , Menus.Add("&File",         FileMenu)
  , Menus.Add("&Quick-focus",  FocusMenu)
  , Menus.Add("Quick-to&ggle", ToggleMenu)
  , Menus.Add("&Search-types", SearchFill)
  , Menus.Add("&Hex-data",     HexMenu)
  , MyGui.MenuBar := Menus                                ;           ----------------   Gui MenuBar End -------------------
    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  , Rich1.OnEvent("ContextMenu", (*) => HexMenu.Show())
  , TextB.OnEvent("ContextMenu", (*) => FileMenu.Show())
  , Text2.OnEvent("ContextMenu", (*) => SearchFill.Show())


                    GuiClose()
                    {
                        ListBuffer.Pos := Bin.Size ? (UpDn1.Value + 1) : 0

                        If ( GetKeyState("Control", "P") )
                             ExitApp

                        If ( Loading )
                             Return ( RetVal := 0 )

                        If ! ( RetVal = 0 or RetVal = 1 )
                        {
                               If ( RetVal<0 And Bin.HasProp("NoReturn0") And Bin.NoReturn0 )
                               {
                                    If ( Bin.HasProp("NoReturn0_Msg") and StrLen(Bin.NoReturn0_Msg) )
                                         Return MySB_Tip(Bin.NoReturn1_Msg, 5000)
                                    Else Return MySB_Tip("[Return] : Lesser than 0 disabled", 5000)
                               }

                               Else
                               If ( RetVal>0 And Bin.HasProp("NoReturn1") And Bin.NoReturn1 )
                               {
                                    If ( Bin.HasProp("NoReturn1_Msg") and StrLen(Bin.NoReturn1_Msg) )
                                         Return MySB_Tip(Bin.NoReturn1_Msg, 5000)
                                    Else Return MySB_Tip("[Return] : Greater than 1 disabled", 5000)
                               }
                        }

                        MySB_Tip("", 0)                                            ;  Clear any pending timers

                        DllCall("User32\DestroyWindow", "ptr",hTooltip)
                        MyGui.Destroy()

                        DllCall("Kernel32\FreeLibrary", "ptr",hMod1)               ;  RichEd20.dll
                        DllCall("Kernel32\FreeLibrary", "ptr",hMod2)               ;  Crypt32.dll
                    }

    MyGui.OnEvent("Close",  (*) => (RetVal := 0, GuiClose()))
  , MyGui.OnEvent("Escape", (*) => (RetVal := 0, GuiClose()))

                    FocusIndicator(Ctrl)
                    {
                        Local Prefix := Chr(0x25BC) A_Space

                        If ( SubStr(Ctrl.Text, 1, 2) = Prefix )
                             Ctrl.Text := SubStr(Ctrl.Text, 3)
                        Else Ctrl.Text := Prefix Ctrl.Text
                    }

    Edit1.OnEvent("Focus",     (*) => FocusIndicator(Text1))
  , Edit1.OnEvent("LoseFocus", (*) => FocusIndicator(Text1))
  , Edit2.OnEvent("Focus",     (*) => FocusIndicator(Text2))
  , Edit2.OnEvent("LoseFocus", (*) => FocusIndicator(Text2))
  , Edit3.OnEvent("Focus",     (*) => FocusIndicator(Text3))
  , Edit3.OnEvent("LoseFocus", (*) => FocusIndicator(Text3))
    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                                          ;           -------   Rich control settings/routines  begin  -----
    Local  EN_SETFOCUS  :=  0x100
        ,  EN_KILLFOCUS :=  0x200

    Rich1.OnCommand(EN_SETFOCUS,  (*) => FocusIndicator(Text4))
  , Rich1.OnCommand(EN_KILLFOCUS, (*) => FocusIndicator(Text4))

                    EN_MSGFILTER(GuiControl, Param)                                ;  EN_MSGFILTER    := 0x700
                    {
                    ;   Triggered when Number keys are pressed when Rich1 control has focus. Pressing number keys 1 thru 8,
                    ;   (not NumPad) jumps offsets forward by as many bytes.   Combine with shift to jump offsets backward.

                        Local  Offset  :=  Param+(A_PtrSize*3)
                            ,  Msg     :=  NumGet(Offset, "uint")
                            ,  wParam  :=  NumGet(Offset+4, A_PtrSize*0, "ptr")
                            ,  Key     :=  Chr(wparam)

                         If ( Msg = 0x101     ;  WM_KEYUP := 0x101                 ;  When pressed key is released
                        and   IsNumber(Key)                                        ;  and the released key is a number
                        and   Key>0 and Key<9                                      ;  and number is in range of 1-8
                        and   GetKeyState("Control", "P") = 0 )                    ;  and Control is not detected, then
                              UpDn1.Value  +=  GetKeyState("Shift", "P")           ;  If shift key is detected
                                           ?   0 - Integer(Key)                    ;  shift as many bytes backward, else
                                           :   Integer(Key)                        ;  shift as many bytes forward
                    }


                    EN_SELCHANGE(GuiControl, lParam)                               ;  EN_SELCHANGE  := 0x702
                    {
                        pCHARRANGE  :=  lParam+(A_PtrSize*3)                       ;  Called whenever Rich1,
                    ,   Rich1_Min   :=  NumGet(pCHARRANGE, 0, "uint") // 3         ;  (Hex data) selection changes
                    ,   Rich1_Max   :=  NumGet(pCHARRANGE, 4, "uint") // 3

                        If ( Rich1_Max  =  Bin.Size )
                             Rich1_Max -=  1

                        SelBytes  :=  Rich1_Max - Rich1_Min + 1

                        If ( UpDn1.Value != Rich1_Min )
                             SelectOffsetEnable(False)                             ;  Turn off to avoid recursive triggering
                         ,   UpDn1.Value := Rich1_Min                              ;  Update offset.  (without SelectOffset)
                         ,   SelectOffsetEnable(True)                              ;  Turn back on event change

                        Bytes       :=  Min(Bin.Size - UpDn1.Value, 192)
                    ,   TextB.Text  :=  BinToTxt192(Bin.Ptr + UpDn1.Value, Bytes)  ;  Update Text
                    ,   NumValues(Bin, UpDn1.Value, Bytes)                         ;  Update Values

                        If ( SelBytes > 1 )
                             MySB_Tip("[Selected bytes] : " SelBytes, 0)
                        Else
                        If ( SubStr(SB_Text, 1, 19) = "[Selected bytes] : " )
                             MySB_Tip("", 0)
                    }

 ;  EM_SETEVENTMASK := 0x445,  ENM_SELCHANGE := 0x80000,  ENM_KEYEVENTS := 0x10000
 ;  EN_MSGFILTER    := 0x700,  EN_SELCHANGE  := 0x702,    EN_SETFOCUS   := 0x100,    EN_KILLFOCUS := 0x200

    PostMessage(0x445, 0, 0x80000|0x10000, Rich1)                                  ;  Set Event Mask

  , Rich1.OnNotify(0x700, EN_MSGFILTER, 1)                                         ;  Monitor number key press in Hex data
  , Rich1.OnNotify(0x702, EN_SELCHANGE, 1)                                         ;  Monitor selection change in Hex data

                                                          ;           -------   Rich control settings/routines  end  -------
    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                                          ;           ----------  Tooltip for controls routines begin  -----

                    CtrlSetTip(GuiCtrl, TipText, *)              ;  Original by 'just me'.
                    {                                            ;  GuiCtrlSetTip() - Add tooltips to your Gui.Controls
                                                                 ;  https://www.autohotkey.com/boards/viewtopic.php?t=116218
                        TOOLINFO  :=  Buffer(24 + (A_PtrSize * 6), 0)                 ;  I've simplified it for ListBuffer()

                      ; TTF_SUBCLASS | TTF_IDISHWND := 0x11  (TTF_SUBCLASS := 0x10, TTF_IDISHWND := 0x1)
                        NumPut("uint",24 + (A_PtrSize * 6), "uint",0x11, "uptr",MyGui.Hwnd, "uptr",MyGui.Hwnd, TOOLINFO)

                                        CreateToolTip()
                                        {
                                            hToolTip := DllCall("User32\CreateWindowEx", "uint",0
                                                              , "str","tooltips_class32", "ptr",0, "uint",0x80000003
                                                              , "int",0x80000000, "int",0x80000000, "int",0x80000000
                                                              , "int",0x80000000, "ptr",MyGui.Hwnd, "ptr",0
                                                              , "ptr",0, "ptr",0, "uptr")

                                            SendMessage(0x418, 0, 1000, hToolTip)          ;  TTM_SETMAXTIPWIDTH := 0x418
                                            SendMessage(0x403, 0, 1000, hToolTip)          ;  TTM_SETDELAYTIME   := 0x403
                                                                                           ;    , TTDT_AUTOMATIC := 0
                                            DllCall("Uxtheme\SetWindowTheme", "ptr",hToolTip, "ptr",0, "ptr",0)
                                        }

                        If ( hToolTip = 0 )
                             CreateToolTip()

                        NumPut("uptr", GuiCtrl.Hwnd, TOOLINFO, 8 + A_PtrSize)
                        SendMessage(0x0432, 0, TOOLINFO.Ptr, hToolTip)                     ;  TTM_ADDTOOLW       := 0x432

                        NumPut("uptr", StrPtr(TipText), TOOLINFO, 24 + (A_PtrSize * 3))    ;  lpszText
                      	SendMessage(0x0439, 0, TOOLINFO.Ptr, hToolTip)                     ;  TTM_UPDATETIPTEXTW := 0x439
                    }

    Local  TOOLINFO                                       ;  TOOLINFO structure  ( Size:  24 + (A_PtrSize * 6) )
        ,  hToolTip       :=  0                           ;  Created by CtrlSetTip() and  destroyed at GuiClose()
        ,  Tip            :=  Tips(Bin.Size-1)            ;  Tip[] is passed to CtrlSetTip()

                    Tips(Bytes)
                    {
                        Return StrSplit( StrReplace("
                        (   Join`s
                            Use Mouse wheel or Up/Down arrow`nto Scroll between Offset 0 to ***`n`nQuick focus:  CTRL+O|For
                            Search-types, Right-CLICK here or press ALT+S`nFor searching CLICK here or press ENTER
                            `n`nQuickfocus:  CTRL+S|Search in Reverse`n(When checked, make sure Offset is at end of data)
                            `nUse CTRL+L to seek last offset`n`nQuick Toggle: CTRL+R|Hex data.`nSeek first offset:
                            CTRL+F`nSeek last offset: CTRL+L`nSelect offset: CTRL+N`n`nQuick focus: CTRL+H|Pointer type
                            `nand`nPointer|Maximum text display of 192 bytes,`nstarting from current Offset|Values`n`nQuick
                            focus:  CTRL+U|Toggle values between Little/Big Endian`n`nQuick Toggle: CTRL+B
                        )", "***", Bytes), "|" )
                    }

    CtrlSetTip(Text1, Tip[1]) ; Offset
  , CtrlSetTip(Text2, Tip[2]) ; Search
  , CtrlSetTip(Text3, Tip[7]) ; Values
  , CtrlSetTip(Text4, Tip[4]) ; Hex data
  , CtrlSetTip(Text5, Tip[5]) ; Pointer
  , CtrlSetTip(Text6, Tip[6]) ; Text (BinText)
  , CtrlSetTip(ChkB1, Tip[3]) ; Reverse
  , CtrlSetTip(ChkB2, Tip[8]) ; BigEndian
                                                          ;           ------------  Tooltip for controls routines end  -----
    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    WinMoveBottom(TextL)                                  ;  To display correctly ordered ClassNN in Window Spy
  , WinMoveBottom(Rich1)
  , WinMoveBottom(Edit3)

    If ( LoadDelay )
         TextL.Text := "LoadDelay.. Please wait!"
     ,   Rich1.Opt("-Redraw")
     ,   MyGui.Opt("+Disabled")

    MyGui.Show("AutoSize")  ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - Show the GUI
    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    MySB_Tip(Text, TimeOut := 3000)
                    {
                        Static  Address :=  0

                        Timeout :=  Abs(TimeOut)
                        SB_Text :=  Text
                        Text    :=  RTrim(A_Space Text, A_Space)
                        MySB.SetText(Text, 2)

                        If ( Address )
                             DllCall("User32\KillTimer", "ptr",MyGui.Hwnd, "int",1234)
                         ,   CallbackFree(Address)
                         ,   Address := 0

                        If ( TimeOut = 0 )
                             Return 1

                        Address  :=  CallbackCreate( MySB_Tip.Bind("", 0) )
                        DllCall("User32\SetTimer", "ptr",MyGui.Hwnd, "uint",1234, "uint",TimeOut, "ptr",Address)
                    }

    MySB_Tip("[Loading ...]", 0)

    If ( Bin.Size )
         Hex      :=  BufferToSHex(Bin)                                             ;  Convert buffer to 'Spaced Hex' buffer
       , DllCall("User32\SetWindowTextA", "ptr",Rich1.Hwnd, "ptr",Hex)              ;  and apply 'Spaced Hex' into RichEdit
       , Hex.Size :=  0                                                             ;  and save memory

    If ( LoadDelay )                                           ;  The following is as good as Ctrl+End
         Rich1.OnNotify(0x702, EN_SELCHANGE, 0)                ;  Monitor selection change in Hex data (Turn off)
       , SendMessage(0xB1, Bin.Size*3+2, Bin.Size*3+2, Rich1)  ;  Move to Hex last offset to fully account loading time
       , Rich1.OnNotify(0x702, EN_SELCHANGE, 1)                ;  Monitor selection change in Hex data (Turn on)

    UpDn1.Value := 0
  , TickCount  :=  Round(QPC(), 3)                             ;  End of Loading time.

    Local  Size  :=  DllCall("Shlwapi\StrFormatByteSizeW", "int64",Bin.Size, "str",Format("{:16}",""), "int",16, "str")
    MySB_Tip("[Loading completed] : " Size " in " TickCount "s", 9999)

    If ( LoadDelay=0 and TickCount > 0.5 )
    or ( LoadDelay=1 and TickCount > 2.0 )
         SoundBeep()

    If ( LoadDelay )
         TextL.Text := ""
       , Rich1.Opt("+Redraw")
       , MyGui.Opt("-Disabled")

    If ( Bin.HasProp("Offset") and IsInteger(Bin.Offset) )
         SelectOffsetEnable(False)
       , UpDn1.Value := Bin.Offset
       , RichSelectChars(1)
       , SelectOffsetEnable(True)

    If ( Bin.HasProp("Focus") )
    {
         If ( Bin.Focus = "Offset" )
              Edit1.Focus()

         If ( Bin.Focus = "Search" )
              Edit2.Focus()

         If ( Bin.Focus = "Hex" )
              Rich1.Focus()
    }

    If ( Bin.HasProp("Search") and InStr(Bin.Search, ":", True) )
         Edit2.Text := Bin.Search
       , Sleep(0)
       , RichSelectChars(0)
       , TrySearch()

    Loading        :=  False                                   ;  Mark Loading completed to allow GuiClose() to work.
    WinWaitClose(MyGui.Hwnd)
    Return RetVal

    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   End of Main! Dependencies follow


                     ReplaceWithNulls(Buf, Ord, nType)                     ;  by SKAN on D78I/D78I
                     {                                                     ;  @ autohotkey.com/r?p=581806
                         Local  nAdv :=  ( nType="short" ? 2 : 1 )
                             ,  nPtr :=  Buf.Ptr - nAdv

                         Loop ( Buf.Size // nAdv )
                                If ( NumGet(nPtr += nAdv, nType) = Ord )
                                     NumPut(nType, 0, nPtr)
                    }

                    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    ByteRev(Buf1)                                         ;  by SKAN on D78L/D78L
                    {                                                     ;  @ autohotkey.com/r?p=581806
                        Local  Buf2 := Buffer(Buf1.Size)

                        Loop ( Buf1.Size )
                               NumPut("char", NumGet(Buf1, A_Index-1, "char"), Buf2,  Buf1.Size-A_Index)

                        Return Buf2
                    }

                    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    NumValues(Source, Offset, Bytes)      ;  Formats and Updates Values edit control
                    {
                        If ( Bytes < 1 )                  ;  To handle empty buffer like:     B := Buffer(0),  ListBuffer(B)
                             Return

                        Static Buf     :=  Buffer(8)
                        Local  Num
                            ,  Double_ :=  ""
                            ,  Float_  :=  ""
                            ,  NumType :=  Bytes>7 ? "uint64" : Bytes>2 ? "uint" : Bytes>1 ? "ushort" : "uchar"
                            ,  Val     :=  0

                        If ( Bytes != 3 )
                             Val       :=  NumGet(Source, Offset,    NumType)
                        Else           ;   read uint24
                             Val       :=  NumGet(Source, Offset,   "ushort")
                                       | ( NumGet(Source, Offset+2, "uchar" ) << 16 )

                        Num  :=  Format("{:016X}", Val)
                     ,  Num  :=  BigE

                             ?  Format( "0x{15:}{16:}"
                                     . "|0x{15:}{16:}{13:}{14:}"
                                     . "|0x{15:}{16:}{13:}{14:}{11:}{12:}"
                                     . "|0x{15:}{16:}{13:}{14:}{11:}{12:}{09:}{10:}"
                                     . "|0x{15:}{16:}{13:}{14:}{11:}{12:}{09:}{10:}{07:}{08:}{05:}{06:}{03:}{04:}{01:}{02:}"
                                     ,  StrSplit(Num)* )

                             :  Format( "0x{15:}{16:}"
                                     . "|0x{13:}{14:}{15:}{16:}"
                                     . "|0x{11:}{12:}{13:}{14:}{15:}{16:}"
                                     . "|0x{09:}{10:}{11:}{12:}{13:}{14:}{15:}{16:}"
                                     . "|0x{01:}{02:}{03:}{04:}{05:}{06:}{07:}{08:}{09:}{10:}{11:}{12:}{13:}{14:}{15:}{16:}"
                                     ,  StrSplit(Num)* )

                     ,  Num  :=  StrSplit(Num, "|")
                     ,  Num[5] += 0,  Num[4] += 0,  Num[3] += 0,  Num[2] += 0,  Num[1] += 0 ; Convert Hex to Decimal numbers

                        If ( Bytes > 7 )
                             Double_  :=  NumGet(NumPut("int64", Num[5], Buf) - 8, "double")
                         ,   Double_  :=  Format("{:.15g}", Double_)
                         ,   Double_  :=  StrLen(Double_) > 16 ? "" : Double_

                        If ( Bytes > 3 )
                             Float_   :=  NumGet(NumPut("uint",  Num[4], Buf) - 4, "float")
                         ,   Float_   :=  Format("{:.7g}", Float_)
                         ,   Float_   :=  StrLen(Float_)  >  9 ? "" : Float_

                        If ( Bytes < 8 )                                              ;  Blank out redundant zeroes
                        {
                                 Num[5] := ""
                            If ( Bytes < 4 )
                                 Num[4] := ""
                            If ( Bytes < 3 )
                                 Num[3] := ""
                            If ( Bytes < 2 )
                                 Num[2] := ""
                        }

                        Edit3.Text := Format( "Char  {1:11} {2:11}             Float"   CRLF
                                            . "Short {3:11} {4:11}  {5:16}"             CRLF
                                            . "Int24 {6:11} {7:11}                  "   CRLF
                                            . "Int32 {8:11} {9:11}            Double"   CRLF
                                            . "Int64 {10:23}  {11:16}"
                                            , Num[1]
                                            , Num[1]<0x80                     ? Num[1] : (Num[1] & 0x7F      )  - 0x80
                                            , Num[2]
                                            , Not Num[2] || Num[2]<0x8000     ? Num[2] : (Num[2] & 0x7FFF    )  - 0x8000
                                            , Float_
                                            , Num[3]
                                            , Not Num[3] || Num[3]<0x800000   ? Num[3] : (Num[3] & 0x7FFFFF  )  - 0x800000
                                            , Num[4]
                                            , Not Num[4] || Num[4]<0x80000000 ? Num[4] : (Num[4] & 0x7FFFFFFF)  - 0x80000000
                                            , Num[5]
                                            , Double_
                                            )
                    }

                    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    BufferToSHex(Buf)                     ;  Converts buffer content to 'Spaced Hex', much faster than
                    {                                     ;  Crypt32.dll.  Every byte is converted in to
                        Static mCode                      ;  2 hex Chars + 1 space = 3 Chars.   So, 1.0 MB of Buffer will
                        Local  Hex                        ;  consume 3.0 MB ANSI text (+ Null Terminator) in
                            ,  mSz := 128                 ;  Rich1 (RichEdit20A) control.

                        If ( IsSet(mCode) = 0 )
                            mCode := Buffer(mSz, 0)
                         ,  DllCall("Kernel32\VirtualProtect", "ptr",mCode, "ptr",mSz, "int",0x40, "int*",0)
                         ,  DllCall("Crypt32\CryptStringToBinary"
                                  , "str",A_PtrSize=8

                                  ? "U1ZFhcB2djHARTHJDx9AAEGJwkYPthQRRYnTQcHrBESI20GD+wlAD5fWQPbeQIDmB0CAxjBAAPNEic6IHDJFid"
                                  . "NBg+MPRYjaQYP7CUEPl9NB9ttBgOMHQYDDMEUA2mdFjVkBRogUGmdFjVECQsYEEiBBg8EDg8ABRDnAcpNeW8M="

                                  : "VYnlg+wEU1ZXi30Mg30QAHZQMfYx24tNCA+2DDGJTfzB6QSIyoP5CQ+X0PbYJAcEMADCiBQfi1X8idGD4Q+Iyo"
                                  . "P5CQ+X0fbZgOEHgMEwAMqIVB8BxkQfAiCDwwNGO3UQcrRfXluJ7F3D"

                                  , "int",A_PtrSize=8 ? 172 : 140, "int",0x1, "ptr",mCode, "intp",mSz, "int",0, "int",0)

                        Hex := Buffer((Buf.Size*3) + 2)                             ;  bytes extra for null terminator
                        DllCall(mCode, "ptr",Buf, "ptr",Hex, "int",Buf.Size, "cdecl")
                        NumPut("ushort", 0, Hex, Hex.Size - 2)                      ;  put a trailing null terminator

                        Return Hex                        ;  Return 'Spaced Hex' as buffer
                    }

                    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    BinToTxt192(pBin, Bytes:=192)         ;  Converts binary content to printable/readable text.
                    {
                        Local  Txt  :=  BinToTxt(pBin, Bytes)
                               Txt  :=  StrGet(Txt, "cp0")

                        Return  SubStr(Txt,  1, 48)  LF  SubStr(Txt,  49, 48)  LF
                             .  SubStr(Txt, 97, 48)  LF  SubStr(Txt, 145, 48)
                    }

                    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    BinToTxt(pBin, Bytes)                 ;  Converts binary content to printable/readable text.
                    {                                     ;  Chrs in range of 0-32, 126-161 and 173
                        Static mCode                      ;  are converted to Chr(46), a period '.'
                        Local  Txt
                            ,  mSz := 104

                        If ( IsSet(mCode) = 0 )
                            mCode := Buffer(mSz, 0)
                         ,  DllCall("Kernel32\VirtualProtect", "ptr",mCode, "ptr",mSz, "int",0x40, "int*",0)
                         ,  DllCall("Crypt32\CryptStringToBinary"
                                  , "str",A_PtrSize=8

                                  ? "U1ZFhcB2WjHARTHJQYnCRg+2HBFBg/sgcwe7LgAAAOsqQbouAAAAQYH7rQAAAEEPRfNBD0TyQbouAAAAQYPrf0"
                                  . "GD+yFBD0baD0feRYnKQYjbRogcEkGDwQGDwAFEOcByq15bww=="

                                  : "U1ZXg3wkGAB2SDHAMdKLTCQQD7YMAYP5IHMHvi4AAADrH78uAAAAgfmtAAAAD0X5uy4AAACD6X+D+SEPRvMPR/"
                                  . "eLTCQUifOIHBFCQDtEJBhyvF9eW8M="

                                  , "int",A_PtrSize=8 ? 136 : 116, "int",0x1, "ptr",mCode, "intp",mSz, "int",0, "int",0)

                        Txt := Buffer(Bytes)
                        DllCall(mCode, "ptr",pBin, "ptr",Txt, "int",Bytes, "cdecl")

                        Return Txt
                    }

                    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    TrySearch()              ;   Attempt search
                    {
                        Local  Val           :=  Edit2.Text

                        If ( StrLen(Val) = 0 or Bin.Size = 0 )
                             Return

                        Local  Pos           :=  0
                             , Sel           :=  0
                             , Err           :=  Object()

                        If ( InStr(Val, ":") = 0 )
                             Return MySB_Tip("[Search Error] : Invalid search.  Enter 'Type:Value'")

                        If  ( ReverseSearch = 1  and  UpDn1.Value = 0 )
                              Return MySB_Tip("[Note] : Cannot search backward at first offset. Try at Offset " Bin.Size-1)

                        If  ( ReverseSearch = 0  and  UpDn1.Value = Bin.Size-1 )
                              Return MySB_Tip("[Note] : Cannot search forward at last offset. Try at Offset 0")

                        QPC(1)
                        Sel :=  GetSelChars(Rich1)

                        If ( Sel )
                             SelectOffsetEnable(False)
                         ,   UpDn1.Value +=  ReverseSearch ? -1 :  +1

                        Try   Pos := Search(Bin, Val)
                        Catch as Err
                        {}

                        If ( Sel )
                             UpDn1.Value += ReverseSearch ?  +1  : -1
                         ,   SelectOffsetEnable(True)

                        TickCount  :=  Round(QPC()*1000, 1)

                        If ( Err.HasProp("Message") )
                             Return  MySB_Tip("[Search Error] : " Err.Message ".", 5000)

                        If ( Pos )
                        {
                             SelectOffsetEnable(False)

                        ,    UpDn1.Value := Pos - 1
                        ,    SelBytes    := Needle.Size
                        ,    RichSelectChars(SelBytes, True)

                        ,    SelectOffsetEnable(True)

                        ,    MySB_Tip("[Search] : " Needle.Type " found at offset " Pos-1 " in " TickCount "ms", 9999)
                             Return
                        }

                        Local Loc := ReverseSearch ? "before" : "after"
                        MySB_Tip("[Search] : " Needle.Type " not found " Loc " offset " UpDn1.Value, 9999)
                    }

                    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    Search(HayBuffer, Val)                     ;  Formats user's 'search input' into proper Needle, based on
                    {                                          ;  Type and Value (Type:Value)...    Examples:
                        Val    :=  StrSplit(Val, ":",, 2)      ;
                        Val[1] :=  StrLower( Trim(Val[1]) )    ;  6 bytes x 8 bits = 48 bit search: '6:0x987654321000'
                                                               ;
                        Local  ValType      :=  Val[1]         ;                                 or '6:167633986129920'
                            ,  Value        :=  Val[2]         ;                                 or '6:-113840990580736'
                            ,  ValType_     :=  ""             ;
                            ,  Buf          :=  Buffer(8, 0)   ;  Hex search unicode text '.ahk': ':2E 00 61 00 68 00 6B 00'
                            ,  NullReplChr  :=  ""             ;
                            ,  Needle1      :=  Buffer(0)      ;  Numput based search:  'int:-1', 'uint:1024', 'float:1.234'
                            ,  Needle2      :=  Buffer(0)      ;
                            ,  Len          :=  0              ;  StrPut based search:  'cp0:Fox', 'utf-8:Fox', 'utf-16:Fox'
                            ,  Bytes        :=  0              ;
                            ,  IsUnicode    :=  0              ;
                            ,  Pos          :=  0              ;
                            ,  StartingPos  :=  1              ;

                            ,  Translation  :=  Map( "unicode","utf-16", "u","utf-16", "ansi","cp0", "a","cp0", "u8","utf-8"
                                                   ,  "u16","utf-16", "utf8","utf-8", "utf16","utf-16", "","Hex", "int8",1
                                                   ,  "int16",2, "int24",3, "int32",4, "int40",5, "int48",6, "int56",7
                                                   ,  "float?","float, double", "double?","double, float"
                                                   ,  "utf-8?","utf-8, utf-16", "utf-16?","utf-16, utf-8"  )

                            ,  NumPutTypes  :=  Map(  "uint",4, "uint64",8, "int",4, "int64",8, "short",2, "ushort",2
                                                   ,  "char",1, "uchar",1, "double",8, "float",4, "ptr",A_PtrSize
                                                   ,  "uptr",A_PtrSize, "float, double",0, "double, float",0  )

                        If ( StrLen(Value) = 0 )
                             Throw ValueError("Value empty", 0)

                        If ( SubStr(ValType, -1) = "*" )
                             ValType     :=  RTrim(ValType, "*")
                           , NullReplChr :=  SubStr(Value, 1, 1)   ;  ReplaceWithNulls() for StrPut & ByteRev() for NumPut()

                        If ( Translation.Has(ValType) )
                             ValType := Translation[ValType]

                        If ( IsNumber(ValType) )                                   ;  example 40 bit/5 byte search: '5:-255'
                        {
                             If ( ValType > 0 and ValType < 9 )
                             {
                                    Try  NumPut("uint64", Value, Buf)
                                      ,  Needle1 := Buffer(ValType)
                                      ,  DllCall("Kernel32\RtlMoveMemory", "ptr",Needle1, "ptr",Buf, "ptr",ValType)
                                  Catch
                                         Throw ValueError("Invalid numerical Value", -1)
                             }
                             Else       Throw ValueError("Invalid bytes of " ValType " as type. Use 1 to 8", -1)

                             If ( StrLen(NullReplChr) )
                                  Needle1 := ByteRev(Needle1)

                             ValType := "int" (ValType * 8)
                        }

                        Else  ;  NumPut based search
                        If  ( NumPutTypes.Has(ValType) )                           ;  example num search: 'uint:1024'
                        {
                              Loop Parse, ValType, ",", A_Space
                              {
                                     Try   ValType_             :=  A_LoopField
                                       ,   Needle%A_Index%      :=  Buffer( NumPutTypes[ValType_] )
                                       ,   Needle%A_Index%.Type :=  ValType_
                                       ,   NumPut(ValType_, Value, Needle%A_Index%)
                                   Catch
                                           Throw ValueError("Invalid numerical Value", -3)

                                   If ( StrLen(NullReplChr) )
                                        Needle%A_Index% := ByteRev(Needle%A_Index%)
                              }
                        }

                        Else  ;  Hex based search
                        If  ( ValType  =   "Hex" )                                 ;  example hex search: ':FF 00 FF 00'
                        {
                              Value    :=  StrReplace(Value, A_Space)
                            , Len      :=  StrLen(Value)
                            , Bytes    :=  Ceil(Len/2)
                            , Needle1  :=  Buffer(Bytes)
                                                                              ;  CRYPT_STRING_HEXRAW := 0xC
                              If ! DllCall("Crypt32\CryptStringToBinary", "str",Value, "int",Len, "int",0xC
                                         , "ptr",Needle1, "uintp",Bytes, "int",0, "int",0)
                                   Throw ValueError("Invalid hex Value" , -2)
                        }

                        Else  ; StrPut based text search
                        {
                             If ( StrLen(NullReplChr) )
                                  Value  :=  SubStr(Value, 2)

                             Loop  Parse, ValType, ",", A_Space
                             {
                                     Try   ValType_             :=  A_LoopField
                                       ,   Needle%A_Index%      :=  Buffer(StrPut(Value, ValType_))
                                       ,   Bytes                :=  StrPut(Value, Needle%A_Index%, ValType_)
                                       ,   IsUnicode            :=  NumGet(Needle%A_Index%, Bytes - 2, "short") = 0
                                       ,   Needle%A_Index%      :=  Buffer(Bytes - 1 - IsUnicode)
                                       ,   Needle%A_Index%.Type :=  ValType_
                                       ,   StrPut(Value, Needle%A_Index%, ValType_)
                                   Catch
                                           Throw ValueError("Invalid text search", -4)

                                  If ( StrLen(NullReplChr) )
                                       ReplaceWithNulls(Needle%A_Index%, Ord(NullReplChr), IsUnicode ? "short" : "char")
                             }    Until ( A_Index = 2 )
                        }

                        StartingPos :=  ReverseSearch = 0
                                    ?   UpDn1.Value + 1
                                    :   Min(0, UpDn1.Value - HayBuffer.Size +  Needle1.Size)

                        Pos := InBuffer(HayBuffer, Needle1, StartingPos)
                     ,  Needle := Needle1

                        If ( Pos > 0 and Needle2.Size )
                             ValType  := Needle1.Type

                        If ( Pos = 0 and Needle2.Size )
                        {
                            StartingPos :=  ReverseSearch = 0
                                        ?   UpDn1.Value + 1
                                        :   Min(0, UpDn1.Value - HayBuffer.Size +  Needle2.Size)

                            If ( Pos := InBuffer(HayBuffer, Needle2, StartingPos) )
                                 ValType := Needle2.Type
                               , Needle  := Needle2
                        }

                        Needle.Type := StrTitle(ValType)
                        Return Pos
                    }

                    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    InBuffer(HayBuffer, NeedleBuffer, StartingPos?, Occurrence?)              ;  by SKAN on D456/D78K
                    {                                                                         ;  @ autohotkey.com/r?t=101121
                        Static mCode
                        Local  mSz  :=  184
                            ,  Pos  :=  0

                        If ( NeedleBuffer.Size > HayBuffer.Size )
                             Return 0

                        If  ( IsSet(mCode) = 0 )
                            mCode  :=  Buffer(mSz, 0)
                         ,  DllCall("Kernel32\VirtualProtect", "ptr",mCode, "ptr",mSz, "int",0x40, "intp",0)
                         ,  DllCall("Crypt32\CryptStringToBinary"
                                  , "str",A_PtrSize=8

                                  ? "U1ZXQVSLRCRIRItcJFCJ00Qpy4XAvgEAAABBuv////9BD07yhcB+B2dEjVD/6wgBwkGJ0kUpykSJ0kGD6QE52n"
                                  . "dnMcBBidJBijhCODwRdU9FicpHihQQZ0KNPApEOBQ5dT1Bg/kCci9BugEAAABBg/kBdh5EiddBijw4Z0aNJBJF"
                                  . "ieRCODwhdQlBg8IBRTnKcuJFOcp1A4PAAUQ52HQOAfKF0nIEOdp2mzHA6wRnjUIBQVxfXlvD"

                                  : "VYnlg+wMU1ZXi1UUi0UMKdCJRfQxwIN9GAAPntD32IPg/kCJRfiDfRgAfgmLRRhIiUX86wuLRQwDRRgp0IlF/I"
                                  . "tF/InBSjtN9HdbMcCLdQiKHA6LdRA6HnVAjTQRi30Iihw3i3UQOhwWdS+D+gJyJL4BAAAAg/oBdhaNPDGLXQiK"
                                  . "HDuLfRA6HDd1BUY51nLqOdZ1AUA7RRx0EANN+IXJcgU7TfR2pzHA6wONQQFfXluJ7F3D"

                                                ; CRYPT_STRING_BASE64 := 0x1
                                  , "int",A_PtrSize=8 ? 244 : 240, "int",0x1, "ptr",mCode, "intp",mSz, "int",0, "int",0)

                        Try    Pos  :=  DllCall(mCode, "ptr", HayBuffer.Ptr,      "int", HayBuffer.Size
                                                     , "ptr", NeedleBuffer.Ptr, "short", NeedleBuffer.Size
                                                     , "int", StartingPos ?? 1,   "int", Occurrence ?? 1
                                                     , "cdecl uint")
                        Return Pos
                    }
} ; ________________________________________________________________________________________________________________________