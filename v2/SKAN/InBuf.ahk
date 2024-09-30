; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=132507
; Author: SKAN

InBuf(Haystack, TypeVal, StartingPos?, Occurrence?)        ;  InBuf() v0.49 by SKAN on D459/D78R @ autohotkey.com/r?t=132507
{
    If ( IsObject(Haystack) = 0  or  HasProp(HayStack, "Ptr") = 0  or  HasProp(HayStack, "Size") = 0  or Haystack.Size = 0 )
         Return ( InBuf.Status := "Invalid Haystack", 0 )

    If ( Type(Haystack) = "File" and Haystack.Handle = -1 )
         Return ( InBuf.Status := "Invalid File handle", 0 )

    If ( InStr(TypeVal, ":") = 0 )
         Return ( InBuf.Status := "Invalid Type:Value", 0 )

    Local  Val          :=  StrSplit(TypeVal, ":",, 2)
        ,  ValType      :=  StrLower( Trim( Val[1] ) )
        ,  ValType_     :=  ""
        ,  Value        :=  Val[2]
        ,  Buf          :=  Buffer(8, 0)
        ,  NullReplChr  :=  ""
        ,  Needle1      :=  Buffer(0)
        ,  Needle2      :=  Buffer(0)
        ,  Len          :=  0
        ,  Bytes        :=  0
        ,  IsUnicode    :=  0
        ,  Pos          :=  0

        ,  Translation  :=  Map(  "unicode","utf-16", "u","utf-16", "ansi","cp0", "a","cp0", "u8","utf-8"
                               ,  "u16","utf-16", "utf8","utf-8", "utf16","utf-16", "","Hex", "int8",1
                               ,  "int16",2, "int24",3, "int32",4, "int40",5, "int48",6, "int56",7
                               ,  "float?","float, double", "double?","double, float"
                               ,  "utf-8?","utf-8, utf-16", "utf-16?","utf-16, utf-8"  )

        ,  NumPutTypes  :=  Map(  "uint",4, "uint64",8, "int",4, "int64",8, "short",2, "ushort",2
                               ,  "char",1, "uchar",1, "double",8, "float",4, "ptr",A_PtrSize
                               ,  "uptr",A_PtrSize, "float, double",0, "double, float",0  )

    If ( StrLen(Value) = 0 )
         Return ( InBuf.Status := "Invalid value", 0 )

    If ( SubStr(ValType, -1) = "*" )
         ValType     :=  RTrim(ValType, "*")
       , NullReplChr :=  SubStr(Value, 1, 1)                       ;  ReplaceWithNulls() for StrPut & ByteRev() for NumPut()

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
               Try  NumPut("uint64", Value, Buf)
                 ,  Needle1  :=  Buffer(ValType)
                 ,  DllCall("Kernel32\RtlMoveMemory", "ptr",Needle1, "ptr",Buf, "ptr",ValType)
             Catch
                    Return ( InBuf.Status :=  "Invalid numerical value", 0 )
         }
         Else       Return ( InBuf.Status :=  "Invalid numerical type",  0 )

         If ( StrLen(NullReplChr) )
              Needle1 := ByteRev(Needle1)

         ValType := "int" (ValType * 8)
     }

    Else                                     ; Normal NumPut based search
    If  ( NumPutTypes.Has(ValType) )
    {
          Loop Parse, ValType, ",", A_Space
          {
                 Try   ValType_             :=  A_LoopField
                   ,   Needle%A_Index%      :=  Buffer( NumPutTypes[ValType_] )
                   ,   Needle%A_Index%.Type :=  ValType_
                   ,   NumPut(ValType_, Value, Needle%A_Index%)
               Catch
                       Return ( InBuf.Status :=  "Invalid numerical value", 0 )

               If ( StrLen(NullReplChr) )
                    Needle%A_Index% := ByteRev(Needle%A_Index%)
          }
    }

    Else                                     ; Hex based search
    If ( ValType = "Hex" )
    {
         Value    :=  StrReplace(Value, A_Space)
       , Len      :=  StrLen(Value)
       , Bytes    :=  Ceil(Len/2)
       , Needle1  :=  Buffer(Bytes)

         If ! DllCall("Crypt32\CryptStringToBinary", "str",Value, "int",Len, "int",0xC ;  CRYPT_STRING_HEXRAW := 0xC
                     ,"ptr",Needle1, "uintp",Bytes, "int",0, "int",0)
              Return ( InBuf.Status :=  "Invalid hex value", 0 )
    }

    Else                                     ; StrPut based text search
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
                        Return ( InBuf.Status :=  "Invalid text search", 0 )

                If ( StrLen(NullReplChr) )
                     ReplaceWithNulls(Needle%A_Index%, Ord(NullReplChr), IsUnicode ? "short" : "char")
          }     Until ( A_Index = 2 )
    }

    Pos := InBuffer(Haystack, Needle1, StartingPos?, Occurrence?)

    If ( Pos > 0 and Needle2.Size )
         ValType  := Needle1.Type

    If ( Pos = 0 and Needle2.Size )
    If ( Pos := InBuffer(Haystack, Needle2, StartingPos?, Occurrence?) )
         ValType := Needle2.Type

    Return ( InBuf.Status :=  StrTitle(ValType) A_Space (Pos ? "found" : "not found"), Pos )

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
} ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -