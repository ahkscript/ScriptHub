; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=120582
; Author: SKAN

PathX(Path, X*)             ; PathX() v0.67 by SKAN for ah2 on D34U/D68M @ autohotkey.com/r?p=120582
{
    Local  K,V,N,U, Dr,   Di,   Fn,   Ex
        ,  FPath := Dr := Di := Fn := Ex := Format("{:260}", "")

    U := Map(),  U.Default := "",  U.CaseSense := 0

    For  K, V  in  X
         N     :=  StrSplit(V, ":",, 2)  ;  split X into Key and Value
      ,  K     :=  SubStr(N[1], 1, 2)    ;  reduce Key to leading 2 chars
      ,  U[K]  :=  N[2]                  ;  assign Key and Value to Map

    DllCall("Kernel32\GetFullPathNameW", "str",Trim(Path,Chr(34)), "uint",260, "str",FPath, "ptr",0)
    DllCall("Msvcrt\_wsplitpath", "str",FPath, "str",Dr, "str",Di, "str",Fn, "str",Ex)

    Return {  Drive  :  Dr  :=  U["Dr"] ? U["Dr"] : Dr
           ,  Dir    :  Di  :=  U["dp"] ( U["Di"] ? U["Di"] : Di ) U["ds"]
           ,  Fname  :  Fn  :=  U["fp"] ( U["Fn"]!="" ? U["Fn"] : Fn )  U["fs"]
           ,  Ext    :  Ex  :=  U["*E"]!="" ? ( Ex ? Ex : U["*E"] ) : ( U["Ex"]!="" ? U["Ex"] : Ex )
           ,  Folder :  Dr Di
           ,  File   :  Fn Ex
           ,  Full   :  U["pp"] ( Dr Di Fn Ex ) U["ps"] }
}