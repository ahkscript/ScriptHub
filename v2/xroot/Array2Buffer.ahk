; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=135564
; Author: xroot

#Requires AutoHotkey v2.0+

Class Array2Buffer{
/*   
    Parm1: Array Reference
    Parm2: Encoding = True =String Data with No DllCall 
                      False=String Data with a structure (like LOGFONT) with DllCall
*/
    __New(&iArr,Encoding:=True){
        this.iArr    := iArr     ;Your Data Array
        this.iType   := ["String","Integer","Float"]
        this.tSizes  := Map("uchar",1,"char",1,"ushort",2,"short",2,"uint",4,"int",4,"float",4,"int64",8,"double",8,"ptr",A_PtrSize,"uptr",A_PtrSize)
        this.bufSize := 0
        ;Get Buffer Size
        Loop this.iArr.Length{
            Switch Type(this.iArr[A_Index][1]){
                ;String 
                Case this.iType[1]:this.bufSize += StrLen(this.iArr[A_Index][1])+1
                ;Integer and Float    
                Case this.iType[2],this.iType[3]:this.bufSize += this.tSizes.Get(this.iArr[A_Index][2])
            }
        }
        this.iBuf      := Buffer(this.bufSize,0)                 ;Buffer to Use in your scripts
        this.bPtr      := this.iBuf.Ptr                          ;Ptr added to for BufPtrs
        this.Encoding  := (Encoding?A_FileEncoding:"UTF-16")     
        this.BufPtrs   := []                                     ;Addresses of all data in Buffer ibuf
        this.UpdateArr := (*)=>this.BufPtrs.Push(this.bPtr)      ;Array Update for BufPtrs
        ;Update the Buffer with your Data
        Loop this.iArr.Length{
            Switch Type(this.iArr[A_Index][1]){
                ;String 
                Case this.iType[1]:
                    this.UpdateArr
                    StrPut this.iArr[A_Index][1],this.BufPtrs[A_Index],this.Encoding 
                    this.bPtr += StrLen(this.iArr[A_Index][1])+1
                ;Integer and Float   
                Case this.iType[2],this.iType[3]:
                    this.UpdateArr
                    NumPut this.iArr[A_Index][2],this.iArr[A_Index][1],this.BufPtrs[A_Index]
                    this.bPtr += this.tSizes.Get(this.iArr[A_Index][2])
            }
        }
    } 
    Show_Buffer(){
        A_Clipboard := "Buffer Size = " this.bufSize "`n"
        Loop this.iArr.Length{
            Switch Type(this.iArr[A_Index][1]){
                ;String
                Case this.iType[1]:A_Clipboard .= Format("{}`nData Type={}`n Data={}`nPtr={}`n",A_Index,this.iType[1]
                                                 ,StrGet(this.BufPtrs[A_Index],this.Encoding),this.BufPtrs[A_Index])
                ;Integer and Float     
                Case this.iType[2],this.iType[3]:A_Clipboard .= Format("{}`nData Type={}`nData={}`nPtr={}`n",A_Index,this.iArr[A_Index][2]
                                                               ,NumGet(this.BufPtrs[A_Index],this.iArr[A_Index][2]),this.BufPtrs[A_Index])
            }
        }
        MsgBox A_Clipboard
    }
}