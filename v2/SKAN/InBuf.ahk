; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=132507
; Author: SKAN

InBuf(Haystack, TypeVal, StartingPos?, Occurrence?)        ;  InBuf() v0.50 by SKAN on D459/D7AB @ autohotkey.com/r?t=132507
{
    If ( IsObject(Haystack) = 1 )
    If ( HasProp(HayStack, "Ptr") = 0  or  HasProp(HayStack, "Size") = 0  or Haystack.Size = 0 )
         Return ( InBuf.Status := "Invalid Haystack", 0 )
    Else
    If ( Type(Haystack) = "File" and Haystack.Handle = -1 )
         Return ( InBuf.Status := "Invalid File handle", 0 )

    If ( IsObject(TypeVal) = 1 )
         If ( Type(TypeVal) = "Buffer" and TypeVal.HasProp("Type") )
              Return InBuf2(Haystack, TypeVal, Buffer(0), StartingPos?, Occurrence?)
         Else Return ( InBuf.Status := "Invalid needle", 0 )

    If ( Type(TypeVal) != "String" )
         Return ( InBuf.Status := "Invalid Type:Value", 0 )
    Else
    If ( InStr(TypeVal, ":") = 0 )
         Return ( InBuf.Status := "Invalid Type:Value", 0 )

    Local  Val          :=  StrSplit(TypeVal, ":",, 2)
        ,  ValType      :=  StrLower( Trim( Val[1] ) )
        ,  ValType_     :=  ""
        ,  Value_       :=  Val[2]
        ,  Buf          :=  Buffer(8, 0)
        ,  NullReplChr  :=  ""
        ,  Needle1      :=  Buffer(0)
        ,  Needle2      :=  Buffer(0)
        ,  Bytes        :=  0
        ,  IsUnicode    :=  0

        ,  Translation  :=  Map(  "unicode","utf-16", "u","utf-16", "ansi","cp0", "a","cp0", "u8","utf-8"
                               ,  "u16","utf-16", "utf8","utf-8", "utf16","utf-16", "","Hex", "int8",1
                               ,  "int16",2, "int24",3, "int32",4, "int40",5, "int48",6, "int56",7
                               ,  "float?","float, double", "double?","double, float"
                               ,  "utf-8?","utf-8, utf-16", "utf-16?","utf-16, utf-8"  )

        ,  NumPutTypes  :=  Map(  "uint",4, "uint64",8, "int",4, "int64",8, "short",2, "ushort",2
                               ,  "char",1, "uchar",1, "double",8, "float",4, "ptr",A_PtrSize
                               ,  "uptr",A_PtrSize, "float, double",0, "double, float",0  )

    If ( StrLen(Value_) = 0 )
         Return ( InBuf.Status := "Invalid value", 0 )

    If ( SubStr(ValType, -1) = "*" )
         ValType     :=  RTrim(ValType, "*")
       , NullReplChr :=  SubStr(Value_, 1, 1)                      ;  ReplaceWithNulls() for StrPut & ByteRev() for NumPut()

                                        ReplaceWithNulls(Buf, Ord, nType)                     ;  by SKAN on D78I/D78I
                                        {                                                     ;  @ autohotkey.com/r?p=581806
                                            Local  nAdv :=  ( nType="short" ? 2 : 1 )
                                                ,  nPtr :=  Buf.Ptr - nAdv

                                            Loop ( Buf.Size // nAdv )
                                                   If ( NumGet(nPtr += nAdv, nType) = Ord )
                                                        NumPut(nType, 0, nPtr)
                                        }


                                        ByteRev(Buf1)                                         ;  by SKAN on D78L/D78L
                                        {                                                     ;  @ autohotkey.com/r?p=581806
                                            Local  Buf2 := Buffer(Buf1.Size)

                                            Loop ( Buf1.Size )
                                                   NumPut("char", NumGet(Buf1, A_Index-1, "char"), Buf2,  Buf1.Size-A_Index)

                                            Return Buf2
                                        }

    If ( Translation.Has(ValType) )
         ValType := Translation[ValType]

    If ( IsNumber(ValType) )                 ; Odd byte! NumPut based search
    {
         If ( ValType > 0 and ValType < 9 )
         {
               Try  NumPut("uint64", Value_, Buf)
                 ,  Needle1  :=  Buffer(ValType)
                 ,  DllCall("Kernel32\RtlMoveMemory", "ptr",Needle1, "ptr",Buf, "ptr",ValType)
             Catch
                    Return ( InBuf.Status :=  "Invalid numerical value", 0 )
         }
         Else       Return ( InBuf.Status :=  "Invalid numerical type",  0 )

         If ( StrLen(NullReplChr) )
              Needle1  :=  ByteRev(Needle1)

         Needle1.Type  :=  "int" (ValType * 8)
    }

    Else                                     ; Normal NumPut based search
    If  ( NumPutTypes.Has(ValType) )
    {
          Loop Parse, ValType, ",", A_Space
          {
                 Try   ValType_             :=  A_LoopField
                   ,   Needle%A_Index%      :=  Buffer( NumPutTypes[ValType_] )
                   ,   Needle%A_Index%.Type :=  ValType_
                   ,   NumPut(ValType_, Value_, Needle%A_Index%)
               Catch
                       Return ( InBuf.Status :=  "Invalid numerical value", 0 )

               If ( StrLen(NullReplChr) )
                    Needle%A_Index%      := ByteRev(Needle%A_Index%)
                  , Needle%A_Index%.Type := ValType_ ; ???
          }
    }

    Else                                     ; Hex based search
    If  ( ValType  =  "Hex" )
    {
          Value_ :=  StrReplace(Value_, A_Space)

                                        HexToBuf_Loop(&Hex)
                                        {
                                            Local  Buf := Buffer(StrLen(Hex)//2)

                                            Loop ( Buf.Size )
                                                   NumPut("char", "0x" . SubStr(Hex, 2*A_Index-1, 2), Buf, A_Index-1)

                                            Return Buf
                                        }

          If ( Mod(StrLen(Value_), 2) = 0 and IsXDigit(Value_) = 1 )
               Needle1      :=  HexToBuf_Loop(&Value_)
             , Needle1.Type :=  "Hex"
          Else Throw ValueError("Invalid hex Value" , -2)
    }

    Else                                     ; StrPut based text search
    {
          If ( StrLen(NullReplChr) )
               Value_  :=  SubStr(Value_, 2)

          Loop Parse, ValType, ",", A_Space
          {
                 Try   ValType_             :=  A_LoopField
                   ,   Needle%A_Index%      :=  Buffer(StrPut(Value_, ValType_))
                   ,   Bytes                :=  StrPut(Value_, Needle%A_Index%, ValType_)
                   ,   IsUnicode            :=  NumGet(Needle%A_Index%, Bytes - 2, "short") = 0
                   ,   Needle%A_Index%      :=  Buffer(Bytes - 1 - IsUnicode)
                   ,   Needle%A_Index%.Type :=  ValType_
                   ,   StrPut(Value_, Needle%A_Index%, ValType_)
               Catch
                       Return ( InBuf.Status :=  "Invalid text search", 0 )

               If ( StrLen(NullReplChr) )
                     ReplaceWithNulls(Needle%A_Index%, Ord(NullReplChr), IsUnicode ? "short" : "char")
          }    Until ( A_Index = 2 )
    }


    If ( IsObject(Haystack) = 0 )
         Return ( InBuf.Status  :=  StrTitle(Needle1.Type) " needle created",  Needle1 )

    Return InBuf2(Haystack, Needle1, Needle2, StartingPos?, Occurrence?)

                    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    InBuf2(Haystack, Needle1, Needle2, StartingPos?, Occurrence?)
                    {
                        Local  Pos := 0

                        If ( IsObject(Haystack) = 0 )
                             Return ( InBuf.Status := "Invalid Haystack", 0 )

                        If ( Pos := InBuffer(Haystack, Needle1, StartingPos?, Occurrence?) )
                        or ( Needle2.Size = 0 )
                             ValType :=  Needle1.Type

                        If ( Pos = 0 and Needle2.Size )
                        If ( Pos := InBuffer(Haystack, Needle2, StartingPos?, Occurrence?) )
                             ValType := Needle2.Type

                        Return ( InBuf.Status :=  StrTitle(ValType) A_Space (Pos ? "found" : "not found"), Pos )
                    }

                    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    InBuffer(HayBuffer, NeedleBuffer, StartingPos?, Occurrence?)              ;  by SKAN on D456/D79C
                    {                                                                         ;  @ autohotkey.com/r?t=101121
                        Static mcode
                        Local  Pos := 0

                        If (  NeedleBuffer.Size > HayBuffer.Size  or  Min(NeedleBuffer.Size, HayBuffer.Size) = 0  )
                              Return 0

                        If (  IsSet(mcode) = 0  )
                              mcode := Buffer(200, 0)

                           ,  ( A_PtrSize = 8 )
                                ? NumPut( "int64",0x4156415441575653, "int64",0x6024548b44554157, "int64",0x44d38968245c8b44
                                        , "int64",0xbeffffffffb8cb29, "int64",0x0fd2854500000001, "int64",0x67797ed28545f04e
                                        , "int64",0x8941f889ff7a8d41, "int64",0xdc394101e98341c4, "int64",0x45e68945c0316277
                                        , "int64",0x4c75313c3846388a, "int64",0x6730348a47ce8945, "int64",0x46ff89450c3c8d47
                                        , "int64",0xf983413775393438, "int64",0x000001be41297202, "int64",0x383c8a47f7894500
                                        , "int64",0xed8945342c8d4767, "int64",0x83410975293c3846, "int64",0x45e272ce394501c6
                                        , "int64",0x4401c0830375ce39, "int64",0x41f401411674d839, "int64",0x10ebc031a076dc39
                                        , "int64",0xcf2944d789d20144, "int64",0x0124448d416782eb, "int64",0x5c415e415f415d41
                                        , "int64",0xc35b5e5f, mcode)
                                : NumPut( "int64",0x565310ec83e58955, "int64",0x290c458b14558b57, "int64",0x7d83c031f44589d0
                                        , "int64",0x83d8f7d09e0f0018, "int64",0x7d83fc458940fee0, "int64",0x4818458b737e0018
                                        , "int64",0xc189f8458bf84589, "int64",0x45c75d77f44d3b4a, "int64",0x08458b00000000f0
                                        , "int64",0x081c381e8a10758b, "int64",0x10048a10458b4175, "int64",0x0438087d8b11348d
                                        , "int64",0x1f7202fa83307537, "int64",0x10758b00000001b8, "int64",0x7d8b01348d061c8a
                                        , "int64",0x39400575371c3808, "int64",0x830475d039ea72d0, "int64",0x45391c458b01f045
                                        , "int64",0x4d3bfc4d031974f0, "int64",0x8b10ebc031aa76f4, "int64",0x89d0291845030c45
                                        , "int64",0x5f01418d87ebf845, "int64",0xc35dec895b5e, mcode)

                           ,  DllCall("Kernel32\VirtualProtect", "ptr",mcode, "ptr",200, "int",0x40, "intp",0)

                        Try   Pos :=  DllCall(mcode, "ptr", HayBuffer.Ptr,      "int", HayBuffer.Size
                                                   , "ptr", NeedleBuffer.Ptr, "short", NeedleBuffer.Size
                                                   , "int", StartingPos ?? 1,   "int", Occurrence ?? 1
                                                   , "cdecl uint")
                        Return Pos
                    }
} ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -