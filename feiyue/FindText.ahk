; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=116471
; Author: feiyue

;/*
;===========================================
;  FindText - Capture screen image into text and then find it
;  https://www.autohotkey.com/boards/viewtopic.php?f=83&t=116471
;
;  Author  : FeiYue
;  Version : 9.2
;  Date    : 2023-10-01
;
;  Usage:  (required AHK v2.02)
;  1. Capture the image to text string.
;  2. Test find the text string on full Screen.
;  3. When test is successful, you may copy the code
;     and paste it into your own script.
;     Note: Copy the "FindText()" function and the following
;     functions and paste it into your own script Just once.
;  4. The more recommended way is to save the script as
;     "FindText.ahk" and copy it to the "Lib" subdirectory
;     of AHK program, instead of copying the "FindText()"
;     function and the following functions, add a line to
;     the beginning of your script: #Include <FindText>
;  5. If you want to call a method in the "FindTextClass" class,
;     use the parameterless FindText() to get the default object
;
;===========================================
;*/


if (!A_IsCompiled && A_LineFile=A_ScriptFullPath)
  FindText().Gui("Show")


;===== Copy The Following Functions To Your Own Code Just once =====


FindText(args*)
{
  static obj:=FindTextClass()
  return !args.Length ? obj : obj.FindText(args*)
}

Class FindTextClass
{  ;// Class Begin

Floor(i) => IsNumber(i) ? i+0 : 0

__New()
{
  this.bits:={ Scan0: 0, hBM: 0, oldzw: 0, oldzh: 0 }
  this.bind:={ id: 0, mode: 0, oldStyle: 0 }
  this.Lib:=Map()
  this.Cursor:=0
}

__Delete()
{
  if (this.bits.hBM)
    DllCall("DeleteObject", "Ptr",this.bits.hBM)
}

help()
{
return "
(
;--------------------------------
;  FindText - Capture screen image into text and then find it
;  Version : 9.2  (2023-10-01)
;--------------------------------
;  returnArray:=FindText(
;      &OutputX --> The name of the variable used to store the returned X coordinate
;    , &OutputY --> The name of the variable used to store the returned Y coordinate
;    , X1 --> the search scope's upper left corner X coordinates
;    , Y1 --> the search scope's upper left corner Y coordinates
;    , X2 --> the search scope's lower right corner X coordinates
;    , Y2 --> the search scope's lower right corner Y coordinates
;    , err1 --> Fault tolerance percentage of text       (0.1=10%)
;    , err0 --> Fault tolerance percentage of background (0.1=10%)
;    , Text --> can be a lot of text parsed into images, separated by '|'
;    , ScreenShot --> if the value is 0, the last screenshot will be used
;    , FindAll --> if the value is 0, Just find one result and return
;    , JoinText --> if you want to combine find, it can be 1, or an array of words to find
;    , offsetX --> Set the max text offset (X) for combination lookup
;    , offsetY --> Set the max text offset (Y) for combination lookup
;    , dir --> Nine directions for searching: up, down, left, right and center
;    , zoomW --> Zoom percentage of image width  (1.0=100%)
;    , zoomH --> Zoom percentage of image height (1.0=100%)
;  )
;
;  The function returns an Array containing all lookup results,
;  any result is a object with the following values:
;  {1:X, 2:Y, 3:W, 4:H, x:X+W//2, y:Y+H//2, id:Comment}
;  If no image is found, the function returns 0.
;  All coordinates are relative to Screen, colors are in RGB format
;
;  If the return variable is set to 'ok', ok[1] is the first result found.
;  ok[1].1, ok[1].2 is the X, Y coordinate of the upper left corner of the found image,
;  ok[1].3 is the width of the found image, and ok[1].4 is the height of the found image,
;  ok[1].x <==> ok[1].1+ok[1].3//2 ( is the Center X coordinate of the found image ),
;  ok[1].y <==> ok[1].2+ok[1].4//2 ( is the Center Y coordinate of the found image ),
;  ok[1].id is the comment text, which is included in the <> of its parameter.
;
;  If OutputX is equal to 'wait' or 'wait1'(appear), or 'wait0'(disappear)
;  it means using a loop to wait for the image to appear or disappear.
;  the OutputY is the wait time in seconds, time less than 0 means infinite waiting
;  Timeout means failure, return 0, and return other values means success
;  If you want to appear and the image is found, return the found array object
;  If you want to disappear and the image cannot be found, return 1
;  Example 1: FindText(&X:='wait', &Y:=3, 0,0,0,0,0,0,Text)   ; Wait 3 seconds for appear
;  Example 2: FindText(&X:='wait0', &Y:=-1, 0,0,0,0,0,0,Text) ; Wait indefinitely for disappear
;--------------------------------
)"
}

FindText(OutputX:="", OutputY:=""
  , x1:=0, y1:=0, x2:=0, y2:=0, err1:=0, err0:=0, text:=""
  , ScreenShot:=1, FindAll:=1, JoinText:=0, offsetX:=20, offsetY:=10
  , dir:=1, zoomW:=1, zoomH:=1)
{
  wait:=(OutputX is VarRef) && IsSetRef(OutputX) ? %OutputX% : OutputX
  if !IsObject(wait) && (wait ~= "i)^\s*wait[10]?\s*$")
  {
    time:=(OutputY is VarRef) && IsSetRef(OutputY) ? %OutputY% : OutputY
    found:=!InStr(wait,"0"), time:=this.Floor(time)
    , timeout:=A_TickCount+Round(time*1000)
    Loop
    {
      ok:=this.FindText(,, x1, y1, x2, y2, err1, err0, text, ScreenShot
        , FindAll, JoinText, offsetX, offsetY, dir, zoomW, zoomH)
      if (found && ok)
      {
        (OutputX is VarRef) && (%OutputX%:=ok[1].x)
        , (OutputY is VarRef) && (%OutputY%:=ok[1].y)
        return ok
      }
      if (!found && !ok)
        return 1
      if (time>=0 && A_TickCount>=timeout)
        Break
      Sleep 50
    }
    return 0
  }
  x1:=this.Floor(x1), y1:=this.Floor(y1), x2:=this.Floor(x2), y2:=this.Floor(y2)
  if (x1=0 && y1=0 && x2=0 && y2=0)
    n:=150000, x:=y:=-n, w:=h:=2*n
  else
    x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  bits:=this.GetBitsFromScreen(&x,&y,&w,&h,ScreenShot,&zx,&zy), x-=zx, y-=zy
  , this.ok:=0, info:=[]
  Loop Parse, text, "|"
    if IsObject(j:=this.PicInfo(A_LoopField))
      info.Push(j)
  if (w<1 || h<1 || !(num:=info.Length) || !bits.Scan0)
  {
    return 0
  }
  arr:=[], info2:=Map(), info2.Default:=[], k:=0, s:=""
  , mode:=(IsObject(JoinText) ? 2 : JoinText ? 1 : 0)
  For i,j in info
  {
    k:=Max(k, j[2]*j[3])
    if (mode)
      v:=(mode=2 ? j[10] : i) . "", s.="|" v
      , (!info2.Has(v) && info2[v]:=[]), (v!="" && info2[v].Push(j))
  }
  sx:=x, sy:=y, sw:=w, sh:=h
  , JoinText:=(mode=1 ? [s] : JoinText)
  , s1:=Buffer(k*4), s0:=Buffer(k*4)
  , ss:=Buffer(sw*(sh+2))
  , FindAll:=(dir=9 ? 1 : FindAll)
  , allpos_max:=(FindAll || JoinText ? 10240 : 1)
  , ini:={ sx:sx, sy:sy, sw:sw, sh:sh, zx:zx, zy:zy
  , mode:mode, bits:bits, ss:ss.Ptr, s1:s1.Ptr, s0:s0.Ptr
  , err1:err1, err0:err0, allpos_max:allpos_max
  , zoomW:zoomW, zoomH:zoomH }
  Loop 2
  {
    if (err1=0 && err0=0) && (num>1 || A_Index>1)
      ini.err1:=err1:=0.05, ini.err0:=err0:=0.05
    if (!JoinText)
    {
      allpos:=Buffer(allpos_max*4), allpos_ptr:=allpos.Ptr
      For i,j in info
      Loop this.PicFind(ini, j, dir, sx, sy, sw, sh, allpos_ptr)
      {
        pos:=NumGet(allpos, 4*(A_Index-1), "uint")
        , x:=(pos&0xFFFF)+zx, y:=(pos>>16)+zy
        , w:=Floor(j[2]*zoomW), h:=Floor(j[3]*zoomH), comment:=j[10]
        , arr.Push({1:x, 2:y, 3:w, 4:h, x:x+w//2, y:y+h//2, id:comment})
        if (!FindAll)
          Break 3
      }
    }
    else
    For k,v in JoinText
    {
      v:=StrSplit(Trim(RegExReplace(v, "\s*\|[|\s]*"
      , "|"), "|"), (InStr(v,"|")?"|":""), " `t")
      , this.JoinText(arr, ini, info2, v, 1, offsetX, offsetY
      , FindAll, dir, 0, 0, 0, sx, sy, sw, sh)
      if (!FindAll && arr.Length)
        Break 2
    }
    if (err1!=0 || err0!=0 || arr.Length || info[1][4] || info[1][7]=5)
      Break
  }
  if (dir=9 && arr.Length)
    arr:=this.Sort2(arr, (x1+x2)//2, (y1+y2)//2)
  if (arr.Length)
  {
    (OutputX is VarRef) && (%OutputX%:=arr[1].x)
    , (OutputY is VarRef) && (%OutputY%:=arr[1].y)
    , this.ok:=arr
    return arr
  }
  return 0
}

; the join text object <==> [ "abc", "xyz", "a1|a2|a3" ]

JoinText(arr, ini, info2, text, index, offsetX, offsetY
  , FindAll, dir, minX, minY, maxY, sx, sy, sw, sh)
{
  if !(Len:=text.Length)
    return 0
  allpos:=Buffer(ini.allpos_max*4), allpos_ptr:=allpos.Ptr
  , zoomW:=ini.zoomW, zoomH:=ini.zoomH, mode:=ini.mode
  For i,j in info2[text[index]]
  if (mode!=2 || text[index]==j[10])
  Loop this.PicFind(ini, j, dir, sx, sy, (index=1 ? sw
  : Min(sx+offsetX+Floor(j[2]*zoomW),ini.sx+ini.sw)-sx), sh, allpos_ptr)
  {
    pos:=NumGet(allpos, 4*(A_Index-1), "uint")
    , x:=pos&0xFFFF, y:=pos>>16
    , w:=Floor(j[2]*zoomW), h:=Floor(j[3]*zoomH)
    , (index=1 && (minX:=x, minY:=y, maxY:=y+h))
    , minY1:=Min(y, minY), maxY1:=Max(y+h, maxY), sx1:=x+w
    if (index<Len)
    {
      sy1:=Max(minY1-offsetY, ini.sy)
      , sh1:=Min(maxY1+offsetY, ini.sy+ini.sh)-sy1
      if this.JoinText(arr, ini, info2, text, index+1, offsetX, offsetY
      , FindAll, 5, minX, minY1, maxY1, sx1, sy1, 0, sh1)
      && (index>1 || !FindAll)
        return 1
    }
    else
    {
      comment:=""
      For k,v in text
        comment.=(mode=2 ? v : info2[v][1][10])
      x:=minX+ini.zx, y:=minY1+ini.zy, w:=sx1-minX, h:=maxY1-minY1
      , arr.Push({1:x, 2:y, 3:w, 4:h, x:x+w//2, y:y+h//2, id:comment})
      if (index>1 || !FindAll)
        return 1
    }
  }
  return 0
}

PicFind(ini, j, dir, sx, sy, sw, sh, allpos_ptr)
{
  static MyFunc:=""
  if (!MyFunc)
  {
    x32:=""
    . "5557565383EC7C83BC2490000000058BBC24C80000000F84010A00008B8424CC"
    . "00000085C00F8E8310000031C0896C241CC744240800000000C7442414000000"
    . "00C74424040000000089C5C7442418000000008B8424C40000008B4C241831F6"
    . "31DB01C885FF894424107F3BE98F0000000FAF8424B000000089C189F099F7FF"
    . "01C18B442410803C1831744D8B8424C000000083C30103B424E0000000890CA8"
    . "83C50139DF74558B44240899F7BC24CC00000083BC24900000000375B40FAF84"
    . "24A400000089C189F099F7FF8D0C818B442410803C183175B38B4424048B9424"
    . "BC00000083C30103B424E0000000890C8283C00139DF8944240475AB017C2418"
    . "83442414018B9C24E40000008B442414015C2408398424CC0000000F8532FFFF"
    . "FF8B442404BBAD8BDB68896C24100FAF8424D00000008B6C241C89C1F7EB89C8"
    . "8B4C24100FAF8C24D4000000C1F81F8944240889D6C1FE0C2B74240889C8C1F9"
    . "1FF7EB89742450C1FA0C29CA8954245883BC2490000000030F84D10A00008B84"
    . "24A40000008BB424A80000000FAF8424AC0000008D04B08BB424A40000008944"
    . "242C8B8424B0000000F7D88D0486894424248B84249000000085C00F855D0300"
    . "008B842494000000C744242000000000C744242800000000C1E8100FB6C08944"
    . "24148B8424940000000FB6C4894424180FB68424940000008944241C8B8424B0"
    . "000000C1E002894424308B8424B400000085C00F8EB90000008B44242C8BBC24"
    . "B000000085FF0F8E8C0000008BB424A00000008B7C242803BC24B800000001C6"
    . "034424308944242C038424A0000000894424080FB66E028B4C24140FB646010F"
    . "B6162B4424182B54241C89EB01CD29CB8D8D000400000FAFC00FAFCBC1E00B0F"
    . "AFCB01C1B8FE05000029E80FAFC20FAFD001CA399424980000000F930783C604"
    . "83C7013B74240875AA8B9C24B0000000015C24288B44242C8344242001034424"
    . "248B74242039B424B40000000F854BFFFFFF8B7424048B5C2450B80000000039"
    . "DE89C30F4FDE8B74245839742410895C24040F8E360900008B7424048B442410"
    . "39C60F4DC6894424708B84249000000083E80383E0FD0F849E0600008B8424B0"
    . "0000002B8424E0000000C744246000000000C744246C00000000894424648B84"
    . "24B40000002B8424E4000000894424448B84249C00000083E80183F8070F871A"
    . "06000083F8038944244C0F8E150600008B44246C8B742460894424608974246C"
    . "8B742464397424600F8F450D00008B4424648B742404C744243400000000896C"
    . "2408894424688B8424BC0000008D04B08B74244C8944245C89F083E001894424"
    . "5489F08BB424A000000083E003894424748B44246C8B5C244439D80F8F170100"
    . "00837C2474018B7C24600F4F7C2468895C243889442428897C24488B7C247090"
    . "8B4C24548B44243885C90F44442428837C244C038944242C0F8F8602000083BC"
    . "2490000000058B442448894424308B4424300F848E02000083BC249000000003"
    . "0F84CA0300000FAF8424B00000000344242C85FF89C2894424200F8474030000"
    . "8B6C24588B5C245031C0039424B80000008B4C24048974241C896C2418895C24"
    . "148B6C2410EB1489F68DBC270000000083C00139C70F843503000039C873188B"
    . "9C24BC0000008B348301D6803E007507836C241401781C39C576D58B9C24C000"
    . "00008B348301D6803E0175C4836C24180179BD8B74241C89F68DBC2700000000"
    . "8344242801836C2438018B442428394424440F8D08FFFFFF8344246001836C24"
    . "68018B442460394424640F8DC1FEFFFF8B44243483C47C5B5E5F5DC2580083BC"
    . "2490000000010F84A90A000083BC2490000000020F84460800008B8424940000"
    . "000FB6BC2494000000C744241C00000000C744243000000000C1E8100FB6D08B"
    . "842494000000895424080FB69424980000000FB6DC8B842498000000C1E8100F"
    . "B6C88B8424980000000FB6F48B44240829C8034C24088944243889D829F001DE"
    . "8944241489D089FA29C201F889742418894424288BB424B40000008B8424B000"
    . "000089542420894C2408C1E00285F6894424340F8EF9FCFFFF896C243C8B4C24"
    . "2C8B6C24388B9C24B000000085DB0F8E8D0000008B8424A00000008B54243003"
    . "9424B800000001C8034C243489CF894C242C03BC24A0000000EB39908D742600"
    . "395C24087C3D394C24147F37394C24187C3189F30FB6F3397424200F9EC33974"
    . "24280F9DC183C00483C20121D9884AFF39F8741E0FB658020FB648010FB63039"
    . "DD7EBD31C983C00483C201884AFF39F875E28BB424B0000000017424308B4C24"
    . "2C8344241C01034C24248B44241C398424B40000000F854AFFFFFF8B6C243CE9"
    . "2EFCFFFF8B44242C83BC249000000005894424308B4424488944242C8B442430"
    . "0F8572FDFFFF0FAF8424A40000008B5C242C85FF8D0498894424180F848C0000"
    . "008B6C245031C9897C2414908D7426008B8424BC0000008B5C2418031C888B84"
    . "24C00000008B3C880FB6441E0289FAC1EA100FB6D229D00FB6541E010FB61C1E"
    . "0FAFC03B4424087F2789F80FB6C429C20FAFD23B5424087F1789F80FB6C029C3"
    . "0FAFDB3B5C24087E108DB4260000000083ED010F880702000083C101394C2414"
    . "758E89BC24940000008B7C24148B8424D800000083442434018B5C243485C00F"
    . "845BFDFFFF8B542430039424AC0000008B44242C038424A80000008B8C24D800"
    . "0000C1E21009D03B9C24DC000000894499FC0F8C28FDFFFF8B44243483C47C5B"
    . "5E5F5DC258008D76008DBC27000000008B74241C8B54240485D274918B9C24B8"
    . "0000008B4C24208B8424BC00000001D98B5C245C8B1083C00401CA39D8C60200"
    . "75F2E966FFFFFF89F68DBC27000000000FAF8424A40000008B5C242C8D049889"
    . "4424180384249400000085FF0FB65C0602895C241C0FB65C06010FB60406895C"
    . "2420894424240F8421FFFFFF8B44245831DB897C2414894424408B4424508944"
    . "243C8B4424088D76008DBC27000000003B5C240473658B8424BC0000008B4C24"
    . "188B7C241C030C980FB6440E020FB6540E010FB60C0E2B5424202B4C242489C5"
    . "01F829FD8DB8000400000FAFD20FAFFDC1E20B0FAFFDBDFE05000029C50FAFE9"
    . "01FA0FAFCD01D13B8C2498000000760B836C243C010F8895000000395C241076"
    . "618B8424C00000008B4C24188B7C241C030C980FB6440E020FB6540E010FB60C"
    . "0E2B5424202B4C242489C501F829FD8DB8000400000FAFD20FAFFDC1E20B0FAF"
    . "FDBDFE05000029C50FAFE901FA0FAFCD01D13B8C24980000007707836C244001"
    . "782E83C301395C24140F8521FFFFFF894424088B7C2414E911FEFFFF8D742600"
    . "89BC24940000008B7C2414E970FBFFFF894424088B7C2414E963FBFFFFC74424"
    . "4C000000008B4424448B7424648944246489742444E9E6F9FFFFC74424700000"
    . "0000C744245800000000C744240400000000C7442410000000008B8424B00000"
    . "00038424A80000002B8424E0000000894424648B8424AC000000038424B40000"
    . "002B8424E4000000894424448B8424AC000000C78424AC000000000000008944"
    . "24608B8424A8000000C78424A8000000000000008944246CE933F9FFFF8BAC24"
    . "940000008B8424980000000FAFED85C00F845F0200008B9424CC0000008BB424"
    . "CC00000083AC2498000000010FAFD7C1E20285F60F8E860600008BB424C40000"
    . "008D04BD0000000089BC24C800000089EF8BAC2494000000C744242800000000"
    . "89442434C744242C0000000031C001D6C744240400000000897424088BB42498"
    . "0000008B9C24C800000085DB0F8E1D0100008B8C24C40000008B5C2408896C24"
    . "20C74424180000000089F501C103442434894C241489442430038424C4000000"
    . "894424248B44241485ED0FB650010FB670020FB6008954240889442410744131"
    . "D28B0C9389C8C1E8100FB6C029F00FAFC039C77C200FB6C52B4424080FAFC039"
    . "C77C120FB6C12B4424100FAFC039C70F8D8B04000083C20139D575C5894C2420"
    . "8B442404C1E610C1E0028944241C8B44242899F7BC24CC0000000FAF8424A400"
    . "000089C18B44241899F7BC24C80000008B5424048D04818B8C24BC0000008904"
    . "918B44240883C2018B8C24C000000089542404C1E00809C60B7424108B44241C"
    . "89340183442414048B9424E00000008B442414015424183B4424240F8523FFFF"
    . "FF89EE8B4424308B6C2420895C24088344242C018B9C24E40000008B4C242C01"
    . "5C2428398C24CC0000000F85B3FEFFFF89AC249400000089FD8B7424048B8C24"
    . "D0000000BAAD8BDB680FAFCE89C8C1F91FF7EAC1FA0C89D029C839F089442450"
    . "0F8D74FDFFFFC7442458000000008B742404B800000000C74424100000000089"
    . "C385F60F49DE895C2470E9BAF6FFFF8B842494000000C1E8100FAF8424E40000"
    . "0099F7BC24CC0000000FAF8424A400000089C10FB78424940000000FAF8424E0"
    . "00000099F7FF8D048189842494000000E93DF6FFFF8BB424C4000000C7442408"
    . "00000000C744240C00000000C744240400000000EB216B5C240C0AB80A000000"
    . "F764240801DA31DB01C111D3894C2408895C240C83C6010FB60685C00F8417FF"
    . "FFFF8D48D083F90976CC83F82F75E58B54240C8B4424088B5C2404C744240C00"
    . "0000000FACD01831D28D0C9D0000000089842494000000F7F70FAF8424E40000"
    . "008954241099F7BC24CC0000008B5424100FAF9424E00000000FAF8424A40000"
    . "0089C389D099F7FF8B9424BC0000008D04838B5C240489049A83C3018B442408"
    . "895C24048B9C24C0000000C74424080000000025FFFFFF0089040BE954FFFFFF"
    . "8BB424B00000008B8424B80000008B8C24B4000000C744240800000000C74424"
    . "14000000008D04708944242889F0C1E00285C9894424188B44242C0F8E11F5FF"
    . "FF8B9424B000000085D27E608B8C24A00000008B5C2428035C241401C1034424"
    . "188944241C038424A000000089C766900FB651020FB6410183C1040FB671FC83"
    . "C3016BC04B6BD22601C289F0C1E00429F001D0C1F8078843FF39CF75D38B9C24"
    . "B0000000015C24148B44241C8344240801034424248B74240839B424B4000000"
    . "0F857BFFFFFF8B8424B0000000C74424180000000031FF896C242C83E8018944"
    . "24208B8424B400000083E801894424248B8424B000000085C00F8E190100008B"
    . "6C241889FB8B4424288BB424B00000008D4F0185ED8BAC24B80000008D14380F"
    . "9444241C2B9C24B000000001FE01C601EF897C241401C331C0895C24088D7600"
    . "85C00F8401010000807C241C000F85F6000000394424200F84EC0000008B7C24"
    . "18397C24240F84DE0000000FB63A0FB66AFF03BC249400000089BC2498000000"
    . "39AC2498000000BF0100000072600FB66A0139AC249800000072538B5C24080F"
    . "B62B39AC249800000072430FB62E39AC249800000072370FB66BFF39AC249800"
    . "0000722A0FB66B0139AC2498000000721D0FB66EFF39AC249800000072100FB6"
    . "7E0139BC24980000000F92C389DF8B6C241489FB89CF885C050083C00183C101"
    . "83C20183C6018344240801398424B00000000F8528FFFFFF83442418018B4424"
    . "18398424B40000000F85C2FEFFFF8B6C242CE91BF3FFFF89F68DBC2700000000"
    . "894C2420E9DAFBFFFF8B5C241489CFC6040302EBA58B8424940000008BB424B4"
    . "000000C744240800000000C74424140000000083C001C1E00789842494000000"
    . "8B8424B0000000C1E00285F6894424180F8EBCF2FFFF896C24208B44242C8BAC"
    . "24940000008B9C24B000000085DB7E5F8B8C24A00000008B5C2414039C24B800"
    . "000001C1034424188944241C038424A000000089C70FB651020FB641010FB631"
    . "6BC04B6BD22601C289F0C1E00429F001D039C50F970383C10483C30139F975D5"
    . "8B9C24B0000000015C24148B44241C8344240801034424248B74240839B424B4"
    . "00000075808B6C2420E924F2FFFFC744245800000000C744245000000000C744"
    . "241000000000C744240400000000E99DF0FFFFC744243400000000E930F4FFFF"
    . "C744245800000000C744240400000000C744245000000000E931FBFFFF909090"
    x64:=""
    . "4157415641554154555756534883EC78488BBC24E00000004C8BA42410010000"
    . "83F905898C24C000000089D3448944240444898C24D80000004C8BAC24200100"
    . "004C8BBC24280100008BB424300100000F84BF090000448B8424380100004585"
    . "C00F8E8C0F000044897424084C89A424100100004531D2448BA424C00000008B"
    . "9C24380100004531DB448BB42460010000C704240000000031ED4531C0899424"
    . "C80000004889BC24E00000000F1F40004531C985F6428D3C067F38EB7C0F1F00"
    . "0FAF84240001000089C14489C899F7FE01C143803C0731418D400174404963D3"
    . "4501F14183C30139F841894C95004189C074464489D099F7FB4183FC0375C10F"
    . "AF8424E800000089C14489C899F7FE43803C07318D0C81418D400175C04C8B84"
    . "24180100004863D54501F183C50139F841890C904189C075BA83042401440394"
    . "24680100008B042439C30F8560FFFFFF8B8C244001000041B8AD8BDB68448B74"
    . "24088B9C24C8000000488BBC24E00000004C8BA424100100000FAFCD89C8C1F9"
    . "1F4189CA8B8C244801000041F7E8410FAFCBC1FA0C4189D14529D189C8C1F91F"
    . "44894C243041F7E8C1FA0C29CA8954245883BC24C0000000030F843E0A00008B"
    . "8424E80000008BB424F00000000FAF8424F80000008D04B08BB424E800000089"
    . "04248B842400010000F7D88D04868944240C8B8424C000000085C00F855D0300"
    . "0089D8C1E8100FB6F00FB6C789C10FB6C389C28B84240801000085C00F8E0501"
    . "00008B842400010000448B7C24044531D2896C24144C89AC242001000089CDC7"
    . "4424080000000044895C24184189D5C1E002899C24C8000000894424108B9C24"
    . "000100008B842400010000448B0C244401D385C07E7C662E0F1F840000000000"
    . "418D41024489CA4489D10FB61417440FB63407418D41010FB604074429EA4589"
    . "F04101F64189D3418D96000400004129F029E8410FAFD00FAFC0410FAFD0C1E0"
    . "0B8D0402BAFE0500004429F2410FAFD3410FAFD301D04139C7410F93040C4183"
    . "C2014183C1044139DA75958B5C2410011C2483442408018B4C240C8B44240801"
    . "0C24398424080100000F854EFFFFFF8B6C2414448B5C24188B9C24C80000004C"
    . "8BAC24200100003B6C2430B8000000000F4EE8443B5C24580F8EAB0800004439"
    . "DD4489DE0F4DF58B8424C000000083E80383E0FD0F84580600008B8424000100"
    . "002B842460010000C744245C00000000C744246800000000894424608B842408"
    . "0100002B842468010000894424248B8424D800000083E80183F8070F87E50500"
    . "0083F8038944242C0F8EE00500008B4424688B4C245C8944245C894C24688B4C"
    . "2460394C245C0F8F410C00008B442460488B8C2418010000899C24C80000004C"
    . "89EB4189EDC744241400000000894424648D45FF4489DD4D89E34189F4488BB4"
    . "2418010000488D4481048B4C242C488944243889C883E0018944243489C883E0"
    . "038944246C8B4424688B4C242439C80F8FFC000000837C246C018B54245C0F4F"
    . "54246448899C24200100004889F3488BB42420010000894C2418894424088954"
    . "24288B44243485C08B4424180F44442408837C242C038944240C0F8F60020000"
    . "83BC24C0000000058B442428894424100F846802000083BC24C0000000030F84"
    . "600300008B4C24100FAF8C2400010000034C240C4585E40F8426030000448B54"
    . "2458448B4C243031C0EB120F1F4400004883C0014139C40F86060300004439E8"
    . "89C273144189C84403048343803C030075064183E901781839D576D489CA0314"
    . "8641803C130175C84183EA0179C266908344240801836C2418018B4424083944"
    . "24240F8D3AFFFFFF4889F04889DE4889C38344245C01836C2464018B44245C39"
    . "4424600F8DDCFEFFFF8B4424144883C4785B5E5F5D415C415D415E415FC383BC"
    . "24C0000000010F84DA09000083BC24C0000000020F84E70600008B74240489D8"
    . "0FB6CFC1E8104189C9440FB6FB440FB6D089F0440FB6C6C1E8100FB6D04889F0"
    . "4489D60FB6C429D689C14489C88974241829C84489FE4529C78944241C4489C0"
    . "448B84240801000001F044897C24084401C9894424108B842400010000458D3C"
    . "124531D231D2C1E0024585C0894424140F8E31FDFFFF896C2424899C24C80000"
    . "008B2C248B74241C8B5C241844897424204189CE4C89AC242001000044895C24"
    . "284589D5448B9C24000100008B8C240001000089E84101D385C97F36EB6A6690"
    . "4539CF7C4E4439C67F494539C67C444439542408410F9EC14439542410410F9D"
    . "C083C20183C0044521C84139D344880174328D4802440FB60C0F8D4801440FB6"
    . "040F89C1440FB6140F89D14C01E14439CB7EAD83C2014531C083C0044139D344"
    . "880175CE036C24144183C501036C240C4439AC24080100000F8566FFFFFF448B"
    . "7424208B6C2424448B5C24288B9C24C80000004C8BAC2420010000E947FCFFFF"
    . "8B44240C83BC24C000000005894424108B4424288944240C0F8598FDFFFF8B44"
    . "24108B4C240C0FAF8424E80000004585E4448D14887476448B4C24304531C049"
    . "89DF4489D243031487428B1C8689D98D4202C1E9100FB6C90FB6040729C88D4A"
    . "010FB614170FAFC00FB60C0F4439F07F1F0FB6C729C10FAFC94439F17F120FB6"
    . "C329C20FAFD24439F27E0F0F1F4400004183E9010F88E90100004983C0014539"
    . "C4779F899C24C80000004C89FB83442414014883BC245001000000448B4C2414"
    . "0F846AFDFFFF8B542410039424F80000004963C18B4C240C038C24F0000000C1"
    . "E21009CA443B8C2458010000488B8C2450010000895481FC0F8C32FDFFFFE966"
    . "FDFFFF4585ED74A54C8B4424384889D889CA03104883C0044C39C041C6041300"
    . "75EEEB898B4424108B4C240C0FAF8424E80000008D04884189C7038424C80000"
    . "004585E48D50020FB60C178D50010FB604070FB614178914240F844EFFFFFF8B"
    . "5424584989D94C895C244048895C24484989F24531C04589FB89C34889742450"
    . "895424208B5424308954241C0F1F40004539E873624489DA4103118D4202440F"
    . "B634078D42010FB614170FB604072B04244589F74101CE29DA418DB600040000"
    . "4129CF410FAFF70FAFC0410FAFF741BFFE050000C1E00B4529F7440FAFFA01F0"
    . "410FAFD701C23B542404760B836C241C010F889B0000004439C5765E4489DA41"
    . "03128D4202440FB634078D42010FB614170FB604072B04244589F74101CE29DA"
    . "418DB6000400004129CF410FAFF70FAFC0410FAFF741BFFE050000C1E00B4529"
    . "F7440FAFFA01F0410FAFD701C23B5424047707836C24200178384183C0014983"
    . "C2044983C1044539C40F8521FFFFFF4C8B5C2440488B5C2448488B742450E92A"
    . "FEFFFF899C24C80000004C89FBE99EFBFFFF4C8B5C2440488B5C2448488B7424"
    . "50E98AFBFFFFC744242C000000008B4424248B4C246089442460894C2424E91B"
    . "FAFFFF31F6C74424580000000031ED4531DB8B842400010000038424F0000000"
    . "2B842460010000894424608B8424F8000000038424080100002B842468010000"
    . "894424248B8424F8000000C78424F8000000000000008944245C8B8424F00000"
    . "00C78424F00000000000000089442468E979F9FFFF8B4C24044189D6440FAFF2"
    . "85C90F840A0200008B8424380100008B942438010000836C2404010FAFC6C1E0"
    . "0285D248980F8ECF0500004D8D1407448B5C24048D04B500000000C744240800"
    . "000000C744240C0000000031EDC744241000000000894424144889BC24E00000"
    . "004C89A424100100004C89AC242001000089B424300100008B84243001000031"
    . "FF4531E48B74241085C00F8ED10000008D46024585DB410FB60C078D4601450F"
    . "B6040789F0450FB60C07743F31D26690418B1C9289D8C1E8100FB6C029C80FAF"
    . "C04139C67C1C0FB6C74429C00FAFC04139C67C0E0FB6C34429C80FAFC04139C6"
    . "7D5B4883C2014139D377C58B4424084C63EDC1E11041C1E00883C5014409C199"
    . "4409C9F7BC24380100000FAF8424E800000089042489F899F7BC24300100008B"
    . "14248D0482488B942418010000428904AA488B84242001000042890CA84183C4"
    . "0183C60403BC24600100004439A424300100000F8537FFFFFF8B7C2414017C24"
    . "108344240C018BB424680100008B44240C01742408398424380100000F85F6FE"
    . "FFFF488BBC24E00000004C8BA424100100004C8BAC24200100008B8C24400100"
    . "00BAAD8BDB680FAFCD89C8C1F91FF7EAC1FA0C29CA39EA895424300F8DC2FDFF"
    . "FFC74424580000000085EDB8000000000F49C54531DB89C6E94AF7FFFF89D8C1"
    . "E8100FAF84246801000099F7BC24380100000FAF8424E800000089C10FB7C30F"
    . "AF84246001000099F7FE8D1C81E9F5F6FFFF4531DB31ED31C08D4801410FB604"
    . "0785C00F8471FFFFFF8D50D083FA090F87820200004B8D049B4C8D1C4289C8EB"
    . "D88B842400010000448B9424080100004531C0C74424080000000001C048984D"
    . "8D3C048B842400010000C1E0024585D2894424100F8E8DF6FFFF8BB424000100"
    . "00448B8C24000100008B0C244401C64585C97E498D41024489C24183C001440F"
    . "B60C078D41010FB60407456BC9266BC04B4101C189C883C104440FB614074489"
    . "D0C1E0044429D04401C8C1F8074139F04188041775BE8B742410013424834424"
    . "08018B4C240C8B442408010C243984240801000075848B8424000100008B4C24"
    . "0431D2448B8C24000100004889BC24E000000031F64489742418896C241C89D7"
    . "83E80144895C24204C89AC24200100008904248B84240801000083E801894424"
    . "088B842400010000F7D0894424144585C90F8E0E01000085FF89F2468D2C0E40"
    . "0F94C54429CA448D76FF895424048B54241441B80100000031C001F28954240C"
    . "8B142401F2895424100F1F800000000085C08D14060F84050100004084ED0F85"
    . "FC0000003904240F84F3000000397C24080F84E9000000458D1406410FB60C17"
    . "4C01E2470FB61C1741BA0100000001D94439D9727A468D1C06470FB61C1F4439"
    . "D9726C448B5C24044101C3470FB61C1F4439D9725A468D1C28470FB61C1F4439"
    . "D9724C448B5C240C4101C3470FB61C1F4439D9723A448B5C24044501C3470FB6"
    . "1C1F4439D97228448B5424104101C2470FB61C1741BA010000004439D9721047"
    . "8D1428470FB614174439D1410F92C283C0014183C0014488124139C10F852EFF"
    . "FFFF4489EE83C70139BC24080100000F85D9FEFFFF448B7424188B6C241C448B"
    . "5C2420894C2404488BBC24E00000004C8BAC2420010000E96BF4FFFF0F1F4000"
    . "83C0014183C00141C60414024139C10F85DBFEFFFFEBAB83F82F0F857DFDFFFF"
    . "4C89D831D24C63CD48C1E8184181E3FFFFFF0083C5014889C3F7F60FAF842468"
    . "0100004189D299F7BC24380100000FAF8424E80000004189C08B842460010000"
    . "410FAFC299F7FE488B942418010000418D04804289048A47895C8D0089C84531"
    . "DBE9F3FCFFFF8D43014531FF4531C0C1E00789C38B842400010000C1E0028944"
    . "24088B84240801000085C00F8EB6F3FFFF8BB424000100008B8424000100008B"
    . "0C244401C685C07E500F1F80000000008D41024489C2440FB60C078D41010FB6"
    . "0407456BC9266BC04B4101C189C8440FB614074489D0C1E0044429D04401C839"
    . "C3410F9704144183C00183C1044439C675BE8B7424080134244183C7018B7424"
    . "0C0134244439BC24080100007583E934F3FFFFC744245800000000C744243000"
    . "0000004531DB31EDE9A4F1FFFFC744241400000000E92FF5FFFFC74424580000"
    . "000031EDC744243000000000E9B8FBFFFF909090909090909090909090909090"
    this.MCode(&MyFunc, A_PtrSize=8 ? x64:x32)
  }
  text:=j[1], w:=j[2], h:=j[3]
  , err1:=this.Floor(j[4] ? j[5] : ini.err1)
  , err0:=this.Floor(j[4] ? j[6] : ini.err0)
  , mode:=j[7], color:=j[8], n:=j[9]
  return (!ini.bits.Scan0) ? 0 : DllCall(MyFunc.Ptr
    , "int",mode, "uint",color, "uint",n, "int",dir
    , "Ptr",ini.bits.Scan0, "int",ini.bits.Stride
    , "int",sx, "int",sy, "int",sw, "int",sh
    , "Ptr",ini.ss, "Ptr",ini.s1, "Ptr",ini.s0
    , (mode=5 && n>0 ? "Ptr":"AStr"),text, "int",w, "int",h
    , "int",Floor(err1*10000), "int",Floor(err0*10000)
    , "Ptr",allpos_ptr, "int",ini.allpos_max
    , "int",Floor(w*ini.zoomW), "int",Floor(h*ini.zoomH))
}

code()
{
return "
(

//***** C source code of machine code *****

int __attribute__((__stdcall__)) PicFind(
  int mode, unsigned int c, unsigned int n, int dir
  , unsigned char * Bmp, int Stride
  , int sx, int sy, int sw, int sh
  , unsigned char * ss, unsigned int * s1, unsigned int * s0
  , unsigned char * text, int w, int h, int err1, int err0
  , unsigned int * allpos, int allpos_max
  , int new_w, int new_h )
{
  unsigned int o, i, j;
  int ok, v, e1, e0, len1, len0, max;
  int x, y, x1, y1, x2, y2, x3, y3, r, g, b, rr, gg, bb;
  int r_min, r_max, g_min, g_max, b_min, b_max;
  unsigned char * gs;
  unsigned int * trans;
  unsigned long long sum;
  ok=0; o=0; len1=0; len0=0;
  //----------------------
  // MultiColor or PixelSearch or ImageSearch Mode
  if (mode==5)
  {
    v=c*c;
    if (n>0)
    {
      trans=(unsigned int *)(text+w*h*4); n--;
      for (y=0; y<h; y++)
      {
        for (x=0; x<w; x++, o+=4)
        {
          rr=text[2+o]; gg=text[1+o]; bb=text[o];
          for (i=0; i<n; i++)
          {
            c=trans[i]; r=((c>>16)&0xFF)-rr;
            g=((c>>8)&0xFF)-gg; b=(c&0xFF)-bb;
            if (r*r<=v && g*g<=v && b*b<=v) goto NoMatch1;
          }
          s1[len1]=(y*new_h/h)*Stride+(x*new_w/w)*4;
          s0[len1++]=(rr<<16)|(gg<<8)|bb;
          NoMatch1:;
        }
      }
    }
    else
    {
      for (sum=0; (j=text[o++])!='\0';)
      {
        if (j>='0' && j<='9')
          sum = sum*10 + (j-'0');
        else if (j=='/')
        {
          c=sum>>24; y=c/w; x=c%w;
          s1[len1]=(y*new_h/h)*Stride+(x*new_w/w)*4;
          s0[len1++]=sum&0xFFFFFF; sum=0;
        }
      }
    }
    goto StartLookUp;
  }
  //----------------------
  // Generate Lookup Table
  for (y=0; y<h; y++)
  {
    for (x=0; x<w; x++)
    {
      if (mode==3)
        i=(y*new_h/h)*Stride+(x*new_w/w)*4;
      else
        i=(y*new_h/h)*sw+(x*new_w/w);
      if (text[o++]=='1')
        s1[len1++]=i;
      else
        s0[len0++]=i;
    }
  }
  //----------------------
  // Color Position Mode
  // only used to recognize multicolored Verification Code
  if (mode==3)
  {
    y=c>>16; x=c&0xFFFF;
    c=(y*new_h/h)*Stride+(x*new_w/w)*4;
    goto StartLookUp;
  }
  //----------------------
  // Generate Two Value Image
  o=sy*Stride+sx*4; j=Stride-sw*4; i=0;
  if (mode==0)  // Color Mode
  {
    rr=(c>>16)&0xFF; gg=(c>>8)&0xFF; bb=c&0xFF;
    for (y=0; y<sh; y++, o+=j)
      for (x=0; x<sw; x++, o+=4, i++)
      {
        r=Bmp[2+o]-rr; g=Bmp[1+o]-gg; b=Bmp[o]-bb; v=r+rr+rr;
        ss[i]=((1024+v)*r*r+2048*g*g+(1534-v)*b*b<=n) ? 1:0;
      }
  }
  else if (mode==1)  // Gray Threshold Mode
  {
    c=(c+1)<<7;
    for (y=0; y<sh; y++, o+=j)
      for (x=0; x<sw; x++, o+=4, i++)
        ss[i]=(Bmp[2+o]*38+Bmp[1+o]*75+Bmp[o]*15<c) ? 1:0;
  }
  else if (mode==2)  // Gray Difference Mode
  {
    gs=ss+sw*2;
    for (y=0; y<sh; y++, o+=j)
    {
      for (x=0; x<sw; x++, o+=4, i++)
        gs[i]=(Bmp[2+o]*38+Bmp[1+o]*75+Bmp[o]*15)>>7;
    }
    for (i=0, y=0; y<sh; y++)
      for (x=0; x<sw; x++, i++)
      {
        if (x==0 || y==0 || x==sw-1 || y==sh-1)
          ss[i]=2;
        else
        {
          n=gs[i]+c;
          ss[i]=(gs[i-1]>n || gs[i+1]>n
          || gs[i-sw]>n   || gs[i+sw]>n
          || gs[i-sw-1]>n || gs[i-sw+1]>n
          || gs[i+sw-1]>n || gs[i+sw+1]>n) ? 1:0;
        }
      }
  }
  else  // (mode==4) Color Difference Mode
  {
    r=(c>>16)&0xFF; g=(c>>8)&0xFF; b=c&0xFF;
    rr=(n>>16)&0xFF; gg=(n>>8)&0xFF; bb=n&0xFF;
    r_min=r-rr; g_min=g-gg; b_min=b-bb;
    r_max=r+rr; g_max=g+gg; b_max=b+bb;
    for (y=0; y<sh; y++, o+=j)
      for (x=0; x<sw; x++, o+=4, i++)
      {
        r=Bmp[2+o]; g=Bmp[1+o]; b=Bmp[o];
        ss[i]=(r>=r_min && r<=r_max
            && g>=g_min && g<=g_max
            && b>=b_min && b<=b_max) ? 1:0;
      }
  }
  //----------------------
  StartLookUp:
  err1=len1*err1/10000;
  err0=len0*err0/10000;
  if (err1>=len1) len1=0;
  if (err0>=len0) len0=0;
  max=(len1>len0) ? len1 : len0;
  if (mode==5 || mode==3)
  {
    x1=sx; y1=sy; x2=sx+sw-new_w; y2=sy+sh-new_h; sx=0; sy=0;
  }
  else
  {
    x1=0; y1=0; x2=sw-new_w; y2=sh-new_h;
  }
  // 1 ==> ( Left to Right ) Top to Bottom
  // 2 ==> ( Right to Left ) Top to Bottom
  // 3 ==> ( Left to Right ) Bottom to Top
  // 4 ==> ( Right to Left ) Bottom to Top
  // 5 ==> ( Top to Bottom ) Left to Right
  // 6 ==> ( Bottom to Top ) Left to Right
  // 7 ==> ( Top to Bottom ) Right to Left
  // 8 ==> ( Bottom to Top ) Right to Left
  if (dir<1 || dir>8) dir=1;
  if (--dir>3) { r=y1; y1=x1; x1=r; r=y2; y2=x2; x2=r; }
  for (y3=y1; y3<=y2; y3++)
  {
    for (x3=x1; x3<=x2; x3++)
    {
      y=((dir&3)>1) ? y1+y2-y3 : y3;
      x=(dir&1) ? x1+x2-x3 : x3;
      if (dir>3) { r=y; y=x; x=r; }
      //----------------------
      e1=err1; e0=err0;
      if (mode==5)
      {
        o=y*Stride+x*4;
        for (i=0; i<max; i++)
        {
          j=o+s1[i]; c=s0[i]; r=Bmp[2+j]-((c>>16)&0xFF);
          g=Bmp[1+j]-((c>>8)&0xFF); b=Bmp[j]-(c&0xFF);
          if ((r*r>v || g*g>v || b*b>v) && (--e1)<0) goto NoMatch;
        }
      }
      else if (mode==3)
      {
        o=y*Stride+x*4;
        j=o+c; rr=Bmp[2+j]; gg=Bmp[1+j]; bb=Bmp[j];
        for (i=0; i<max; i++)
        {
          if (i<len1)
          {
            j=o+s1[i]; r=Bmp[2+j]-rr; g=Bmp[1+j]-gg; b=Bmp[j]-bb; v=r+rr+rr;
            if ((1024+v)*r*r+2048*g*g+(1534-v)*b*b>n && (--e1)<0) goto NoMatch;
          }
          if (i<len0)
          {
            j=o+s0[i]; r=Bmp[2+j]-rr; g=Bmp[1+j]-gg; b=Bmp[j]-bb; v=r+rr+rr;
            if ((1024+v)*r*r+2048*g*g+(1534-v)*b*b<=n && (--e0)<0) goto NoMatch;
          }
        }
      }
      else
      {
        o=y*sw+x;
        for (i=0; i<max; i++)
        {
          if (i<len1 && ss[o+s1[i]]==0 && (--e1)<0) goto NoMatch;
          if (i<len0 && ss[o+s0[i]]==1 && (--e0)<0) goto NoMatch;
        }
        // Clear the image that has been found
        for (i=0; i<len1; i++)
          ss[o+s1[i]]=0;
      }
      ok++;
      if (allpos!=0)
      {
        allpos[ok-1]=(sy+y)<<16|(sx+x);
        if (ok>=allpos_max) goto Return1;
      }
      NoMatch:;
    }
  }
  //----------------------
  Return1:
  return ok;
}

)"
}

PicInfo(text)
{
  static info:=Map(), bmp:=[]
  if !InStr(text, "$")
    return
  key:=(r:=StrLen(text))<10000 ? text
    : DllCall("ntdll\RtlComputeCrc32", "uint",0
    , "Ptr",StrPtr(text), "uint",r*2, "uint")
  if info.Has(key)
    return info[key]
  v:=text, comment:="", seterr:=err1:=err0:=0
  ; You Can Add Comment Text within The <>
  if RegExMatch(v, "<([^>\n]*)>", &r)
    v:=StrReplace(v,r[0]), comment:=Trim(r[1])
  ; You can Add two fault-tolerant in the [], separated by commas
  if RegExMatch(v, "\[([^\]\n]*)]", &r)
  {
    v:=StrReplace(v,r[0]), r:=StrSplit(r[1] ",", ",")
    , seterr:=1, err1:=r[1], err0:=r[2]
  }
  color:=SubStr(v,1,InStr(v,"$")-1), v:=Trim(SubStr(v,InStr(v,"$")+1))
  mode:=InStr(color,"##") ? 5
    : InStr(color,"-") ? 4 : InStr(color,"#") ? 3
    : InStr(color,"**") ? 2 : InStr(color,"*") ? 1 : 0
  color:=RegExReplace(color, "[*#\s]")
  if (mode=5)
  {
    ; You can use Text:="##10-RRGGBB-RRGGBB... $ d:\a.bmp"
    ; then the 0xRRGGBB(+/-10)... as transparent color
    if !(v~="/[\s\-\w]+/[\s\-\w,/]+$")  ; ImageSearch
    {
      if !(hBM:=LoadPicture(v))
        return
      this.GetBitmapWH(hBM, &w, &h)
      if (w<1 || h<1)
        return
      hBM2:=this.CreateDIBSection(w, h, 32, &Scan0)
      this.CopyHBM(hBM2, 0, 0, hBM, 0, 0, w, h)
      DllCall("DeleteObject", "Ptr",hBM)
      if (!Scan0)
        return
      ; All images used for ImageSearch are cached
      StrReplace(color, "-",,, &n)
      bmp.Push(buf:=Buffer(w*h*4+n*4)), v:=buf.Ptr
      DllCall("RtlMoveMemory", "Ptr",v, "Ptr",Scan0, "Ptr",w*h*4)
      DllCall("DeleteObject", "Ptr",hBM2)
      n++, p:=v+w*h*4-4, tab:=Map(), tab.CaseSense:="Off"
      , tab.Set("Black", "000000", "White", "FFFFFF"
      , "Red", "FF0000", "Green", "008000", "Blue", "0000FF"
      , "Yellow", "FFFF00", "Silver", "C0C0C0", "Gray", "808080"
      , "Teal", "008080", "Navy", "000080", "Aqua", "00FFFF"
      , "Olive", "808000", "Lime", "00FF00", "Fuchsia", "FF00FF"
      , "Purple", "800080", "Maroon", "800000")
      For k1,v1 in StrSplit(StrReplace(color, "0x"), "-")
      if (k1>1)
        NumPut("uint", Floor("0x" (tab.Has(v1)?tab[v1]:v1)), p+=4)
    }
    else
    {
      v:=RegExReplace(RegExReplace(v,"\s"), "i)/-?\w+/(?!0x)", "$00x")
      r:=StrSplit(Trim(StrReplace(v, ",", "/"), "/"), "/")
      if !(n:=r.Length//3)
        return
      VarSetStrCapacity(&v, n*18*2)
      x1:=x2:=this.Floor(r[1]), y1:=y2:=this.Floor(r[2]), i:=-2
      Loop n
        x:=this.Floor(r[i+=3]), y:=this.Floor(r[i+1])
        , (x<x1 && x1:=x), (x>x2 && x2:=x)
        , (y<y1 && y1:=y), (y>y2 && y2:=y)
      w:=x2-x1+1, h:=y2-y1+1, i:=-2
      Loop n
        x:=this.Floor(r[i+=3])-x1, y:=this.Floor(r[i+1])-y1
        , v.=(y*w+x)<<24|(this.Floor(r[i+2])&0xFFFFFF) . "/"
      n:=0
    }
    color:=this.Floor(StrSplit(color "-", "-")[1])
  }
  else
  {
    r:=StrSplit(v ".", "."), w:=this.Floor(r[1])
    , v:=this.base64tobit(r[2]), h:=StrLen(v)//w
    if (w<1 || h<1 || StrLen(v)!=w*h)
      return
    if (mode=4)
    {
      r:=StrSplit(StrReplace(color, "0x"), "-")
      , color:=this.Floor("0x" r[1]), n:=this.Floor("0x" r[2])
    }
    else
    {
      r:=StrSplit(color "@0", "@")
      , color:=this.Floor(r[1]), n:=this.Floor(r[2])
      , n:=Round(n,2)+(!n), n:=Floor(512*9*255*255*(1-n)*(1-n))
      , (mode=3 && color:=((color-1)//w)<<16|Mod(color-1,w))
    }
  }
  return info[key]:=[v, w, h, seterr, err1, err0, mode, color, n, comment]
}

GetBitsFromScreen(&x:=0, &y:=0, &w:=0, &h:=0
  , ScreenShot:=1, &zx:=0, &zy:=0, &zw:=0, &zh:=0)
{
  static CAPTUREBLT:=""
  (!IsObject(this.bits) && this.bits:={Scan0:0, hBM:0, oldzw:0, oldzh:0})
  , bits:=this.bits
  if (!ScreenShot && bits.Scan0)
  {
    zx:=bits.zx, zy:=bits.zy, zw:=bits.zw, zh:=bits.zh
    , w:=Min(x+w,zx+zw), x:=Max(x,zx), w-=x
    , h:=Min(y+h,zy+zh), y:=Max(y,zy), h-=y
    return bits
  }
  cri:=A_IsCritical
  Critical
  if (id:=this.BindWindow(0,0,1))
  {
    id:=WinGetID("ahk_id " id)
    WinGetPos &zx, &zy, &zw, &zh, id
  }
  if (!id)
    zx:=SysGet(76), zy:=SysGet(77), zw:=SysGet(78), zh:=SysGet(79)
  this.UpdateBitsRect(bits, zx, zy, zw, zh)
  , w:=Min(x+w,zx+zw), x:=Max(x,zx), w-=x
  , h:=Min(y+h,zy+zh), y:=Max(y,zy), h-=y
  if (!ScreenShot || w<1 || h<1 || !bits.hBM)
  {
    Critical(cri)
    return bits
  }
  if IsSet(GetBitsFromScreen2) && (GetBitsFromScreen2 is Func)
    && GetBitsFromScreen2(bits, x-zx, y-zy, w, h)
  {
    ; Each small range of data obtained from DXGI must be
    ; copied to the screenshot cache using this.CopyBits()
    zx:=bits.zx, zy:=bits.zy, zw:=bits.zw, zh:=bits.zh
    Critical(cri)
    return bits
  }
  if (CAPTUREBLT="")  ; thanks Descolada
  {
    DllCall("Dwmapi\DwmIsCompositionEnabled", "Int*", &i:=0)
    CAPTUREBLT:=i ? 0 : 0x40000000
  }
  mDC:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
  oBM:=DllCall("SelectObject", "Ptr",mDC, "Ptr",bits.hBM, "Ptr")
  if (id)
  {
    if (mode:=this.BindWindow(0,0,0,1))<2
    {
      hDC2:=DllCall("GetDCEx", "Ptr",id, "Ptr",0, "int",3, "Ptr")
      DllCall("BitBlt","Ptr",mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
        , "Ptr",hDC2, "int",x-zx, "int",y-zy, "uint",0xCC0020|CAPTUREBLT)
      DllCall("ReleaseDC", "Ptr",id, "Ptr",hDC2)
    }
    else
    {
      hBM2:=this.CreateDIBSection(zw, zh)
      mDC2:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
      oBM2:=DllCall("SelectObject", "Ptr",mDC2, "Ptr",hBM2, "Ptr")
      DllCall("PrintWindow", "Ptr",id, "Ptr",mDC2, "uint",(mode>3)*3)
      DllCall("BitBlt","Ptr",mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
        , "Ptr",mDC2, "int",x-zx, "int",y-zy, "uint",0xCC0020)
      DllCall("SelectObject", "Ptr",mDC2, "Ptr",oBM2)
      DllCall("DeleteDC", "Ptr",mDC2)
      DllCall("DeleteObject", "Ptr",hBM2)
    }
  }
  else
  {
    win:=DllCall("GetDesktopWindow", "Ptr")
    , hDC:=DllCall("GetWindowDC", "Ptr",win, "Ptr")
    , DllCall("BitBlt","Ptr",mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
      , "Ptr",hDC, "int",x, "int",y, "uint",0xCC0020|CAPTUREBLT)
    , DllCall("ReleaseDC", "Ptr",win, "Ptr",hDC)
  }
  if this.CaptureCursor(0,0,0,0,0,1)
    this.CaptureCursor(mDC, zx, zy, zw, zh)
  DllCall("SelectObject", "Ptr",mDC, "Ptr",oBM)
  , DllCall("DeleteDC", "Ptr",mDC)
  Critical(cri)
  return bits
}

UpdateBitsRect(bits, zx, zy, zw, zh)
{
  if (zw>bits.oldzw || zh>bits.oldzh || !bits.hBM)
  {
    Try DllCall("DeleteObject", "Ptr",bits.hBM)
    bits.hBM:=this.CreateDIBSection(zw, zh, bpp:=32, &ppvBits)
    , bits.Scan0:=(!bits.hBM ? 0:ppvBits)
    , bits.Stride:=((zw*bpp+31)//32)*4
    , bits.oldzw:=zw, bits.oldzh:=zh
  }
  bits.zx:=zx, bits.zy:=zy, bits.zw:=zw, bits.zh:=zh
}

CreateDIBSection(w, h, bpp:=32, &ppvBits:=0)
{
  NumPut("int",40, "int",w, "int",-h, "short",1, "short",bpp, bi:=Buffer(40,0))
  return DllCall("CreateDIBSection", "Ptr",0, "Ptr",bi
    , "int",0, "Ptr*",&ppvBits:=0, "Ptr",0, "int",0, "Ptr")
}

GetBitmapWH(hBM, &w, &h)
{
  bm:=Buffer(size:=(A_PtrSize=8 ? 32:24))
  , DllCall("GetObject", "Ptr",hBM, "int",size, "Ptr",bm)
  , w:=NumGet(bm,4,"int"), h:=Abs(NumGet(bm,8,"int"))
}

CopyHBM(hBM1, x1, y1, hBM2, x2, y2, w, h)
{
  if (w<1 || h<1 || !hBM1 || !hBM2)
    return
  mDC1:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
  oBM1:=DllCall("SelectObject", "Ptr",mDC1, "Ptr",hBM1, "Ptr")
  mDC2:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
  oBM2:=DllCall("SelectObject", "Ptr",mDC2, "Ptr",hBM2, "Ptr")
  DllCall("BitBlt", "Ptr",mDC1, "int",x1, "int",y1, "int",w, "int",h
    , "Ptr",mDC2, "int",x2, "int",y2, "uint",0xCC0020)
  DllCall("SelectObject", "Ptr",mDC1, "Ptr",oBM1)
  DllCall("DeleteDC", "Ptr",mDC1)
  DllCall("SelectObject", "Ptr",mDC2, "Ptr",oBM2)
  DllCall("DeleteDC", "Ptr",mDC2)
}

CopyBits(Scan01,Stride1,x1,y1,Scan02,Stride2,x2,y2,w,h,Reverse:=0)
{
  if (w<1 || h<1 || !Scan01 || !Scan02)
    return
  ListLines (lls:=A_ListLines)?0:0
  p1:=Scan01+(y1-1)*Stride1+x1*4
  , p2:=Scan02+(y2-1)*Stride2+x2*4, w*=4
  if (Reverse)
    p2+=(h+1)*Stride2, Stride2:=-Stride2
  Loop h
    DllCall("RtlMoveMemory","Ptr",p1+=Stride1,"Ptr",p2+=Stride2,"Ptr",w)
  ListLines(lls)
}

; Bind the window so that it can find images when obscured
; by other windows, it's equivalent to always being
; at the front desk. Unbind Window using FindText().BindWindow(0)

BindWindow(bind_id:=0, bind_mode:=0, get_id:=0, get_mode:=0)
{
  (!IsObject(this.bind) && this.bind:={id:0, mode:0, oldStyle:0})
  , bind:=this.bind
  if (get_id)
    return bind.id
  if (get_mode)
    return bind.mode
  if (bind_id)
  {
    bind_id:=Integer(bind_id), bind.id:=bind_id
    , bind.mode:=bind_mode, bind.oldStyle:=0
    if (bind_mode & 1)
    {
      i:=WinGetExStyle(bind_id)
      bind.oldStyle:=i
      WinSetTransparent(255, bind_id)
      Loop 30
      {
        Sleep 100
        i:=WinGetTransparent(bind_id)
      }
      Until (i=255)
    }
  }
  else
  {
    bind_id:=bind.id
    if (bind.mode & 1)
      WinSetExStyle(bind.oldStyle, bind_id)
    bind.id:=0, bind.mode:=0, bind.oldStyle:=0
  }
}

; Use FindText().CaptureCursor(1) to Capture Cursor
; Use FindText().CaptureCursor(0) to Cancel Capture Cursor

CaptureCursor(hDC:=0, zx:=0, zy:=0, zw:=0, zh:=0, get_cursor:=0)
{
  if (get_cursor)
    return this.Cursor
  if (hDC=1 || hDC=0) && (zw=0)
  {
    this.Cursor:=hDC
    return
  }
  mi:=Buffer(40, 0), NumPut("int", 16+A_PtrSize, mi)
  DllCall("GetCursorInfo", "Ptr",mi)
  bShow:=NumGet(mi, 4, "int")
  hCursor:=NumGet(mi, 8, "Ptr")
  x:=NumGet(mi, 8+A_PtrSize, "int")
  y:=NumGet(mi, 12+A_PtrSize, "int")
  if (!bShow) || (x<zx || y<zy || x>=zx+zw || y>=zy+zh)
    return
  ni:=Buffer(40, 0)
  DllCall("GetIconInfo", "Ptr",hCursor, "Ptr",ni)
  xCenter:=NumGet(ni, 4, "int")
  yCenter:=NumGet(ni, 8, "int")
  hBMMask:=NumGet(ni, (A_PtrSize=8?16:12), "Ptr")
  hBMColor:=NumGet(ni, (A_PtrSize=8?24:16), "Ptr")
  DllCall("DrawIconEx", "Ptr",hDC
    , "int",x-xCenter-zx, "int",y-yCenter-zy, "Ptr",hCursor
    , "int",0, "int",0, "int",0, "int",0, "int",3)
  DllCall("DeleteObject", "Ptr",hBMMask)
  DllCall("DeleteObject", "Ptr",hBMColor)
}

MCode(&code, hex)
{
  code:=Buffer(len:=StrLen(hex)//2)
  DllCall("crypt32\CryptStringToBinary", "Str",hex, "uint",0
    , "uint",4, "Ptr",code, "uint*",&len, "Ptr",0, "Ptr",0)
  DllCall("VirtualProtect", "Ptr",code, "Ptr",len, "uint",0x40, "Ptr*",0)
}

base64tobit(s)
{
  static Chars:="0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  ListLines((lls:=A_ListLines)?0:0)
  Loop Parse, Chars
    if InStr(s, A_LoopField, 1)
      s:=RegExReplace(s, "[" A_LoopField "]", ((i:=A_Index-1)>>5&1)
      . (i>>4&1) . (i>>3&1) . (i>>2&1) . (i>>1&1) . (i&1))
  s:=RegExReplace(RegExReplace(s,"[^01]+"),"10*$")
  ListLines(lls)
  return s
}

bit2base64(s)
{
  ListLines((lls:=A_ListLines)?0:0)
  s:=RegExReplace(s,"[^01]+")
  s.=SubStr("100000",1,6-Mod(StrLen(s),6))
  s:=RegExReplace(s,".{6}","|$0")
  Chars:="0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  Loop Parse, Chars
    s:=StrReplace(s, "|" . ((i:=A_Index-1)>>5&1)
    . (i>>4&1) . (i>>3&1) . (i>>2&1) . (i>>1&1) . (i&1), A_LoopField)
  ListLines(lls)
  return s
}

ASCII(s)
{
  if RegExMatch(s, "\$(\d+)\.([\w+/]+)", &r)
  {
    s:=RegExReplace(this.base64tobit(r[2]),".{" r[1] "}","$0`n")
    s:=StrReplace(StrReplace(s,"0","_"),"1","0")
  }
  else s:=""
  return s
}

; You can put the text library at the beginning of the script,
; and Use FindText().PicLib(Text,1) to add the text library to PicLib()'s Lib,
; Use FindText().PicLib("comment1|comment2|...") to get text images from Lib

PicLib(comments, add_to_Lib:=0, index:=1)
{
  (!IsObject(this.Lib) && this.Lib:=Map()), Lib:=this.Lib
  , (!Lib.Has(index) && Lib[index]:=Map()), Lib:=Lib[index]
  if (add_to_Lib)
  {
    re:="<([^>\n]*)>[^$\n]+\$[^`"'\r\n]+"
    Loop Parse, comments, "|"
      if RegExMatch(A_LoopField, re, &r)
      {
        s1:=Trim(r[1]), s2:=""
        Loop Parse, s1
          s2.="_" . Format("{:d}",Ord(A_LoopField))
        Lib[s2]:=r[0]
      }
    Lib[""]:=""
  }
  else
  {
    Text:=""
    Loop Parse, comments, "|"
    {
      s1:=Trim(A_LoopField), s2:=""
      Loop Parse, s1
        s2.="_" . Format("{:d}",Ord(A_LoopField))
      if Lib.Has(s2)
        Text.="|" . Lib[s2]
    }
    return Text
  }
}

; Decompose a string into individual characters and get their data

PicN(Number, index:=1)
{
  return this.PicLib(RegExReplace(Number,".","|$0"), 0, index)
}

; Use FindText().PicX(Text) to automatically cut into multiple characters
; Can't be used in ColorPos mode, because it can cause position errors

PicX(Text)
{
  if !RegExMatch(Text, "(<[^$\n]+)\$(\d+)\.([\w+/]+)", &r)
    return Text
  v:=this.base64tobit(r[3]), Text:=""
  c:=StrLen(StrReplace(v,"0"))<=StrLen(v)//2 ? "1":"0"
  txt:=RegExReplace(v,".{" r[2] "}","$0`n")
  While InStr(txt,c)
  {
    While !(txt~="m`n)^" c)
      txt:=RegExReplace(txt,"m`n)^.")
    i:=0
    While (txt~="m`n)^.{" i "}" c)
      i:=Format("{:d}",i+1)
    v:=RegExReplace(txt,"m`n)^(.{" i "}).*","$1")
    txt:=RegExReplace(txt,"m`n)^.{" i "}")
    if (v!="")
      Text.="|" r[1] "$" i "." this.bit2base64(v)
  }
  return Text
}

; Screenshot and retained as the last screenshot.

ScreenShot(x1:=0, y1:=0, x2:=0, y2:=0)
{
  this.FindText(,, x1, y1, x2, y2)
}

; Get the RGB color of a point from the last screenshot.
; If the point to get the color is beyond the range of
; Screen, it will return White color (0xFFFFFF).

GetColor(x, y, fmt:=1)
{
  bits:=this.GetBitsFromScreen(,,,,0,&zx,&zy,&zw,&zh)
  , c:=(x<zx || x>=zx+zw || y<zy || y>=zy+zh || !bits.Scan0)
  ? 0xFFFFFF : NumGet(bits.Scan0+(y-zy)*bits.Stride+(x-zx)*4,"uint")
  return (fmt ? Format("0x{:06X}",c&0xFFFFFF) : c)
}

; Set the RGB color of a point in the last screenshot

SetColor(x, y, color:=0x000000)
{
  bits:=this.GetBitsFromScreen(,,,,0,&zx,&zy,&zw,&zh)
  if !(x<zx || x>=zx+zw || y<zy || y>=zy+zh || !bits.Scan0)
    NumPut("uint", color, bits.Scan0+(y-zy)*bits.Stride+(x-zx)*4)
}

; Identify a line of text or verification code
; based on the result returned by FindText().
; offsetX is the maximum interval between two texts,
; if it exceeds, a "*" sign will be inserted.
; offsetY is the maximum height difference between two texts.
; overlapW is used to set the width of the overlap.
; Return Association array {text:Text, x:X, y:Y, w:W, h:H}

Ocr(ok, offsetX:=20, offsetY:=20, overlapW:=0)
{
  ocr_Text:=ocr_X:=ocr_Y:=min_X:=dx:=""
  For k,v in ok
    x:=v.1
    , min_X:=(A_Index=1 || x<min_X ? x : min_X)
    , max_X:=(A_Index=1 || x>max_X ? x : max_X)
  While (min_X!="" && min_X<=max_X)
  {
    LeftX:=""
    For k,v in ok
    {
      x:=v.1, y:=v.2
      if (x<min_X) || (ocr_Y!="" && Abs(y-ocr_Y)>offsetY)
        Continue
      ; Get the leftmost X coordinates
      if (LeftX="" || x<LeftX)
        LeftX:=x, LeftY:=y, LeftW:=v.3, LeftH:=v.4, LeftOCR:=v.id
    }
    if (LeftX="")
      Break
    if (ocr_X="")
      ocr_X:=LeftX, min_Y:=LeftY, max_Y:=LeftY+LeftH
    ; If the interval exceeds the set value, add "*" to the result
    ocr_Text.=(ocr_Text!="" && LeftX>dx ? "*":"") . LeftOCR
    ; Update for next search
    min_X:=LeftX+LeftW-(overlapW>LeftW//2 ? LeftW//2:overlapW)
    , dx:=LeftX+LeftW+offsetX, ocr_Y:=LeftY
    , (LeftY<min_Y && min_Y:=LeftY)
    , (LeftY+LeftH>max_Y && max_Y:=LeftY+LeftH)
  }
  if (ocr_X="")
    ocr_X:=0, min_Y:=0, min_X:=0, max_Y:=0
  return {text:ocr_Text, x:ocr_X, y:min_Y
    , w: min_X-ocr_X, h: max_Y-min_Y}
}

; Sort the results of FindText() from left to right
; and top to bottom, ignore slight height difference

Sort(ok, dy:=10)
{
  if !IsObject(ok)
    return ok
  s:="", n:=150000, ypos:=[]
  For k,v in ok
  {
    x:=v.x, y:=v.y, add:=1
    For k1,v1 in ypos
    if Abs(y-v1)<=dy
    {
      y:=v1, add:=0
      Break
    }
    if (add)
      ypos.Push(y)
    s.=(y*n+x) "." k "|"
  }
  s:=Sort(Trim(s,"|"), "N D|")
  ok2:=[]
  Loop Parse, s, "|"
    ok2.Push( ok[StrSplit(A_LoopField,".")[2]] )
  return ok2
}

; Sort the results of FindText() according to the nearest distance

Sort2(ok, px, py)
{
  if !IsObject(ok)
    return ok
  s:=""
  For k,v in ok
    s.=((v.x-px)**2+(v.y-py)**2) "." k "|"
  s:=Sort(Trim(s,"|"), "N D|")
  ok2:=[]
  Loop Parse, s, "|"
    ok2.Push( ok[StrSplit(A_LoopField,".")[2]] )
  return ok2
}

; Sort the results of FindText() according to the search direction

Sort3(ok, dir:=1)
{
  if !IsObject(ok)
    return ok
  s:="", n:=150000
  For k,v in ok
    x:=v.1, y:=v.2
    , s.=(dir=1 ? y*n+x
    : dir=2 ? y*n-x
    : dir=3 ? -y*n+x
    : dir=4 ? -y*n-x
    : dir=5 ? x*n+y
    : dir=6 ? x*n-y
    : dir=7 ? -x*n+y
    : dir=8 ? -x*n-y : y*n+x) "." k "|"
  s:=Sort(Trim(s,"|"), "N D|")
  ok2:=[]
  Loop Parse, s, "|"
    ok2.Push( ok[StrSplit(A_LoopField,".")[2]] )
  return ok2
}

; Prompt mouse position in remote assistance

MouseTip(x:="", y:="", w:=10, h:=10, d:=3)
{
  if (x="")
  {
    pt:=Buffer(16,0), DllCall("GetCursorPos", "Ptr",pt)
    x:=NumGet(pt,0,"uint"), y:=NumGet(pt,4,"uint")
  }
  Loop 4
  {
    this.RangeTip(x-w, y-h, 2*w+1, 2*h+1, (A_Index & 1 ? "Red":"Blue"), d)
    Sleep 500
  }
  this.RangeTip()
}

; Shows a range of the borders, similar to the ToolTip

RangeTip(x:="", y:="", w:="", h:="", color:="Red", d:=3)
{
  static Range:=Map()
  if (x="")
  {
    Loop 4
      if (Range.Has(i:=A_Index) && Range[i])
        Range[i].Destroy(), Range[i]:=0
    return
  }
  if !(Range.Has(1) && Range[1])
  {
    Loop 4
      Range[A_Index]:=Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000")
  }
  x:=this.Floor(x), y:=this.Floor(y), w:=this.Floor(w), h:=this.Floor(h), d:=this.Floor(d)
  Loop 4
  {
    i:=A_Index
    , x1:=(i=2 ? x+w : x-d)
    , y1:=(i=3 ? y+h : y-d)
    , w1:=(i=1 || i=3 ? w+2*d : d)
    , h1:=(i=2 || i=4 ? h+2*d : d)
    Range[i].BackColor:=color
    Range[i].Show("NA x" x1 " y" y1 " w" w1 " h" h1)
  }
}

; Use RButton to select the screen range

GetRange(ww:=25, hh:=8, key:="RButton")
{
  static Gui_Off:=0, hk, FindText_HotkeyIf:=""
  if (!Gui_Off)
    Gui_Off:=this.GetRange.Bind(this, "Off")
  if (ww="Off")
    return hk:=Trim(A_ThisHotkey, "*")
  ;---------------------
  Try FindText_HotkeyIf.Destroy()
  FindText_HotkeyIf:=_Gui:=Gui()
  _Gui.Opt "-Caption +ToolWindow +E0x80000"
  _Gui.Title:="FindText_HotkeyIf"
  _Gui.Show "NA x0 y0 w0 h0"
  ;---------------------
  HotIfWinExist "FindText_HotkeyIf"
  keys:=key "|Up|Down|Left|Right"
  For k,v in StrSplit(keys, "|")
  {
    KeyWait v
    Try Hotkey "*" v, Gui_Off, "On"
  }
  KeyWait "Ctrl"
  HotIfWinExist
  ;---------------------
  Critical (cri:=A_IsCritical)?"Off":"Off"
  CoordMode "Mouse"
  tip:=this.Lang("s5")
  hk:="", oldx:=oldy:="", keydown:=0
  Loop
  {
    Sleep 50
    MouseGetPos &x, &y
    if (hk=key) || GetKeyState(key,"P") || GetKeyState("Ctrl","P")
    {
      keydown++
      if (keydown=1)
        MouseGetPos &x1, &y1, &Bind_ID
      KeyWait key
      KeyWait "Ctrl"
      hk:=""
      if (keydown>1)
        Break
    }
    else if (hk="Up") || GetKeyState("Up","P")
      (hh>1 && hh--), hk:=""
    else if (hk="Down") || GetKeyState("Down","P")
      hh++, hk:=""
    else if (hk="Left") || GetKeyState("Left","P")
      (ww>1 && ww--), hk:=""
    else if (hk="Right") || GetKeyState("Right","P")
      ww++, hk:=""
    this.RangeTip((keydown?x1:x)-ww, (keydown?y1:y)-hh
      , 2*ww+1, 2*hh+1, (A_MSec<500?"Red":"Blue"))
    if (oldx=x && oldy=y)
      Continue
    oldx:=x, oldy:=y
    ToolTip tip
  }
  ToolTip
  this.RangeTip()
  HotIfWinExist "FindText_HotkeyIf"
  For k,v in StrSplit(keys, "|")
    Try Hotkey "*" v, Gui_Off, "Off"
  HotIfWinExist
  FindText_HotkeyIf.Destroy
  Critical(cri)
  return [x1-ww, y1-hh, x1+ww, y1+hh, Bind_ID]
}

; Take a screenshot to Clipboard or File, or only get Range

SnapShot(ScreenShot:=1, key:="LButton")
{
  static Gui_Off:=0, hk, SnapShot_HotkeyIf:="", SnapShot_Box:=""
  if (!Gui_Off)
    Gui_Off:=this.SnapShot.Bind(this, "Off")
  if (ScreenShot="Off")
    return hk:=Trim(A_ThisHotkey, "*")
  n:=150000, x:=y:=-n, w:=h:=2*n
  hBM:=this.BitmapFromScreen(&x,&y,&w,&h,ScreenShot,&zx,&zy,&zw,&zh)
  ;---------------
  Try SnapShot_HotkeyIf.Destroy()    ; WS_EX_NOACTIVATE:=0x08000000
  SnapShot_HotkeyIf:=_Gui:=Gui()
  _Gui.Opt "+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000"
  _Gui.MarginX:=0, _Gui.MarginY:=0
  _Gui.Add "Pic", "w" zw " h" zh, "HBITMAP:*" hBM
  _Gui.Title:="SnapShot_HotkeyIf"
  _Gui.Show "NA x" zx " y" zy " w" zw " h" zh
  ;---------------
  Try SnapShot_Box.Destroy()
  SnapShot_Box:=_Gui:=Gui()
  _Gui.Opt "+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000"
  box_id:=_Gui.Hwnd
  _Gui.MarginX:=0, _Gui.MarginY:=0
  _Gui.SetFont "s12"
  For k,v in StrSplit(this.Lang("s15"), "|")
    id:=_Gui.Add("Button", (k=1 ? "":"x+0"), v)
  id.GetPos(&pX, &pY, &pW, &pH)
  box_w:=pX+pW+10, box_h:=pH+10
  _Gui.Title:="SnapShot_Box"
  _Gui.Show "Hide"
  ;---------------
  HotIfWinExist "SnapShot_HotkeyIf"
  keys:=key "|RButton|Esc|Up|Down|Left|Right"
  For k,v in StrSplit(keys, "|")
  {
    KeyWait v
    Try Hotkey "*" v, Gui_Off, "On"
  }
  HotIfWinExist
  ;---------------
  Critical (cri:=A_IsCritical)?"Off":"Off"
  CoordMode "Mouse"
  Loop
  {  ;// For ReTry
  tip:=this.Lang("s16")
  hk:="", oldx:=oldy:="", ok:=0, d:=10, oldt:=0, oldf:=""
  Loop
  {
    Sleep 50
    MouseGetPos &x1, &y1
    if (oldx=x1 && oldy=y1)
      Continue
    oldx:=x1, oldy:=y1
    ToolTip tip
  }
  Until (hk=key) || GetKeyState(key,"P")
  Loop
  {
    Sleep 50
    MouseGetPos &x2, &y2
    x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x1-x2)+1, h:=Abs(y1-y2)+1
    this.RangeTip(x, y, w, h, (A_MSec<500 ? "Red":"Blue"))
    if (oldx=x2 && oldy=y2)
      Continue
    oldx:=x2, oldy:=y2
    ToolTip tip
  }
  Until !GetKeyState(key,"P")
  hk:=""
  Loop
  {
    Sleep 50
    MouseGetPos &x3, &y3
    x1:=x, y1:=y, x2:=x+w-1, y2:=y+h-1
    , d1:=Abs(x3-x1)<=d, d2:=Abs(x3-x2)<=d
    , d3:=Abs(y3-y1)<=d, d4:=Abs(y3-y2)<=d
    , d5:=x3>x1+d && x3<x2-d, d6:=y3>y1+d && y3<y2-d
    , f:=(d1 && d3 ? 1 : d2 && d3 ? 2 : d1 && d4 ? 3
    : d2 && d4 ? 4 : d5 && d3 ? 5 : d5 && d4 ? 6
    : d6 && d1 ? 7 : d6 && d2 ? 8 : d5 && d6 ? 9 : 0)
    if (oldf!=f)
      oldf:=f, this.SetCursor(f=1 || f=4 ? "SIZENWSE"
      : f=2 || f=3 ? "SIZENESW" : f=5 || f=6 ? "SIZENS"
      : f=7 || f=8 ? "SIZEWE" : f=9 ? "SIZEALL" : "ARROW")
    ;--------------
    if (hk="Up") || GetKeyState("Up","P")
      hk:="", y--
    else if (hk="Down") || GetKeyState("Down","P")
      hk:="", y++
    else if (hk="Left") || GetKeyState("Left","P")
      hk:="", x--
    else if (hk="Right") || GetKeyState("Right","P")
      hk:="", x++
    else if (hk="RButton") || (hk="Esc")
    || GetKeyState("RButton","P") || GetKeyState("Esc","P")
      Break
    else if (hk=key) || GetKeyState(key,"P")
    {
      MouseGetPos(,, &id, &mc)
      if (id=box_id) && (mc="Button1")
      {
        KeyWait key
        this.RangeTip(), this.SetCursor()
        SnapShot_Box.Hide
        Continue 2
      }
      if (id=box_id) && (ok:=mc="Button2" ? 2 : mc="Button4" ? 1:100)
        Break
      SnapShot_Box.Hide
      ToolTip
      Loop
      {
        Sleep 50
        MouseGetPos &x4, &y4
        x1:=x, y1:=y, x2:=x+w-1, y2:=y+h-1, dx:=x4-x3, dy:=y4-y3
        , (f=1 ? (x1+=dx, y1+=dy) : f=2 ? (x2+=dx, y1+=dy)
        : f=3 ? (x1+=dx, y2+=dy) : f=4 ? (x2+=dx, y2+=dy)
        : f=5 ? y1+=dy : f=6 ? y2+=dy : f=7 ? x1+=dx : f=8 ? x2+=dx
        : f=9 ? (x1+=dx, y1+=dy, x2+=dx, y2+=dy) : 0)
        , (f ? this.RangeTip(Min(x1,x2), Min(y1,y2), Abs(x1-x2)+1, Abs(y1-y2)+1
        , (A_MSec<500 ? "Red":"Blue")) : 0)
      }
      Until !GetKeyState(key,"P")
      hk:="", x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x1-x2)+1, h:=Abs(y1-y2)+1
      if (f=9) && Abs(dx)<2 && Abs(dy)<2 && (ok:=(-oldt)+(oldt:=A_TickCount)<400)
        Break
    }
    this.RangeTip(x, y, w, h, (A_MSec<500 ? "Red":"Blue"))
    x1:=x+w-box_w, (x1<10 && x1:=10), (x1>zx+zw-box_w && x1:=zx+zw-box_w)
    , y1:=y+h+10, (y1>zy+zh-box_h && y1:=y-box_h), (y1<10 && y1:=10)
    SnapShot_Box.Show "NA x" x1 " y" y1
    ;-------------
    if (oldx=x3 && oldy=y3)
      Continue
    oldx:=x3, oldy:=y3
    ToolTip tip
  }
  Break
  }  ;// For ReTry
  KeyWait key
  KeyWait "RButton"
  this.SetCursor()
  ToolTip
  this.RangeTip()
  SnapShot_Box.Destroy
  HotIfWinExist "SnapShot_HotkeyIf"
  For k,v in StrSplit(keys, "|")
    Try Hotkey "*" v, Gui_Off, "Off"
  HotIfWinExist
  SnapShot_HotkeyIf.Destroy
  Critical(cri)
  ;---------------
  w:=Min(x+w,zx+zw), x:=Max(x,zx), w-=x
  h:=Min(y+h,zy+zh), y:=Max(y,zy), h-=y
  if (ok=1)
    this.SaveBitmapToFile(0, hBM, x-zx, y-zy, w, h)
  else if (ok=2)
  {
    file:=FileSelect("S18", A_Desktop "\1.bmp", "SaveAs", "Image (*.bmp)")
    this.SaveBitmapToFile(file, hBM, x-zx, y-zy, w, h)
  }
  DllCall("DeleteObject", "Ptr",hBM)
  return [x, y, x+w-1, y+h-1]
}

SetCursor(cursor:="", *)
{
  static init:=0, tab:=Map()
  if (!init)
  {
    init:=1, OnExit(this.SetCursor.Bind(this,"")), this.SetCursor()
    s:="ARROW,32512, SIZENWSE,32642, SIZENESW,32643"
      . ", SIZEWE,32644, SIZENS,32645, SIZEALL,32646"
      . ", IBEAM,32513, WAIT,32514, CROSS,32515, UPARROW,32516"
      . ", NO,32648, HAND,32649, APPSTARTING,32650, HELP,32651"
    For i,v in StrSplit(s, ",", " ")
      (i&1) ? (k:=v) : (tab[k]:=DllCall("CopyImage"
      , "Ptr", DllCall("LoadCursor", "Ptr",0, "Ptr",v, "Ptr")
      , "int",2, "int",0, "int",0, "int",0, "Ptr"))
  }
  if (cursor!="") && tab.Has(cursor)
    DllCall("SetSystemCursor", "Ptr", DllCall("CopyImage", "Ptr",tab[cursor]
    , "int",2, "int",0, "int",0, "int",0, "Ptr"), "int",32512)
  else
    DllCall("SystemParametersInfo", "int",0x57, "int",0, "Ptr",0, "int",0)
}

BitmapFromScreen(&x:=0, &y:=0, &w:=0, &h:=0
  , ScreenShot:=1, &zx:=0, &zy:=0, &zw:=0, &zh:=0)
{
  bits:=this.GetBitsFromScreen(&x,&y,&w,&h,ScreenShot,&zx,&zy,&zw,&zh)
  if (w<1 || h<1 || !bits.hBM)
    return
  hBM:=this.CreateDIBSection(w, h)
  this.CopyHBM(hBM, 0, 0, bits.hBM, x-zx, y-zy, w, h)
  this.BitmapClear(hBM, w, h)
  return hBM
}

BitmapClear(hBM, w:=0, h:=0)
{
  (w=0 || h=0) && this.GetBitmapWH(hBM, &w, &h)
  mDC:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
  oBM:=DllCall("SelectObject", "Ptr",mDC, "Ptr",hBM, "Ptr")
  DllCall("BitBlt", "Ptr",mDC, "int",0, "int",0, "int",w, "int",h
    , "Ptr",mDC, "int",0, "int",0, "uint", MERGECOPY:=0xC000CA)
  DllCall("SelectObject", "Ptr",mDC, "Ptr",oBM)
  DllCall("DeleteDC", "Ptr",mDC)
}

; Quickly save screen image to BMP file for debugging
; if file = 0 or "", save to Clipboard

SavePic(file:=0, x1:=0, y1:=0, x2:=0, y2:=0, ScreenShot:=1)
{
  x1:=this.Floor(x1), y1:=this.Floor(y1), x2:=this.Floor(x2), y2:=this.Floor(y2)
  if (x1=0 && y1=0 && x2=0 && y2=0)
    n:=150000, x:=y:=-n, w:=h:=2*n
  else
    x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  hBM:=this.BitmapFromScreen(&x, &y, &w, &h, ScreenShot)
  this.SaveBitmapToFile(file, hBM)
  DllCall("DeleteObject", "Ptr",hBM)
}

; Save Bitmap To File, if file = 0 or "", save to Clipboard
; hBM_or_file can be a bitmap handle or file path, eg: "c:\1.bmp"

SaveBitmapToFile(file, hBM_or_file, x:=0, y:=0, w:=0, h:=0)
{
  if IsNumber(hBM_or_file)
    hBM_or_file:="HBITMAP:*" hBM_or_file
  if !hBM:=DllCall("CopyImage", "Ptr",LoadPicture(hBM_or_file)
  , "int",0, "int",0, "int",0, "uint",0x2008)
    return
  if (file) || (w!=0 && h!=0)
  {
    (w=0 || h=0) && this.GetBitmapWH(hBM, &w, &h)
    hBM2:=this.CreateDIBSection(w, -h, bpp:=(file ? 24 : 32))
    this.CopyHBM(hBM2, 0, 0, hBM, x, y, w, h)
    DllCall("DeleteObject", "Ptr",hBM), hBM:=hBM2
  }
  dib:=Buffer(dib_size:=(A_PtrSize=8 ? 104:84))
  , DllCall("GetObject", "Ptr",hBM, "int",dib_size, "Ptr",dib)
  , pbi:=dib.Ptr+(bitmap_size:=A_PtrSize=8 ? 32:24)
  , size:=NumGet(pbi+20, "uint"), pBits:=NumGet(pbi-A_PtrSize, "Ptr")
  if (!file)
  {
    hdib:=DllCall("GlobalAlloc", "uint",2, "Ptr",40+size, "Ptr")
    pdib:=DllCall("GlobalLock", "Ptr",hdib, "Ptr")
    DllCall("RtlMoveMemory", "Ptr",pdib, "Ptr",pbi, "Ptr",40)
    DllCall("RtlMoveMemory", "Ptr",pdib+40, "Ptr",pBits, "Ptr",size)
    DllCall("GlobalUnlock", "Ptr",hdib)
    DllCall("OpenClipboard", "Ptr",0)
    DllCall("EmptyClipboard")
    if !DllCall("SetClipboardData", "uint",8, "Ptr",hdib)
      DllCall("GlobalFree", "Ptr",hdib)
    DllCall("CloseClipboard")
  }
  else
  {
    bf:=Buffer(14, 0), NumPut("short", 0x4D42, bf)
    NumPut("uint", 54+size, bf, 2), NumPut("uint", 54, bf, 10)
    f:=FileOpen(file, "w"), f.RawWrite(bf, 14)
    , f.RawWrite(pbi+0, 40), f.RawWrite(pBits+0, size), f.Close()
  }
  DllCall("DeleteObject", "Ptr",hBM)
}

; Show the saved Picture file

ShowPic(file:="", show:=1, &x:="", &y:="", &w:="", &h:="")
{
  if (file="")
  {
    this.ShowScreenShot()
    return
  }
  if !(hBM:=LoadPicture(file))
    return
  this.GetBitmapWH(hBM, &w, &h)
  this.GetBitsFromScreen(,,,,0,&x,&y)
  bits:=this.GetBitsFromScreen(&x,&y,&w,&h,0)
  this.CopyHBM(bits.hBM, 0, 0, hBM, 0, 0, w, h)
  DllCall("DeleteObject", "Ptr",hBM)
  if (show)
    this.ShowScreenShot(x, y, x+w-1, y+h-1, 0)
}

; Show the memory Screenshot for debugging

ShowScreenShot(x1:=0, y1:=0, x2:=0, y2:=0, ScreenShot:=1)
{
  static hPic, oldx, oldy, oldw, oldh, FindText_Screen:=""
  x1:=this.Floor(x1), y1:=this.Floor(y1), x2:=this.Floor(x2), y2:=this.Floor(y2)
  if (x1=0 && y1=0 && x2=0 && y2=0)
  {
    if (FindText_Screen)
      FindText_Screen.Destroy(), FindText_Screen:=""
    return
  }
  x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  if !hBM:=this.BitmapFromScreen(&x,&y,&w,&h,ScreenShot)
    return
  ;---------------
  if (!FindText_Screen)
  {
    FindText_Screen:=_Gui:=Gui()
    _Gui.Opt "+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000"
    _Gui.Name:="FindText_Screen"
    _Gui.MarginX:=0, _Gui.MarginY:=0
    id:=_Gui.Add("Pic", "w" w " h" h), hPic:=id.Hwnd
    _Gui.Title:="Show Pic"
    _Gui.Show "NA x" x " y" y " w" w " h" h
    oldx:=x, oldy:=y, oldw:=w, oldh:=h
  }
  else if (oldx!=x || oldy!=y || oldw!=w || oldh!=h)
  {
    if (oldw!=w || oldh!=h)
      FindText_Screen[hPic].Move(,, w, h)
    FindText_Screen.Show "NA x" x " y" y " w" w " h" h
    oldx:=x, oldy:=y, oldw:=w, oldh:=h
  }
  this.BitmapToWindow(hPic, 0, 0, hBM, 0, 0, w, h)
  DllCall("DeleteObject", "Ptr",hBM)
}

BitmapToWindow(hwnd, x1, y1, hBM, x2, y2, w, h)
{
  mDC:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
  oBM:=DllCall("SelectObject", "Ptr",mDC, "Ptr",hBM, "Ptr")
  hDC:=DllCall("GetDC", "Ptr",hwnd, "Ptr")
  DllCall("BitBlt", "Ptr",hDC, "int",x1, "int",y1, "int",w, "int",h
    , "Ptr",mDC, "int",x2, "int",y2, "uint",0xCC0020)
  DllCall("ReleaseDC", "Ptr",hwnd, "Ptr",hDC)
  DllCall("SelectObject", "Ptr",mDC, "Ptr",oBM)
  DllCall("DeleteDC", "Ptr",mDC)
}

; Quickly get the search data of screen image

GetTextFromScreen(x1, y1, x2, y2, Threshold:=""
  , ScreenShot:=1, &rx:="", &ry:="", cut:=1)
{
  x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  this.GetBitsFromScreen(&x,&y,&w,&h,ScreenShot)
  if (w<1 || h<1)
  {
    return
  }
  gs:=Map(), gs.Default:=0, k:=0
  Loop h
  {
    j:=y+A_Index-1
    Loop w
      i:=x+A_Index-1, c:=this.GetColor(i,j,0)
      , gs[++k]:=(((c>>16)&0xFF)*38+((c>>8)&0xFF)*75+(c&0xFF)*15)>>7
  }
  if InStr(Threshold,"**")
  {
    Threshold:=StrReplace(Threshold,"*")
    if (Threshold="")
      Threshold:=50
    s:="", sw:=w, w-=2, h-=2, x++, y++
    Loop h
    {
      y1:=A_Index
      Loop w
        x1:=A_Index, i:=y1*sw+x1+1, j:=gs[i]+Threshold
        , s.=( gs[i-1]>j || gs[i+1]>j
        || gs[i-sw]>j || gs[i+sw]>j
        || gs[i-sw-1]>j || gs[i-sw+1]>j
        || gs[i+sw-1]>j || gs[i+sw+1]>j ) ? "1":"0"
    }
    Threshold:="**" Threshold
  }
  else
  {
    Threshold:=StrReplace(Threshold,"*")
    if (Threshold="")
    {
      pp:=Map(), pp.Default:=0
      Loop 256
        pp[A_Index-1]:=0
      Loop w*h
        pp[gs[A_Index]]++
      IP0:=IS0:=0
      Loop 256
        k:=A_Index-1, IP0+=k*pp[k], IS0+=pp[k]
      Threshold:=Floor(IP0/IS0)
      Loop 20
      {
        LastThreshold:=Threshold
        IP1:=IS1:=0
        Loop LastThreshold+1
          k:=A_Index-1, IP1+=k*pp[k], IS1+=pp[k]
        IP2:=IP0-IP1, IS2:=IS0-IS1
        if (IS1!=0 && IS2!=0)
          Threshold:=Floor((IP1/IS1+IP2/IS2)/2)
        if (Threshold=LastThreshold)
          Break
      }
    }
    s:=""
    Loop w*h
      s.=gs[A_Index]<=Threshold ? "1":"0"
    Threshold:="*" Threshold
  }
  ;--------------------
  w:=Format("{:d}",w), CutUp:=CutDown:=0
  if (cut=1)
  {
    re1:="(^0{" w "}|^1{" w "})"
    re2:="(0{" w "}$|1{" w "}$)"
    While (s~=re1)
      s:=RegExReplace(s,re1), CutUp++
    While (s~=re2)
      s:=RegExReplace(s,re2), CutDown++
  }
  rx:=x+w//2, ry:=y+CutUp+(h-CutUp-CutDown)//2
  s:="|<>" Threshold "$" w "." this.bit2base64(s)
  ;--------------------
  return s
}

; Wait for the screen image to change within a few seconds
; Take a Screenshot before using it: FindText().ScreenShot()

WaitChange(time:=-1, x1:=0, y1:=0, x2:=0, y2:=0)
{
  hash:=this.GetPicHash(x1, y1, x2, y2, 0)
  time:=this.Floor(time), timeout:=A_TickCount+Round(time*1000)
  Loop
  {
    if (hash!=this.GetPicHash(x1, y1, x2, y2, 1))
      return 1
    if (time>=0 && A_TickCount>=timeout)
      Break
    Sleep 10
  }
  return 0
}

; Wait for the screen image to stabilize

WaitNotChange(time:=1, timeout:=30, x1:=0, y1:=0, x2:=0, y2:=0)
{
  oldhash:="", timeout:=A_TickCount+Round(this.Floor(timeout)*1000)
  Loop
  {
    hash:=this.GetPicHash(x1, y1, x2, y2, 1), t:=A_TickCount
    if (hash!=oldhash)
      oldhash:=hash, timeout2:=t+Round(this.Floor(time)*1000)
    if (t>=timeout2)
      return 1
    if (t>=timeout)
      return 0
    Sleep 10
  }
}

GetPicHash(x1:=0, y1:=0, x2:=0, y2:=0, ScreenShot:=1)
{
  static h:=DllCall("LoadLibrary", "Str","ntdll", "Ptr")
  x1:=this.Floor(x1), y1:=this.Floor(y1), x2:=this.Floor(x2), y2:=this.Floor(y2)
  if (x1=0 && y1=0 && x2=0 && y2=0)
    n:=150000, x:=y:=-n, w:=h:=2*n
  else
    x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  bits:=this.GetBitsFromScreen(&x,&y,&w,&h,ScreenShot,&zx,&zy), x-=zx, y-=zy
  if (w<1 || h<1 || !bits.Scan0)
    return 0
  hash:=0, Stride:=bits.Stride, p:=bits.Scan0+(y-1)*Stride+x*4, w*=4
  Loop h
    hash:=(hash*31+DllCall("ntdll\RtlComputeCrc32", "uint",0
      , "Ptr",p+=Stride, "uint",w, "uint"))&0xFFFFFFFF
  return hash
}

WindowToScreen(&x, &y, x1, y1, id:="")
{
  if (!id)
    id:=WinGetID("A")
  rect:=Buffer(16, 0)
  , DllCall("GetWindowRect", "Ptr",id, "Ptr",rect)
  , x:=x1+NumGet(rect,"int"), y:=y1+NumGet(rect,4,"int")
}

ScreenToWindow(&x, &y, x1, y1, id:="")
{
  this.WindowToScreen(&dx, &dy, 0, 0, id), x:=x1-dx, y:=y1-dy
}

ClientToScreen(&x, &y, x1, y1, id:="")
{
  if (!id)
    id:=WinGetID("A")
  pt:=Buffer(8, 0), NumPut("int64", 0, pt)
  , DllCall("ClientToScreen", "Ptr",id, "Ptr",pt)
  , x:=x1+NumGet(pt,"int"), y:=y1+NumGet(pt,4,"int")
}

ScreenToClient(&x, &y, x1, y1, id:="")
{
  this.ClientToScreen(&dx, &dy, 0, 0, id), x:=x1-dx, y:=y1-dy
}

; It is not like FindText always use Screen Coordinates,
; But like built-in command ImageSearch using CoordMode Settings

ImageSearch(&rx:="", &ry:="", x1:=0, y1:=0, x2:=0, y2:=0
  , ImageFile:="", ScreenShot:=1, FindAll:=0)
{
  dx:=dy:=0
  if (A_CoordModePixel="Window")
    this.WindowToScreen(&dx, &dy, 0, 0)
  else if (A_CoordModePixel="Client")
    this.ClientToScreen(&dx, &dy, 0, 0)
  text:=""
  Loop Parse, ImageFile, "|"
  if (v:=A_LoopField)!=""
  {
    text.=InStr(v,"$") ? "|" v : "|##"
    . (RegExMatch(v, "(?<=^|\s)\*(\d+)", &r) ? r[1]:0)
    . (RegExMatch(v, "i)(?<=^|\s)\*Trans([\-\w]+)", &r) ? "-" r[1]:"")
    . "$" . Trim(RegExReplace(v, "(?<=^|\s)\*\S+"))
  }
  x1:=this.Floor(x1), y1:=this.Floor(y1), x2:=this.Floor(x2), y2:=this.Floor(y2)
  if (x1=0 && y1=0 && x2=0 && y2=0)
    n:=150000, x1:=y1:=-n, x2:=y2:=n
  if (ok:=this.FindText(,, x1+dx, y1+dy, x2+dx, y2+dy
    , 0, 0, text, ScreenShot, FindAll))
  {
    For k,v in ok  ; you can use ok:=FindText().ok
      v.1-=dx, v.2-=dy, v.x-=dx, v.y-=dy
    rx:=ok[1].1, ry:=ok[1].2
    return ok
  }
  else
  {
    rx:=ry:=""
    return 0
  }
}

; It is not like FindText always use Screen Coordinates,
; But like built-in command PixelSearch using CoordMode Settings

PixelSearch(&rx:="", &ry:="", x1:=0, y1:=0, x2:=0, y2:=0
  , ColorID:="", Variation:=0, ScreenShot:=1, FindAll:=0)
{
  text:=""
  Loop Parse, ColorID, "|"
    if (v:=A_LoopField)!=""
      text.=Format("|##{:d}$0/0/{:06X}", Variation, v)
  return this.ImageSearch(&rx, &ry, x1, y1, x2, y2, text, ScreenShot, FindAll)
}

; Pixel count of certain colors within the range indicated by screen coordinates

PixelCount(x1:=0, y1:=0, x2:=0, y2:=0, ColorID:="", Variation:=0, ScreenShot:=1)
{
  x1:=this.Floor(x1), y1:=this.Floor(y1), x2:=this.Floor(x2), y2:=this.Floor(y2)
  if (x1=0 && y1=0 && x2=0 && y2=0)
    n:=150000, x:=y:=-n, w:=h:=2*n
  else
    x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  bits:=this.GetBitsFromScreen(&x,&y,&w,&h,ScreenShot,&zx,&zy), x-=zx, y-=zy
  sum:=0, s1:=Buffer(4), s0:=Buffer(4)
  , ini:={ bits:bits, ss:0, s1:s1.Ptr, s0:s0.Ptr
  , err1:0, err0:0, allpos_max:0, zoomW:1, zoomH:1 }
  if (w>0 && h>0 && bits.Scan0)
    Loop Parse, ColorID, "|"
      if (v:=A_LoopField)!=""
      && IsObject(j:=this.PicInfo(Format("##{:d}$0/0/{:06X}",Variation,v)))
        sum += this.PicFind(ini, j, 1, x, y, w, h, 0)
  return sum
}

Click(x:="", y:="", other1:="", other2:="", GoBack:=0)
{
  CoordMode "Mouse", (bak:=A_CoordModeMouse)?"Screen":"Screen"
  if GoBack
    MouseGetPos &oldx, &oldy
  MouseMove x, y, 0
  Click x "," y "," other1 "," other2
  if GoBack
    MouseMove oldx, oldy, 0
  CoordMode "Mouse", bak
}

; Using ControlClick instead of Click, Use Screen Coordinates,
; If you want to click on the background window, please provide hwnd

ControlClick(x, y, WhichButton:="", ClickCount:=1, Opt:="", hwnd:="")
{
  if !hwnd
    hwnd:=DllCall("WindowFromPoint", "int64",y<<32|x&0xFFFFFFFF, "Ptr")
  pt:=Buffer(8,0), ScreenX:=x, ScreenY:=y
  Loop
  {
    NumPut("int64",0,pt), DllCall("ClientToScreen", "Ptr",hwnd, "Ptr",pt)
    , x:=ScreenX-NumGet(pt,"int"), y:=ScreenY-NumGet(pt,4,"int")
    , id:=DllCall("ChildWindowFromPoint", "Ptr",hwnd, "int64",y<<32|x, "Ptr")
    if (!id || id=hwnd)
      Break
    else hwnd:=id
  }
  DetectHiddenWindows((bak:=A_DetectHiddenWindows)?1:1)
  PostMessage 0x200, 0, y<<16|x, hwnd  ; WM_MOUSEMOVE
  SetControlDelay -1
  ControlClick "x" x " y" y, hwnd,, WhichButton, ClickCount, "NA Pos " Opt
  DetectHiddenWindows(bak)
}

; Running AHK code dynamically with new threads

Class Thread
{
  __New(args*)
  {
    this.pid:=this.Exec(args*)
  }
  __Delete()
  {
    ProcessClose(this.pid)
  }
  Exec(s, Ahk:="", args:="")
  {
    Ahk:=Ahk ? Ahk : A_IsCompiled ? A_ScriptFullPath : A_AhkPath
    add:=A_IsCompiled ? " /script " : ""
    s:="`nDllCall(`"SetWindowText`",`"Ptr`",A_ScriptHwnd,`"Str`",`"<AHK>`")`n"
      . "`n`n" . s, s:=RegExReplace(s, "\R", "`r`n")
    Try
    {
      shell:=ComObject("WScript.Shell")
      oExec:=shell.Exec("`"" Ahk "`"" add " /force /CP0 * " args)
      oExec.StdIn.Write(s)
      oExec.StdIn.Close(), pid:=oExec.ProcessID
    }
    Catch
    {
      f:=A_Temp "\~ahk.tmp"
      s:="`r`nTry FileDelete(`"" f "`")`r`n" s
      Try FileDelete(f)
      FileAppend(s, f)
      r:=this.Clear.Bind(this)
      SetTimer(r, -3000)
      Run "`"" Ahk "`"" add " /force /CP0 `"" f "`" " args,,, &pid
    }
    return pid
  }
  Clear()
  {
    Try FileDelete(A_Temp "\~ahk.tmp")
    SetTimer(,0)
  }
}

; FindText().QPC() Use the same as A_TickCount

QPC()
{
  static f:=0, c:=DllCall("QueryPerformanceFrequency", "Int*",&f)+(f/=1000)
  return (!DllCall("QueryPerformanceCounter", "Int64*",&c))*0+(c/f)
}

; FindText().ToolTip() Use the same as ToolTip

ToolTip(s:="", x:="", y:="", num:=1, arg:="")
{
  static ini:=Map(), tip:=Map(), timer:=Map()
  f:="ToolTip_" . this.Floor(num)
  if (s="")
  {
    ini[f]:=""
    Try tip[f].Destroy()
    return
  }
  ;-----------------
  r1:=A_CoordModeToolTip
  r2:=A_CoordModeMouse
  CoordMode "Mouse", "Screen"
  MouseGetPos &x1, &y1
  CoordMode "Mouse", r1
  MouseGetPos &x2, &y2
  CoordMode "Mouse", r2
  (x!="" && x:="x" (this.Floor(x)+x1-x2))
  , (y!="" && y:="y" (this.Floor(y)+y1-y2))
  , (x="" && y="" && x:="x" (x1+16) " y" (y1+16))
  ;-----------------
  (!IsObject(arg) && arg:={})
  bgcolor:=arg.HasProp("bgcolor") ? arg.bgcolor : "FAFBFC"
  color:=arg.HasProp("color") ? arg.color : "Black"
  font:=arg.HasProp("font") ? arg.font : "Consolas"
  size:=arg.HasProp("size") ? arg.size : "10"
  bold:=arg.HasProp("bold") ? arg.bold : ""
  trans:=arg.HasProp("trans") ? arg.trans & 255 : 255
  timeout:=arg.HasProp("timeout") ? arg.timeout : ""
  ;-----------------
  r:=bgcolor "|" color "|" font "|" size "|" bold "|" trans "|" s
  if (!ini.Has(f) || ini[f]!=r)
  {
    ini[f]:=r
    Try tip[f].Destroy()
    tip[f]:=_Gui:=Gui()  ; WS_EX_LAYERED:=0x80000, WS_EX_TRANSPARENT:=0x20
    _Gui.Opt "+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x80020"
    _Gui.MarginX:=2, _Gui.MarginY:=2
    _Gui.BackColor:=bgcolor
    _Gui.SetFont "c" color " s" size " " bold, font
    _Gui.Add "Text",, s
    _Gui.Title:=f
    _Gui.Show "Hide"
    ;------------------
    DetectHiddenWindows((bak:=A_DetectHiddenWindows)?1:1)
    WinSetTransparent(trans, _Gui.Hwnd)
    DetectHiddenWindows(bak)
  }
  else _Gui:=tip[f]
  _Gui.Opt "+AlwaysOnTop"
  _Gui.Show "NA " x " " y
  if (timeout)
  {
    (!timer.Has(f) && timer[f]:=this.ToolTip.Bind(this,"","","",num))
    SetTimer(timer[f], -Round(Abs(this.Floor(timeout)*1000))-1)
  }
}

; FindText().ObjView()  view object values for Debug

ObjView(obj, keyname:="")
{
  static Gui_DeBug_Gui:=""
  if IsObject(obj)
  {
    s:=""
    For k,v in (HasMethod(obj,"__Enum") ? obj : obj.OwnProps())
      s.=this.ObjView(v, keyname "[" (k is Number ? k : "`"" k "`"") "]")
  }
  else
    s:=keyname ": " (obj is Number ? obj : "`"" obj "`"") "`n"
  if (keyname!="")
    return s
  ;------------------
  Try Gui_DeBug_Gui.Destroy()
  Gui_DeBug_Gui:=_Gui:=Gui()
  _Gui.Opt "+LastFound +AlwaysOnTop"
  _Gui.Add("Button", "y270 w350 Default", "OK").OnEvent("Click", (*) => WinHide())
  _Gui.Add "Edit", "xp y10 w350 h250 -Wrap -WantReturn"
  _Gui["Edit1"].Value:=s
  _Gui.Title:="Debug view object values"
  _Gui.Show
  DetectHiddenWindows(0)
  WinWaitClose "ahk_id " WinExist()
  _Gui.Destroy
}

; Get Script from Compiled programs

GetScript()  ; thanks TAC109
{
  if (!A_IsCompiled)
    return
  For i,ahk in ["#1", ">AUTOHOTKEY SCRIPT<"]
  if (rc:=DllCall("FindResource", "Ptr",0, "Str",ahk, "Ptr",10, "Ptr"))
  && (sz:=DllCall("SizeofResource", "Ptr",0, "Ptr",rc, "Uint"))
  && (pt:=DllCall("LoadResource", "Ptr",0, "Ptr",rc, "Ptr"))
  && (pt:=DllCall("LockResource", "Ptr",pt, "Ptr"))
  && (DllCall("VirtualProtect", "Ptr",pt, "Ptr",sz, "UInt",0x4, "UInt*",0))
  && (InStr(StrGet(pt, 20, "utf-8"), "<COMPILER"))
    return this.FormatScript(StrGet(pt, sz, "utf-8"))
}

FormatScript(s, space:="", tab:="    ")
{
  ListLines((lls:=A_ListLines)?0:0)
  VarSetStrCapacity(&ss, StrLen(s)*2), n:=0, w:=StrLen(tab)
  , space2:=StrReplace(Format("{:020d}",0), "0", tab)
  Loop Parse, s, "`n", "`r"
  {
    v:=Trim(A_LoopField), n2:=n
    if RegExMatch(v, "^\s*[{}][\s{}]*|\{\s*$|\{\s+;", &r)
      n+=w*(StrLen(RegExReplace(r[0], "[^{]"))
      -StrLen(RegExReplace(r[0], "[^}]"))), n2:=Min(n,n2)
    ss.=Space . SubStr(space2,1,n2) . v . "`r`n"
  }
  ListLines(lls)
  return SubStr(ss,1,-2)
}

; Get Gui object from Gui.Name

GuiFromName(GuiName:="")
{
  DetectHiddenWindows((bak:=A_DetectHiddenWindows)?1:1)
  List:=WinGetList("ahk_class AutoHotkeyGUI ahk_pid " DllCall("GetCurrentProcessId"))
  DetectHiddenWindows(bak)
  For id in List
    Try if (_Gui:=GuiFromHwnd(id)) && (_Gui.Name=GuiName)
      return _Gui
}

; Get Last GuiControl object from Gui.Opt("+LastFound")

LastCtrl()
{
  For Ctrl in GuiFromHwnd(WinExist())
    last:=Ctrl
  return last
}

; Hide Gui from Gui.Opt("+LastFound")

Hide(id:="")
{
  if WinExist("ahk_id " id) || WinExist()
  {
    WinMinimize
    WinHide
    ToolTip
    DetectHiddenWindows(0)
    WinWaitClose "ahk_id " WinExist()
  }
}


;==== Optional GUI interface ====


Gui(cmd, arg1:="", args*)
{
  static
  local cri, lls
  (InStr("MouseMove|ToolTipOff", cmd) && ListLines(0))
  static init:=0
  if (!init)
  {
    init:=1
    Gui_ := this.Gui.Bind(this)
    Gui_G := this.Gui.Bind(this, "G")
    Gui_Run := this.Gui.Bind(this, "Run")
    Gui_Off := this.Gui.Bind(this, "Off")
    Gui_Show := this.Gui.Bind(this, "Show")
    Gui_KeyDown := this.Gui.Bind(this, "KeyDown")
    Gui_LButtonDown := this.Gui.Bind(this, "LButtonDown")
    Gui_MouseMove := this.Gui.Bind(this, "MouseMove")
    Gui_ScreenShot := this.Gui.Bind(this, "ScreenShot")
    Gui_ShowPic := this.Gui.Bind(this, "ShowPic")
    Gui_Slider := this.Gui.Bind(this, "Slider")
    Gui_ToolTip := this.Gui.Bind(this, "ToolTip")
    Gui_ToolTipOff := this.Gui.Bind(this, "ToolTipOff")
    Gui_SaveScr := this.Gui.Bind(this, "SaveScr")
    Gui_SetColor := this.Gui.Bind(this, "SetColor")
    FindText_Capture:=FindText_Main:=""
    FindText_HotkeyIf:=FindText_SelectPic:=FindText_Tip:=""
    cri:=A_IsCritical
    Critical
    Lang:=this.Lang(,1), Tip_Text:=this.Lang(,2)
    Gui_("MakeCaptureWindow")
    Gui_("MakeMainWindow")
    OnMessage(0x100, Gui_KeyDown)
    OnMessage(0x201, Gui_LButtonDown)
    OnMessage(0x200, Gui_MouseMove)
    A_TrayMenu.Add
    A_TrayMenu.Add Lang["s1"], Gui_Show
    if (!A_IsCompiled && A_LineFile=A_ScriptFullPath)
    {
      A_TrayMenu.Default:=Lang["s1"]
      A_TrayMenu.ClickCount:=1
      TraySetIcon "Shell32.dll", 23
    }
    Critical(cri)
    _Gui:=Gui("+LastFound")
    _Gui.Destroy
  }
  Switch cmd
  {
  Case "Off":
    return hk:=Trim(A_ThisHotkey, "*")
  Case "G":
    id:=this.LastCtrl()
    Try id.OnEvent("Click", Gui_Run)
    Try id.OnEvent("Change", Gui_Run)
    return
  Case "Run":
    Critical
    Gui_(arg1.Name)
    return
  Case "Show":
    FindText_Main.Show(arg1 ? "Center" : "")
    ControlFocus(hscr)
    return
  Case "Cancel", "Cancel2":
    WinHide
    return
  Case "MakeCaptureWindow":
    WindowColor:="0xDDEEFF"
    Try FindText_Capture.Destroy()
    FindText_Capture:=_Gui:=Gui()
    _Gui.Opt "+LastFound +AlwaysOnTop -DPIScale"
    _Gui.MarginX:=15, _Gui.MarginY:=15
    _Gui.BackColor:=WindowColor
    _Gui.SetFont "s12", "Verdana"
    ww:=35, hh:=12, nW:=71, nH:=25, w:=h:=12
    w:=nW*w, h:=(nH+1)*h
    _Gui.Add "Text", "w" w " h" h
    _Gui.Add "Slider", "xm w" w " vMySlider1 Disabled"
      . " +Center Page20 Line10 NoTicks AltSubmit"
    Gui_G()
    _Gui.Add "Slider", "ym h" h " vMySlider2 Disabled"
      . " +Center Page20 Line10 NoTicks AltSubmit +Vertical"
    Gui_G()
    this.LastCtrl().GetPos(&pX, &pY, &pW, &pH)
    k:=pX+pW, MySlider1:=MySlider2:=dx:=dy:=0
    ;--------------
    _Gui.Add "Button", "xm Hidden Section", Lang["Auto"]
    this.LastCtrl().GetPos(&pX, &pY, &pW, &pH)
    w:=Round(pW*0.75), i:=Round(w*3+15+pW*0.5-w*1.5)
    _Gui.Add "Button", "xm+" i " yp w" w " hp -Wrap vRepU", Lang["RepU"]
    Gui_G()
    _Gui.Add "Button", "x+0 wp hp -Wrap vCutU", Lang["CutU"]
    Gui_G()
    _Gui.Add "Button", "x+0 wp hp -Wrap vCutU3", Lang["CutU3"]
    Gui_G()
    _Gui.Add "Button", "xm wp hp -Wrap vRepL", Lang["RepL"]
    Gui_G()
    _Gui.Add "Button", "x+0 wp hp -Wrap vCutL", Lang["CutL"]
    Gui_G()
    _Gui.Add "Button", "x+0 wp hp -Wrap vCutL3", Lang["CutL3"]
    Gui_G()
    _Gui.Add "Button", "x+15 w" pW " hp -Wrap vAuto", Lang["Auto"]
    Gui_G()
    _Gui.Add "Button", "x+15 w" w " hp -Wrap vRepR", Lang["RepR"]
    Gui_G()
    _Gui.Add "Button", "x+0 wp hp -Wrap vCutR", Lang["CutR"]
    Gui_G()
    _Gui.Add "Button", "x+0 wp hp -Wrap vCutR3", Lang["CutR3"]
    Gui_G()
    _Gui.Add "Button", "xm+" i " wp hp -Wrap vRepD", Lang["RepD"]
    Gui_G()
    _Gui.Add "Button", "x+0 wp hp -Wrap vCutD", Lang["CutD"]
    Gui_G()
    _Gui.Add "Button", "x+0 wp hp -Wrap vCutD3", Lang["CutD3"]
    Gui_G()
    ;--------------
    _Gui.Add "Text", "x+60 ys+3 Section", Lang["SelGray"]
    _Gui.Add "Edit", "x+3 yp-3 w60 vSelGray ReadOnly"
    _Gui.Add "Text", "x+15 ys", Lang["SelColor"]
    _Gui.Add "Edit", "x+3 yp-3 w150 vSelColor ReadOnly"
    _Gui.Add "Text", "x+15 ys", Lang["SelR"]
    _Gui.Add "Edit", "x+3 yp-3 w60 vSelR ReadOnly"
    _Gui.Add "Text", "x+5 ys", Lang["SelG"]
    _Gui.Add "Edit", "x+3 yp-3 w60 vSelG ReadOnly"
    _Gui.Add "Text", "x+5 ys", Lang["SelB"]
    _Gui.Add "Edit", "x+3 yp-3 w60 vSelB ReadOnly"
    ;--------------
    x:=w*6+pW+15*4
    Tab:=_Gui.Add("Tab3", "x" x " y+15 -Wrap", StrSplit(Lang["s2"],"|"))
    Tab.UseTab(1)
    _Gui.Add "Text", "x+15 y+15", Lang["Threshold"]
    _Gui.Add "Edit", "x+15 w100 vThreshold"
    _Gui.Add "Button", "x+15 yp-3 vGray2Two", Lang["Gray2Two"]
    Gui_G()
    Tab.UseTab(2)
    _Gui.Add "Text", "x+15 y+15", Lang["GrayDiff"]
    _Gui.Add "Edit", "x+15 w100 vGrayDiff", "50"
    _Gui.Add "Button", "x+15 yp-3 vGrayDiff2Two", Lang["GrayDiff2Two"]
    Gui_G()
    Tab.UseTab(3)
    _Gui.Add "Text", "x+15 y+15", Lang["Similar1"] " 0"
    _Gui.Add "Slider", "x+0 w120 vSimilar1 +Center Page1 NoTicks ToolTip", 100
    Gui_G()
    _Gui.Add "Text", "x+0", "100"
    _Gui.Add "Button", "x+15 yp-3 vColor2Two", Lang["Color2Two"]
    Gui_G()
    Tab.UseTab(4)
    _Gui.Add "Text", "x+15 y+15", Lang["Similar2"] " 0"
    _Gui.Add "Slider", "x+0 w120 vSimilar2 +Center Page1 NoTicks ToolTip", 100
    Gui_G()
    _Gui.Add "Text", "x+0", "100"
    _Gui.Add "Button", "x+15 yp-3 vColorPos2Two", Lang["ColorPos2Two"]
    Gui_G()
    Tab.UseTab(5)
    _Gui.Add "Text", "x+10 y+15", Lang["DiffR"]
    _Gui.Add "Edit", "x+5 w80 vDiffR Limit3"
    _Gui.Add "UpDown", "vdR Range0-255 Wrap"
    _Gui.Add "Text", "x+5", Lang["DiffG"]
    _Gui.Add "Edit", "x+5 w80 vDiffG Limit3"
    _Gui.Add "UpDown", "vdG Range0-255 Wrap"
    _Gui.Add "Text", "x+5", Lang["DiffB"]
    _Gui.Add "Edit", "x+5 w80 vDiffB Limit3"
    _Gui.Add "UpDown", "vdB Range0-255 Wrap"
    _Gui.Add "Button", "x+15 yp-3 vColorDiff2Two", Lang["ColorDiff2Two"]
    Gui_G()
    Tab.UseTab(6)
    _Gui.Add "Text", "x+10 y+15", Lang["DiffRGB"]
    _Gui.Add "Edit", "x+5 w80 vDiffRGB Limit3"
    _Gui.Add "UpDown", "vdRGB Range0-255 Wrap"
    _Gui.Add "Checkbox", "x+15 yp+5 vMultiColor", Lang["MultiColor"]
    Gui_G()
    _Gui.Add "Button", "x+15 yp-5 vUndo", Lang["Undo"]
    Gui_G()
    Tab.UseTab()
    ;--------------
    _Gui.Add "Button", "xm vReset", Lang["Reset"]
    Gui_G()
    _Gui.Add "Checkbox", "x+15 yp+5 vModify", Lang["Modify"]
    Gui_G()
    _Gui.Add "Text", "x+30", Lang["Comment"]
    _Gui.Add "Edit", "x+5 yp-2 w150 vComment"
    _Gui.Add "Button", "x+10 yp-3 vSplitAdd", Lang["SplitAdd"]
    Gui_G()
    _Gui.Add "Button", "x+10 vAllAdd", Lang["AllAdd"]
    Gui_G()
    _Gui.Add "Button", "x+10 wp vOK", Lang["OK"]
    Gui_G()
    _Gui.Add "Button", "x+10 wp vCancel", Lang["Cancel"]
    Gui_G()
    _Gui.Add "Button", "xm vBind0", Lang["Bind0"]
    Gui_G()
    _Gui.Add "Button", "x+10 vBind1", Lang["Bind1"]
    Gui_G()
    _Gui.Add "Button", "x+10 vBind2", Lang["Bind2"]
    Gui_G()
    _Gui.Add "Button", "x+10 vBind3", Lang["Bind3"]
    Gui_G()
    _Gui.Add "Button", "x+10 vBind4", Lang["Bind4"]
    Gui_G()
    _Gui.Add "Button", "x+30 vSave", Lang["Save"]
    Gui_G()
    _Gui.Opt "-Theme"
    w:=h:=12, C_:=Map(), C_.Default:=0
    Loop nW*(nH+1)
    {
      i:=A_Index, j:=i=1 ? "xm ym" : Mod(i,nW)=1 ? "xm y+0":"x+0"
      id:=_Gui.Add("Progress", j " w" w " h" h " -E0x20000 Smooth")
      C_[i]:=id.Hwnd
    }
    _Gui.Opt "+Theme"
    _Gui.Title:=Lang["s3"]
    _Gui.Show "Hide"
    return
  Case "MakeMainWindow":
    Try FindText_Main.Destroy()
    FindText_Main:=_Gui:=Gui()
    _Gui.Opt "+LastFound +AlwaysOnTop -DPIScale"
    _Gui.MarginX:=15, _Gui.MarginY:=10
    _Gui.BackColor:=WindowColor
    _Gui.SetFont "s12", "Verdana"
    _Gui.Add "Text", "xm", Lang["NowHotkey"]
    _Gui.Add "Edit", "x+5 w200 vNowHotkey ReadOnly"
    _Gui.Add "Hotkey", "x+5 w200 vSetHotkey1"
    s:="F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|LWin|MButton"
      . "|ScrollLock|CapsLock|Ins|Esc|BS|Del|Tab|Home|End|PgUp|PgDn"
      . "|NumpadDot|NumpadSub|NumpadAdd|NumpadDiv|NumpadMult"
    _Gui.Add "DDL", "x+5 w180 vSetHotkey2", StrSplit(s,"|")
    _Gui.Add "GroupBox", "xm y+0 w280 h55 vMyGroup cBlack"
    _Gui.Add "Text", "xp+15 yp+20 Section", Lang["Myww"] ": "
    _Gui.Add "Text", "x+0 w80", ww
    _Gui.Add "UpDown", "vMyww Range1-100", ww
    _Gui.Add "Text", "x+15 ys", Lang["Myhh"] ": "
    _Gui.Add "Text", "x+0 w80", hh
    _Gui.Add "UpDown", "vMyhh Range1-100", hh
    this.LastCtrl().GetPos(&pX, &pY, &pW, &pH)
    _Gui["MyGroup"].Move(,, pX+pW, pH+30)
    x:=pX+pW+15*2
    _Gui.Add "Button", "x" x " ys-5 vApply", Lang["Apply"]
    Gui_G()
    _Gui.Add "Checkbox", "x+30 ys vAddFunc", Lang["AddFunc"] " FindText()"
    this.LastCtrl().GetPos(&pX, &pY, &pW, &pH)
    pW:=pX+pW-15, pW:=(pW<720?720:pW), w:=pW//5
    _Gui.Add "Button", "xm y+18 w" w " vCutL2", Lang["CutL2"]
    Gui_G()
    _Gui.Add "Button", "x+0 wp vCutR2", Lang["CutR2"]
    Gui_G()
    _Gui.Add "Button", "x+0 wp vCutU2", Lang["CutU2"]
    Gui_G()
    _Gui.Add "Button", "x+0 wp vCutD2", Lang["CutD2"]
    Gui_G()
    _Gui.Add "Button", "x+0 wp vUpdate", Lang["Update"]
    Gui_G()
    _Gui.SetFont "s6 bold", "Verdana"
    _Gui.Add "Edit", "xm y+10 w" pW " h260 vMyPic -Wrap"
    _Gui.SetFont "s12 norm", "Verdana"
    w:=pW//3
    _Gui.Add "Button", "xm w" w " vCapture", Lang["Capture"]
    Gui_G()
    _Gui.Add "Button", "x+0 wp vTest", Lang["Test"]
    Gui_G()
    _Gui.Add "Button", "x+0 wp vCopy", Lang["Copy"]
    Gui_G()
    _Gui.Add "Button", "xm y+0 wp vCaptureS", Lang["CaptureS"]
    Gui_G()
    _Gui.Add "Button", "x+0 wp vGetRange", Lang["GetRange"]
    Gui_G()
    _Gui.Add "Button", "x+0 wp vGetOffset", Lang["GetOffset"]
    Gui_G()
    _Gui.Add "Edit", "xm y+10 w130 hp vClipText"
    _Gui.Add "Button", "x+0 vPaste", Lang["Paste"]
    Gui_G()
    _Gui.Add "Button", "x+0 vTestClip", Lang["TestClip"]
    Gui_G()
    _Gui.Add "Button", "x+0 vGetClipOffset", Lang["GetClipOffset"]
    Gui_G()
    r:=pW
    this.LastCtrl().GetPos(&pX, &pY, &pW, &pH)
    w:=((r+15)-(pX+pW))//2, pW:=r
    _Gui.Add "Edit", "x+0 w" w " hp vOffset"
    _Gui.Add "Button", "x+0 wp vCopyOffset", Lang["CopyOffset"]
    Gui_G()
    _Gui.SetFont "cBlue"
    _Gui.Add "Edit", "xm w" pW " h250 vscr -Wrap HScroll"
    hscr:=this.LastCtrl().Hwnd
    _Gui.Title:=Lang["s4"]
    _Gui.Show "Hide"
    Gui_("LoadScr")
    OnExit(Gui_SaveScr)
    return
  Case "LoadScr":
    f:=A_Temp "\~scr2.tmp"
    Try s:="", s:=FileRead(f)
    FindText_Main["scr"].Value:=s
    return
  Case "SaveScr":
    f:=A_Temp "\~scr2.tmp"
    s:=FindText_Main["scr"].Value
    Try FileDelete(f)
    FileAppend(s, f)
    return
  Case "Capture", "CaptureS":
    id:=FindText_Main.Hwnd
    if WinExist()!=id
      return this.GetRange()
    this.Hide()
    if (ShowScreenShot:=InStr(cmd, "CaptureS"))
    {
      this.ScreenShot(), f:=Gui_("SelectPic")
      if (f="") || !FileExist(f)
        return Gui_Show()
      this.ShowPic(f)
    }
    w:=FindText_Main["Myww"].Value
    h:=FindText_Main["Myhh"].Value
    p:=this.GetRange(w, h)
    if (ShowScreenShot)
      this.ShowPic()
    px:=(p[1]+p[3])//2, py:=(p[2]+p[4])//2
    , ww:=(p[3]-p[1])//2, hh:=(p[4]-p[2])//2
    , Bind_ID:=p[5], oldx:=oldy:=""
    ;-----------------------
    nW:=71, nH:=25, dx:=dy:=0, c:=WindowColor
    c:=((c&0xFF)<<16)|(c&0xFF00)|((c&0xFF0000)>>16)
    ListLines((lls:=A_ListLines)?0:0)
    Loop nW*(nH+1)
      SendMessage 0x2001, 0, (A_Index>nW*nH ? 0xAAFFFF:c), C_[A_Index]
    ListLines(lls)
    nW:=2*ww+1, nH:=2*hh+1
    _Gui:=FindText_Capture
    _Gui["MySlider1"].Enabled:=nW>71
    _Gui["MySlider2"].Enabled:=nH>25
    _Gui["MySlider1"].Value:=MySlider1:=0
    _Gui["MySlider2"].Value:=MySlider2:=0
    ;------------------------
    Gui_("getcors", !ShowScreenShot), Gui_("Reset")
    Loop Parse, "SelGray|SelColor|SelR|SelG|SelB|Threshold|Comment", "|"
      _Gui[A_LoopField].Value:=""
    _Gui["Modify"].Value:=Modify:=0
    _Gui["MultiColor"].Value:=MultiColor:=0
    _Gui["GrayDiff"].Value:=50
    _Gui["Gray2Two"].Focus()
    _Gui["Gray2Two"].Opt("+Default")
    _Gui.Opt "+LastFound"
    _Gui.Show "Center"
    Event:=Result:=""
    DetectHiddenWindows(0)
    Critical "Off"
    WinWaitClose "ahk_id " WinExist()
    Critical
    ToolTip
    _Gui:=FindText_Main
    ;--------------------------------
    if (cors.HasProp("bind") && cors.bind!="")
    {
      tt:=WinGetTitle(Bind_ID)
      tc:=WinGetClass(Bind_ID)
      tt:=Trim(SubStr(tt,1,30) (tc ? " ahk_class " tc:""))
      tt:=StrReplace(RegExReplace(tt, "[;``]", "``$0"), "`"","```"")
      Result:="`nSetTitleMatchMode 2`nid:=WinExist(`"" tt "`")"
        . "`nFindText().BindWindow(id" (cors.bind=0 ? "":"," cors.bind)
        . ")  `; " Lang["s6"] " FindText().BindWindow(0)`n`n" Result
    }
    if (Event="OK")
    {
      if (!A_IsCompiled)
        s:=FileRead(A_LineFile)
      else
        s:=this.GetScript()
      re:="i)\n\s*FindText[^\n]+args\*[\s\S]*?Script_End[(){\s]+}"
      if RegExMatch(s, re, &r)
        s:="`n;==========`n" r[0] "`n"
      _Gui["scr"].Value:=Result "`n" s
      _Gui["MyPic"].Value:=Trim(this.ASCII(Result),"`n")
      Result:=s:=""
    }
    else if (Event="SplitAdd") || (Event="AllAdd")
    {
      s:=_Gui["scr"].Value
      r:=SubStr(s, 1, InStr(s,"=FindText("))
      i:=j:=0, re:="<[^>\n]*>[^$\n]+\$[^`"'\r\n]+"
      While j:=RegExMatch(r, re,, j+1)
        i:=InStr(r, "`n", 0, j)
      _Gui["scr"].Value:=SubStr(s,1,i) . Result . SubStr(s,i+1)
      _Gui["MyPic"].Value:=Trim(this.ASCII(Result),"`n")
      Result:=s:=""
    }
    ;----------------------
    Gui_Show()
    return
  Case "SelectPic":
    static Pics:=""
    if IsObject(Pics)
      return
    Pics:=[], Names:=[], s:=""
    Loop Files, A_Temp "\Ahk_ScreenShot\*.bmp"
      Pics.Push(LoadPicture(v:=A_LoopFileFullPath))
      , Names.Push(v), s.="|" RegExReplace(v,"i)^.*\\|\.bmp$")
    Try FindText_SelectPic.Destroy()
    FindText_SelectPic:=_Gui:=Gui()
    _Gui.Name:="FindText_SelectPic"
    _Gui.Opt "+LastFound +AlwaysOnTop -DPIScale"
    _Gui.MarginX:=15, _Gui.MarginY:=15
    _Gui.SetFont "s12", "Verdana"
    id:=_Gui.Add("Pic", "w800 h500 +Border"), hPic:=id.Hwnd
    _Gui.Add "ListBox", "x+15 w120 hp vSelectBox"
      . " AltSubmit 0x100 Choose1", StrSplit(Trim(s,"|"),"|")
    Gui_G()
    _Gui.Add "Button", "xm w170 vOK2 Default", Lang["OK2"]
    Gui_G()
    _Gui.Add "Button", "x+15 wp vCancel2", Lang["Cancel2"]
    Gui_G()
    _Gui.Add "Button", "x+15 wp vClearAll", Lang["ClearAll"]
    Gui_G()
    _Gui.Add "Button", "x+15 wp vOpenDir", Lang["OpenDir"]
    Gui_G()
    _Gui.Add "Button", "x+15 wp vSavePic", Lang["SavePic"]
    Gui_G()
    _Gui["SelectBox"].Focus()
    Gui_("SelectBox")
    _Gui.Title:="Select ScreenShot"
    _Gui.Show
    ;-----------------------
    DetectHiddenWindows(0)
    Critical "Off"
    SelectFile:=""
    WinWaitClose "ahk_id " WinExist()
    Critical
    FindText_SelectPic.Destroy
    Loop Pics.Length
      DllCall("DeleteObject", "Ptr",Pics[A_Index])
    Pics:="", Names:=""
    return SelectFile
  Case "SavePic":
    SelectBox:=FindText_SelectPic["SelectBox"].Value
    Try f:="", f:=Names[SelectBox]
    FindText_SelectPic.Hide
    this.ShowPic(f)
    pos:=this.SnapShot(0)
    Gui_("ScreenShot", pos[1] "|" pos[2] "|" pos[3] "|" pos[4] "|0")
    this.ShowPic()
    return
  Case "SelectBox":
    SelectBox:=FindText_SelectPic["SelectBox"].Value
    Try hBM:="", hBM:=Pics[SelectBox]
    if (hBM)
    {
      this.GetBitmapWH(hBM, &w, &h)
      FindText_SelectPic[hPic].Value:="*W" (w<800?0:800)
        . " *H" (h<500?0:500) " HBITMAP:*" hBM
    }
    return
  Case "OK2":
    SelectBox:=FindText_SelectPic["SelectBox"].Value
    Try SelectFile:="", SelectFile:=Names[SelectBox]
    FindText_SelectPic.Hide
    return
  Case "ClearAll":
    Try FileDelete(A_Temp "\Ahk_ScreenShot\*.bmp")
    FindText_SelectPic.Hide
    return
  Case "OpenDir":
    Run(A_Temp "\Ahk_ScreenShot\")
    return
  Case "getcors":
    x:=px-ww, y:=py-hh, w:=2*ww+1, h:=2*hh+1
    this.GetBitsFromScreen(&x,&y,&w,&h,arg1)
    if (w<1 || h<1)
      return
    cors:=Map(), cors.Default:=0, gray:=Map(), gray.Default:=0, k:=0, j:=py-hh-1
    ListLines((lls:=A_ListLines)?0:0)
    Loop nH
    {
      j++, i:=px-ww
      Loop nW
        cors[++k]:=c:=this.GetColor(i++,j,0)
        , gray[k]:=(((c>>16)&0xFF)*38+((c>>8)&0xFF)*75+(c&0xFF)*15)>>7
    }
    ListLines(lls)
    cors.CutLeft:=Abs(px-ww-x)
    cors.CutRight:=Abs(px+ww-(x+w-1))
    cors.CutUp:=Abs(py-hh-y)
    cors.CutDown:=Abs(py+hh-(y+h-1))
    return
  Case "GetRange":
    FindText_Main.Opt "+LastFound"
    this.Hide()
    p:=this.SnapShot(), v:=p[1] ", " p[2] ", " p[3] ", " p[4]
    s:=FindText_Main["scr"].Value
    re:="i)(=FindText\([^\n]*?)([^(,\n]*,){4}([^,\n]*,[^,\n]*,[^,\n]*Text)"
    if SubStr(s,1,s~="i)\n\s*FindText[^\n]+args\*")~=re
    {
      s:=RegExReplace(s, re, "$1 " v ",$3",, 1)
      FindText_Main["scr"].Value:=s
    }
    FindText_Main["Offset"].Value:=v
    Gui_Show()
    return
  Case "Test", "TestClip":
    FindText_Main.Opt "+LastFound"
    this.Hide()
    ;----------------------
    if (cmd="Test")
      s:=FindText_Main["scr"].Value
    else
      s:=FindText_Main["ClipText"].Value
    if (cmd="Test") && InStr(s, "MCode(")
    {
      s:="`nA_TrayMenu.ClickCount:=1`n" s "`nExitApp`n"
      Thread1:=FindTextClass.Thread(s)
      DetectHiddenWindows(1)
      if WinWait("ahk_class AutoHotkey ahk_pid " Thread1.pid,, 3)
        WinWaitClose(,, 30)
      ; Thread1:=""  ; kill the Thread
    }
    else
    {
      t:=A_TickCount, v:=X:=Y:=""
      if RegExMatch(s, "<[^>\n]*>[^$\n]+\$[^`"'\r\n]+", &r)
        v:=this.FindText(&X, &Y, 0,0,0,0, 0,0, r[0])
      r:=StrSplit(Lang["s8"] "||||", "|")
      MsgBox(r[1] ":`t" (IsObject(v)?v.Length:v) "`n`n"
        . r[2] ":`t" (A_TickCount-t) " " r[3] "`n`n"
        . r[4] ":`t" X ", " Y "`n`n"
        . r[5] ":`t<" (IsObject(v)?v[1].id:"") ">", "Tip", "4096 T3")
      Try For i,j in v
        if (i<=2)
          this.MouseTip(j.x, j.y)
      v:="", A_Clipboard:=X "," Y
    }
    ;----------------------
    Gui_Show()
    return
  Case "GetOffset", "GetClipOffset":
    FindText_Main.Hide
    p:=this.GetRange()
    if (cmd="GetOffset")
      s:=FindText_Main["scr"].Value
    else
      s:=FindText_Main["ClipText"].Value
    if RegExMatch(s, "<[^>\n]*>[^$\n]+\$[^`"'\r\n]+", &r)
    && this.FindText(&X, &Y, 0,0,0,0, 0,0, r[0])
    {
      r:=StrReplace("X+" ((p[1]+p[3])//2-X)
        . ", Y+" ((p[2]+p[4])//2-Y), "+-", "-")
      if (cmd="GetOffset")
      {
        re:="i)(\(\)\.\w*Click\w*\()[^,\n]*,[^,)\n]*"
        if SubStr(s,1,s~="i)\n\s*FindText[^\n]+args\*")~=re
          s:=RegExReplace(s, re, "$1" r,, 1)
        FindText_Main["scr"].Value:=s
      }
      else
        FindText_Main["Offset"].Value:=r
    }
    s:="", Gui_Show()
    return
  Case "Paste":
    if RegExMatch(A_Clipboard, "<[^>\n]*>[^$\n]+\$[^`"'\r\n]+", &r)
    {
      FindText_Main["ClipText"].Value:=r[0]
      FindText_Main["MyPic"].Value:=Trim(this.ASCII(r[0]),"`n")
    }
    return
  Case "CopyOffset":
    s:=FindText_Main["Offset"].Value
    A_Clipboard:=s
    return
  Case "Copy":
    s:=EditGetSelectedText(hscr)
    if (s="")
    {
      s:=FindText_Main["scr"].Value
      r:=FindText_Main["AddFunc"].Value
      if (r != 1)
        s:=RegExReplace(s, "i)\n\s*FindText[^\n]+args\*[\s\S]*")
        , s:=RegExReplace(s, "i)\n; ok:=FindText[\s\S]*")
        , s:=SubStr(s, (s~="i)\n[ \t]*Text"))
    }
    A_Clipboard:=RegExReplace(s, "\R", "`r`n")
    ControlFocus(hscr)
    return
  Case "Apply":
    _Gui:=FindText_Main
    NowHotkey:=_Gui["NowHotkey"].Value
    SetHotkey1:=_Gui["SetHotkey1"].Value
    SetHotkey2:=_Gui["SetHotkey2"].Text
    if (NowHotkey!="")
      Try Hotkey "*" NowHotkey,, "Off"
    k:=SetHotkey1!="" ? SetHotkey1 : SetHotkey2
    if (k!="")
      Try Hotkey "*" k, Gui_ScreenShot, "On"
    _Gui["NowHotkey"].Value:=k
    _Gui["SetHotkey1"].Value:=""
    _Gui["SetHotkey2"].Choose(0)
    return
  Case "ScreenShot":
    Critical
    f:=A_Temp "\Ahk_ScreenShot"
    if !InStr(r:=FileExist(f), "D")
    {
      if (r)
      {
        FileSetAttrib("-R", f)
        FileDelete(f)
      }
      DirCreate(f)
    }
    Loop
      f:=A_Temp "\Ahk_ScreenShot\" Format("{:03d}",A_Index) ".bmp"
    Until !FileExist(f)
    this.SavePic(f, StrSplit(arg1,"|")*)
    CoordMode "ToolTip"
    this.ToolTip(Lang["s9"],, 0,, { bgcolor:"Yellow", color:"Red"
      , size:48, bold:"bold", trans:200, timeout:0.2 })
    return
  Case "Bind0", "Bind1", "Bind2", "Bind3", "Bind4":
    this.BindWindow(Bind_ID, bind_mode:=SubStr(cmd,5))
    ;-----------------
    Try FindText_HotkeyIf.Destroy()
    FindText_HotkeyIf:=_Gui:=Gui()
    _Gui.Opt "-Caption +ToolWindow +E0x80000"
    _Gui.Title:="FindText_HotkeyIf"
    _Gui.Show "NA x0 y0 w0 h0"
    ;-----------------
    key:="RButton"
    KeyWait key
    KeyWait "Ctrl"
    HotIfWinExist "FindText_HotkeyIf"
    Try Hotkey "*" key, Gui_Off, "On"
    HotIfWinExist
    ;-----------------
    Critical "Off"
    CoordMode "Mouse"
    hk:="", oldx:=oldy:=""
    Loop
    {
      Sleep 50
      MouseGetPos &x, &y
      if (oldx=x && oldy=y)
        Continue
      oldx:=x, oldy:=y
      px:=x, py:=y, Gui_("getcors",1), Gui_("Reset")
      , r:=StrSplit(Lang["s10"] "|", "|")
      ToolTip r[1] " : " x "," y "`n" r[2]
    }
    Until (hk=key) || GetKeyState(key,"P") || GetKeyState("Ctrl","P")
    KeyWait key
    KeyWait "Ctrl"
    ToolTip
    HotIfWinExist "FindText_HotkeyIf"
    Try Hotkey "*" key, Gui_Off, "Off"
    HotIfWinExist
    FindText_HotkeyIf.Destroy
    Critical
    this.BindWindow(0), cors.bind:=bind_mode
    return
  Case "MySlider1", "MySlider2":
    SetTimer(Gui_Slider,-10)
    return
  Case "Slider":
    Critical
    dx:=nW>71 ? Round((nW-71)*FindText_Capture["MySlider1"].Value/100) : 0
    dy:=nH>25 ? Round((nH-25)*FindText_Capture["MySlider2"].Value/100) : 0
    if (oldx=dx && oldy=dy)
      return
    oldy:=dy, k:=0
    Loop nW*nH
      c:=(!show[++k] ? WindowColor : bg="" ? cors[k] : ascii[k]
      ? "Black":"White"), Gui_SetColor()
    Loop nW*(oldx!=dx)
    {
      i:=A_Index-dx
      if (i>=1 && i<=71)
      {
        c:=show[nW*nH+A_Index] ? 0x0000FF : 0xAAFFFF
        SendMessage 0x2001, 0, c, C_[71*25+i]
      }
    }
    oldx:=dx
    return
  Case "Reset":
    show:=Map(), show.Default:=0, ascii:=Map(), ascii.Default:=0, bg:=color:=""
    CutLeft:=CutRight:=CutUp:=CutDown:=k:=0
    Loop nW*nH
      show[++k]:=1, c:=cors[k], Gui_SetColor()
    Loop cors.CutLeft
      Gui_("CutL")
    Loop cors.CutRight
      Gui_("CutR")
    Loop cors.CutUp
      Gui_("CutU")
    Loop cors.CutDown
      Gui_("CutD")
    return
  Case "SetColor":
    if (nW=71 && nH=25)
      tk:=k
    else
    {
      tx:=Mod(k-1,nW)-dx, ty:=(k-1)//nW-dy
      if (tx<0 || tx>=71 || ty<0 || ty>=25)
        return
      tk:=ty*71+tx+1
    }
    c:=c="Black" ? 0x000000 : c="White" ? 0xFFFFFF
      : ((c&0xFF)<<16)|(c&0xFF00)|((c&0xFF0000)>>16)
    SendMessage 0x2001, 0, c, C_[tk]
    return
  Case "RepColor":
    show[k]:=1, c:=(bg="" ? cors[k] : ascii[k] ? "Black":"White")
    , Gui_SetColor()
    return
  Case "CutColor":
    show[k]:=0, c:=WindowColor, Gui_SetColor()
    return
  Case "RepL":
    if (CutLeft<=cors.CutLeft)
    || (bg!="" && InStr(color,"**")
    && CutLeft=cors.CutLeft+1)
      return
    k:=CutLeft-nW, CutLeft--
    Loop nH
      k+=nW, (A_Index>CutUp && A_Index<nH+1-CutDown && Gui_("RepColor"))
    return
  Case "CutL":
    if (CutLeft+CutRight>=nW)
      return
    CutLeft++, k:=CutLeft-nW
    Loop nH
      k+=nW, (A_Index>CutUp && A_Index<nH+1-CutDown && Gui_("CutColor"))
    return
  Case "CutL3":
    Loop 3
      Gui_("CutL")
    return
  Case "RepR":
    if (CutRight<=cors.CutRight)
    || (bg!="" && InStr(color,"**")
    && CutRight=cors.CutRight+1)
      return
    k:=1-CutRight, CutRight--
    Loop nH
      k+=nW, (A_Index>CutUp && A_Index<nH+1-CutDown && Gui_("RepColor"))
    return
  Case "CutR":
    if (CutLeft+CutRight>=nW)
      return
    CutRight++, k:=1-CutRight
    Loop nH
      k+=nW, (A_Index>CutUp && A_Index<nH+1-CutDown && Gui_("CutColor"))
    return
  Case "CutR3":
    Loop 3
      Gui_("CutR")
    return
  Case "RepU":
    if (CutUp<=cors.CutUp)
    || (bg!="" && InStr(color,"**")
    && CutUp=cors.CutUp+1)
      return
    k:=(CutUp-1)*nW, CutUp--
    Loop nW
      k++, (A_Index>CutLeft && A_Index<nW+1-CutRight && Gui_("RepColor"))
    return
  Case "CutU":
    if (CutUp+CutDown>=nH)
      return
    CutUp++, k:=(CutUp-1)*nW
    Loop nW
      k++, (A_Index>CutLeft && A_Index<nW+1-CutRight && Gui_("CutColor"))
    return
  Case "CutU3":
    Loop 3
      Gui_("CutU")
    return
  Case "RepD":
    if (CutDown<=cors.CutDown)
    || (bg!="" && InStr(color,"**")
    && CutDown=cors.CutDown+1)
      return
    k:=(nH-CutDown)*nW, CutDown--
    Loop nW
      k++, (A_Index>CutLeft && A_Index<nW+1-CutRight && Gui_("RepColor"))
    return
  Case "CutD":
    if (CutUp+CutDown>=nH)
      return
    CutDown++, k:=(nH-CutDown)*nW
    Loop nW
      k++, (A_Index>CutLeft && A_Index<nW+1-CutRight && Gui_("CutColor"))
    return
  Case "CutD3":
    Loop 3
      Gui_("CutD")
    return
  Case "Gray2Two":
    FindText_Capture["Threshold"].Focus()
    Threshold:=FindText_Capture["Threshold"].Value
    if (Threshold="")
    {
      pp:=Map(), pp.Default:=0
      Loop 256
        pp[A_Index-1]:=0
      Loop nW*nH
        if (show[A_Index])
          pp[gray[A_Index]]++
      IP0:=IS0:=0
      Loop 256
        k:=A_Index-1, IP0+=k*pp[k], IS0+=pp[k]
      Threshold:=Floor(IP0/IS0)
      Loop 20
      {
        LastThreshold:=Threshold
        IP1:=IS1:=0
        Loop LastThreshold+1
          k:=A_Index-1, IP1+=k*pp[k], IS1+=pp[k]
        IP2:=IP0-IP1, IS2:=IS0-IS1
        if (IS1!=0 && IS2!=0)
          Threshold:=Floor((IP1/IS1+IP2/IS2)/2)
        if (Threshold=LastThreshold)
          Break
      }
      FindText_Capture["Threshold"].Value:=Threshold
    }
    Threshold:=Round(Threshold)
    color:="*" Threshold, k:=i:=0
    Loop nW*nH
    {
      ascii[++k]:=v:=(gray[k]<=Threshold)
      if (show[k])
        i:=(v?i+1:i-1), c:=(v?"Black":"White"), Gui_SetColor()
    }
    bg:=i>0 ? "1":"0"
    return
  Case "GrayDiff2Two":
    GrayDiff:=FindText_Capture["GrayDiff"].Value
    if (GrayDiff="")
    {
      FindText_Capture.Opt "+OwnDialogs"
      MsgBox(Lang["s11"] " !", "Tip", "4096 T1")
      return
    }
    if (CutLeft=cors.CutLeft)
      Gui_("CutL")
    if (CutRight=cors.CutRight)
      Gui_("CutR")
    if (CutUp=cors.CutUp)
      Gui_("CutU")
    if (CutDown=cors.CutDown)
      Gui_("CutD")
    GrayDiff:=Round(GrayDiff)
    color:="**" GrayDiff, k:=i:=0
    Loop nW*nH
    {
      j:=gray[++k]+GrayDiff
      , ascii[k]:=v:=( gray[k-1]>j || gray[k+1]>j
      || gray[k-nW]>j || gray[k+nW]>j
      || gray[k-nW-1]>j || gray[k-nW+1]>j
      || gray[k+nW-1]>j || gray[k+nW+1]>j )
      if (show[k])
        i:=(v?i+1:i-1), c:=(v?"Black":"White"), Gui_SetColor()
    }
    bg:=i>0 ? "1":"0"
    return
  Case "Color2Two", "ColorPos2Two":
    c:=FindText_Capture["SelColor"].Value
    if (c="")
    {
      FindText_Capture.Opt "+OwnDialogs"
      MsgBox(Lang["s12"] " !", "Tip", "4096 T1")
      return
    }
    UsePos:=(cmd="ColorPos2Two") ? 1:0
    n:=this.Floor(FindText_Capture["Similar1"].Value)
    n:=Round(n/100,2), color:=c "@" n
    , n:=Floor(512*9*255*255*(1-n)*(1-n)), k:=i:=0
    , rr:=(c>>16)&0xFF, gg:=(c>>8)&0xFF, bb:=c&0xFF
    Loop nW*nH
    {
      c:=cors[++k], r:=((c>>16)&0xFF)-rr
      , g:=((c>>8)&0xFF)-gg, b:=(c&0xFF)-bb, j:=r+rr+rr
      , ascii[k]:=v:=((1024+j)*r*r+2048*g*g+(1534-j)*b*b<=n)
      if (show[k])
        i:=(v?i+1:i-1), c:=(v?"Black":"White"), Gui_SetColor()
    }
    bg:=i>0 ? "1":"0"
    return
  Case "ColorDiff2Two":
    _Gui:=FindText_Capture
    c:=_Gui["SelColor"].Value
    if (c="")
    {
      _Gui.Opt "+OwnDialogs"
      MsgBox(Lang["s12"] " !", "Tip", "4096 T1")
      return
    }
    dR:=_Gui["dR"].Value
    dG:=_Gui["dG"].Value
    dB:=_Gui["dB"].Value
    rr:=(c>>16)&0xFF, gg:=(c>>8)&0xFF, bb:=c&0xFF
    , n:=Format("{:06X}",(dR<<16)|(dG<<8)|dB)
    , color:=StrReplace(c "-" n,"0x"), k:=i:=0
    Loop nW*nH
    {
      c:=cors[++k], r:=(c>>16)&0xFF, g:=(c>>8)&0xFF
      , b:=c&0xFF, ascii[k]:=v:=(Abs(r-rr)<=dR
      && Abs(g-gg)<=dG && Abs(b-bb)<=dB)
      if (show[k])
        i:=(v?i+1:i-1), c:=(v?"Black":"White"), Gui_SetColor()
    }
    bg:=i>0 ? "1":"0"
    return
  Case "Modify":
    Modify:=FindText_Capture["Modify"].Value
    return
  Case "MultiColor":
    MultiColor:=FindText_Capture["MultiColor"].Value
    Result:=""
    ToolTip
    return
  Case "Undo":
    Result:=RegExReplace(Result, ",[^/]+/[^/]+/[^/]+$")
    ToolTip Trim(Result,"/,")
    return
  Case "Similar1":
    FindText_Capture["Similar2"].Value:=FindText_Capture["Similar1"].Value
    return
  Case "Similar2":
    FindText_Capture["Similar1"].Value:=FindText_Capture["Similar2"].Value
    return
  Case "GetTxt":
    txt:=""
    if (bg="")
      return
    k:=0
    Loop nH
    {
      v:=""
      Loop nW
        v.=!show[++k] ? "" : ascii[k] ? "1":"0"
      txt.=v="" ? "" : v "`n"
    }
    return
  Case "Auto":
    Gui_("GetTxt")
    if (txt="")
    {
      FindText_Capture.Opt "+OwnDialogs"
      MsgBox(Lang["s13"] " !", "Tip", "4096 T1")
      return
    }
    While InStr(txt,bg)
    {
      if (txt~="^" bg "+\n")
        txt:=RegExReplace(txt, "^" bg "+\n"), Gui_("CutU")
      else if !(txt~="m`n)[^\n" bg "]$")
        txt:=RegExReplace(txt, "m`n)" bg "$"), Gui_("CutR")
      else if (txt~="\n" bg "+\n$")
        txt:=RegExReplace(txt, "\n\K" bg "+\n$"), Gui_("CutD")
      else if !(txt~="m`n)^[^\n" bg "]")
        txt:=RegExReplace(txt, "m`n)^" bg), Gui_("CutL")
      else Break
    }
    txt:=""
    return
  Case "OK", "SplitAdd", "AllAdd":
    FindText_Capture.Opt "+OwnDialogs"
    Gui_("GetTxt")
    if (txt="") && (!MultiColor)
    {
      MsgBox(Lang["s13"] " !", "Tip", "4096 T1")
      return
    }
    if InStr(color,"@") && (UsePos) && (!MultiColor)
    {
      r:=StrSplit(color,"@")
      k:=i:=j:=0
      Loop nW*nH
      {
        if (!show[++k])
          Continue
        i++
        if (k=cors.SelPos)
        {
          j:=i
          Break
        }
      }
      if (j=0)
      {
        MsgBox(Lang["s12"] " !", "Tip", "4096 T1")
        return
      }
      color:="#" j "@" r[2]
    }
    Comment:=FindText_Capture["Comment"].Value
    if (cmd="SplitAdd") && (!MultiColor)
    {
      if InStr(color,"#")
      {
        MsgBox(Lang["s14"], "Tip", "4096 T3")
        return
      }
      bg:=StrLen(StrReplace(txt,"0"))
        > StrLen(StrReplace(txt,"1")) ? "1":"0"
      s:="", i:=0, k:=nW*nH+1+CutLeft
      Loop w:=nW-CutLeft-CutRight
      {
        i++
        if (!show[k++] && A_Index<w)
          Continue
        i:=Format("{:d}",i)
        v:=RegExReplace(txt,"m`n)^(.{" i "}).*","$1")
        txt:=RegExReplace(txt,"m`n)^.{" i "}"), i:=0
        While InStr(v,bg)
        {
          if (v~="^" bg "+\n")
            v:=RegExReplace(v,"^" bg "+\n")
          else if !(v~="m`n)[^\n" bg "]$")
            v:=RegExReplace(v,"m`n)" bg "$")
          else if (v~="\n" bg "+\n$")
            v:=RegExReplace(v,"\n\K" bg "+\n$")
          else if !(v~="m`n)^[^\n" bg "]")
            v:=RegExReplace(v,"m`n)^" bg)
          else Break
        }
        if (v!="")
        {
          v:=Format("{:d}",InStr(v,"`n")-1) "." this.bit2base64(v)
          s.="`nText.=`"|<" SubStr(Comment, 1, 1) ">" color "$" v "`"`n"
          Comment:=SubStr(Comment, 2)
        }
      }
      Event:=cmd, Result:=s
      FindText_Capture.Hide
      return
    }
    if (!MultiColor)
      txt:=Format("{:d}",InStr(txt,"`n")-1) "." this.bit2base64(txt)
    else
    {
      dRGB:=FindText_Capture["dRGB"].Value
      r:=StrSplit(Trim(StrReplace(Result, ",", "/"), "/"), "/")
      , x:=(r.Has(1)?r[1]:0), y:=(r.Has(2)?r[2]:0), s:="", i:=1
      Loop r.Length//3
        s.="," (r[i++]-x) "/" (r[i++]-y) "/" r[i++]
      txt:=SubStr(s,2), color:="##" dRGB
    }
    s:="`nText.=`"|<" Comment ">" color "$" txt "`"`n"
    if (cmd="AllAdd")
    {
      Event:=cmd, Result:=s
      FindText_Capture.Hide
      return
    }
    x:=px-ww+CutLeft+(nW-CutLeft-CutRight)//2
    y:=py-hh+CutUp+(nH-CutUp-CutDown)//2
    s:=StrReplace(s, "Text.=", "Text:="), r:=StrSplit(Lang["s8"] "|||||||", "|")
    s:="`; #Include <FindText>`n"
    . "`nt1:=A_TickCount, Text:=X:=Y:=`"`"`n" s
    . "`nif (ok:=FindText(&X, &Y, " x "-150000, "
    . y "-150000, " x "+150000, " y "+150000, 0, 0, Text))"
    . "`n{"
    . "`n  `; FindText()." . "Click(" . "X, Y, `"L`")"
    . "`n}`n"
    . "`n`; ok:=FindText(&X:=`"wait`", &Y:=3, 0,0,0,0,0,0,Text)  `; " r[7]
    . "`n`; ok:=FindText(&X:=`"wait0`", &Y:=-1, 0,0,0,0,0,0,Text)  `; " r[8]
    . "`n`nMsgBox(`"" r[1] ":``t`" (IsObject(ok)?ok.Length:ok)"
    . "`n  . `"``n``n" r[2] ":``t`" (A_TickCount-t1) `" " r[3] "`""
    . "`n  . `"``n``n" r[4] ":``t`" X `", `" Y"
    . "`n  . `"``n``n" r[5] ":``t<`" (IsObject(ok)?ok[1].id:`"`") `">`", `"Tip`", 4096)`n"
    . "`nTry For i,v in ok  `; ok " r[6] " ok:=FindText().ok"
    . "`n  if (i<=2)"
    . "`n    FindText().MouseTip(ok[i].x, ok[i].y)`n"
    Event:=cmd, Result:=s
    FindText_Capture.Hide
    return
  Case "Save":
    x:=px-ww+CutLeft, w:=nW-CutLeft-CutRight
    y:=py-hh+CutUp, h:=nH-CutUp-CutDown
    Gui_("ScreenShot", x "|" y "|" (x+w-1) "|" (y+h-1) "|0")
    return
  Case "ShowPic":
    i:=EditGetCurrentLine(hscr)
    s:=EditGetLine(i, hscr)
    FindText_Main["MyPic"].Value:=Trim(this.ASCII(s),"`n")
    return
  Case "KeyDown":
    Critical
    if (WinExist()!=FindText_Main.Hwnd)
      return
    ctrl:=args.Has(3) ? args[3] : arg1
    if (ctrl=hscr)
      SetTimer(Gui_ShowPic, -150)
    else if (ctrl=FindText_Main["ClipText"].Hwnd)
    {
      s:=FindText_Main["ClipText"].Value
      FindText_Main["MyPic"].Value:=Trim(this.ASCII(s),"`n")
    }
    return
  Case "LButtonDown":
    Critical
    MouseGetPos(,, &k1, &k2, 2)
    if (k1!=FindText_Capture.Hwnd)
      return Gui_("KeyDown", k2)
    k1:=0
    ListLines((lls:=A_ListLines)?0:0)
    For k_,v_ in C_
      if (v_=k2) && (k1:=k_)
        Break
    ListLines(lls)
    if (k1<1)
      return
    if (k1>71*25)
    {
      k3:=nW*nH+(k1-71*25)+dx
      k1:=(show[k3]:=!show[k3]) ? 0x0000FF : 0xAAFFFF
      SendMessage 0x2001, 0, k1, k2
      return
    }
    k2:=Mod(k1-1,71)+dx, k3:=(k1-1)//71+dy
    if (k2<0 || k2>=nW || k3<0 || k3>=nH)
      return
    k1:=k, k:=k3*nW+k2+1, k2:=c
    if (MultiColor && show[k])
    {
      c:="," Mod(k-1,nW) "/" k3 "/"
      . Format("{:06X}",cors[k]&0xFFFFFF)
      , Result.=InStr(Result,c) ? "":c
      ToolTip Trim(Result,"/,")
    }
    else if (Modify && bg!="" && show[k])
    {
      c:=((ascii[k]:=!ascii[k]) ? "Black":"White"), Gui_SetColor()
    }
    else
    {
      c:=cors[k], cors.SelPos:=k
      _Gui:=FindText_Capture
      _Gui["SelGray"].Value:=gray[k]
      _Gui["SelColor"].Value:=Format("0x{:06X}",c&0xFFFFFF)
      _Gui["SelR"].Value:=(c>>16)&0xFF
      _Gui["SelG"].Value:=(c>>8)&0xFF
      _Gui["SelB"].Value:=c&0xFF
    }
    k:=k1, c:=k2
    return
  Case "MouseMove":
    static PrevControl:=""
    MouseGetPos(,,, &ctrl_id, 2)
    Try ctrl_name:="", ctrl_name:=GuiCtrlFromHwnd(ctrl_id).Name
    if (PrevControl != ctrl_name)
    {
      ToolTip
      PrevControl:=ctrl_name
      if IsSet(Gui_ToolTip)
      {
        SetTimer(Gui_ToolTip, PrevControl ? -500 : 0)
        SetTimer(Gui_ToolTipOff, PrevControl ? -5500 : 0)
      }
    }
    return
  Case "ToolTip":
    MouseGetPos(,, &_TT)
    if WinExist("ahk_id " _TT " ahk_class AutoHotkeyGUI")
      Try ToolTip Tip_Text[PrevControl]
    return
  Case "ToolTipOff":
    ToolTip
    return
  Case "CutL2", "CutR2", "CutU2", "CutD2":
    s:=FindText_Main["MyPic"].Value
    s:=Trim(s,"`n") . "`n", v:=SubStr(cmd,4,1)
    if (v="U")
      s:=RegExReplace(s,"^[^\n]+\n")
    else if (v="D")
      s:=RegExReplace(s,"[^\n]+\n$")
    else if (v="L")
      s:=RegExReplace(s,"m`n)^[^\n]")
    else if (v="R")
      s:=RegExReplace(s,"m`n)[^\n]$")
    FindText_Main["MyPic"].Value:=Trim(s,"`n")
    return
  Case "Update":
    ControlFocus(hscr)
    i:=EditGetCurrentLine(hscr)
    s:=EditGetLine(i, hscr)
    if !RegExMatch(s, "(<[^>\n]*>[^$\n]+\$)\d+\.[\w+/]+", &r)
      return
    v:=FindText_Main["MyPic"].Value
    v:=Trim(v,"`n") . "`n", w:=Format("{:d}",InStr(v,"`n")-1)
    v:=StrReplace(StrReplace(v,"0","1"),"_","0")
    s:=StrReplace(s, r[0], r[1] . w "." this.bit2base64(v))
    v:="{End}{Shift Down}{Home}{Shift Up}{Del}"
    ControlSend(v, hscr)
    EditPaste(s, hscr)
    ControlSend("{Home}", hscr)
    return
  }
}

Lang(text:="", getLang:=0)
{
  static Lang1:="", Lang2
  if (!Lang1)
  {
    s:="
    (
Myww       = Width = Adjust the width of the capture range
Myhh       = Height = Adjust the height of the capture range
AddFunc    = Add = Additional FindText() in Copy
NowHotkey  = Hotkey = Current screenshot hotkey
SetHotkey1 = = First sequence Screenshot hotkey
SetHotkey2 = = Second sequence Screenshot hotkey
Apply      = Apply = Apply new screenshot hotkey
CutU2      = CutU = Cut the Upper Edge of the text in the edit box below
CutL2      = CutL = Cut the Left Edge of the text in the edit box below
CutR2      = CutR = Cut the Right Edge of the text in the edit box below
CutD2      = CutD = Cut the Lower Edge of the text in the edit box below
Update     = Update = Update the text in the edit box below to the line of Code
GetRange   = GetRange = Get screen range and update the search range of the Code
GetOffset  = GetOffset = Get position offset relative to the Text from the Code and update FindText().Click()
GetClipOffset  = GetOffset2 = Get position offset relative to the Text from the Left Box
Capture    = Capture = Initiate Image Capture Sequence
CaptureS   = CaptureS = Restore the Saved ScreenShot by Hotkey and then start capturing
Test       = Test = Test the Text from the Code to see if it can be found on the screen
TestClip   = Test2 = Test the Text from the Left Box and copy the result to Clipboard
Paste      = Paste = Paste the Text from Clipboard to the Left Box
CopyOffset = Copy2 = Copy the Offset to Clipboard
Copy       = Copy = Copy the selected or all of the code to the clipboard
Reset      = Reset = Reset to Original Captured Image
SplitAdd   = SplitAdd = Using Markup Segmentation to Generate Text Library
AllAdd     = AllAdd = Append Another FindText Search Text into Previously Generated Code
OK         = OK = Create New FindText Code for Testing
Cancel     = Cancel = Close the Window Don't Do Anything
Save       = SavePic = Save the trimmed original image to the default directory
Gray2Two      = Gray2Two = Converts Image Pixels from Gray Threshold to Black or White
GrayDiff2Two  = GrayDiff2Two = Converts Image Pixels from Gray Difference to Black or White
Color2Two     = Color2Two = Converts Image Pixels from Color Similar to Black or White
ColorPos2Two  = ColorPos2Two = Converts Image Pixels from Color Position to Black or White
ColorDiff2Two = ColorDiff2Two = Converts Image Pixels from Color Difference to Black or White
SelGray    = Gray = Gray value of the selected color
SelColor   = Color = The selected color
SelR       = R = Red component of the selected color
SelG       = G = Green component of the selected color
SelB       = B = Blue component of the selected color
RepU       = -U = Undo Cut the Upper Edge by 1
CutU       = U = Cut the Upper Edge by 1
CutU3      = U3 = Cut the Upper Edge by 3
RepL       = -L = Undo Cut the Left Edge by 1
CutL       = L = Cut the Left Edge by 1
CutL3      = L3 = Cut the Left Edge by 3
Auto       = Auto = Automatic Cut Edge after image has been converted to black and white
RepR       = -R = Undo Cut the Right Edge by 1
CutR       = R = Cut the Right Edge by 1
CutR3      = R3 = Cut the Right Edge by 3
RepD       = -D = Undo Cut the Lower Edge by 1
CutD       = D = Cut the Lower Edge by 1
CutD3      = D3 = Cut the Lower Edge by 3
Modify     = Modify = Allows Modify the Black and White Image
MultiColor = FindMultiColor = Click multiple colors with the mouse, then Click OK button
Undo       = Undo = Undo the last selected color
Comment    = Comment = Optional Comment used to Label Code ( Within <> )
Threshold  = Gray Threshold = Gray Threshold which Determines Black or White Pixel Conversion (0-255)
GrayDiff   = Gray Difference = Gray Difference which Determines Black or White Pixel Conversion (0-255)
Similar1   = Similarity = Adjust color similarity as Equivalent to The Selected Color
Similar2   = Similarity = Adjust color similarity as Equivalent to The Selected Color
DiffR      = R = Red Difference which Determines Black or White Pixel Conversion (0-255)
DiffG      = G = Green Difference which Determines Black or White Pixel Conversion (0-255)
DiffB      = B = Blue Difference which Determines Black or White Pixel Conversion (0-255)
DiffRGB    = R/G/B = Determine the allowed R/G/B Error (0-255) when Find MultiColor
Bind0      = BindWin1 = Bind the window and Use GetDCEx() to get the image of background window
Bind1      = BindWin1+ = Bind the window Use GetDCEx() and Modify the window to support transparency
Bind2      = BindWin2 = Bind the window and Use PrintWindow() to get the image of background window
Bind3      = BindWin2+ = Bind the window Use PrintWindow() and Modify the window to support transparency
Bind4      = BindWin3 = Bind the window and Use PrintWindow(,,3) to get the image of background window
OK2        = OK = Restore this ScreenShot
Cancel2    = Cancel = Close the Window Don't Do Anything
ClearAll   = ClearAll = Clean up all saved ScreenShots
OpenDir    = OpenDir = Open the saved screenshots directory
SavePic    = SavePic = Select a range and save as a picture
ClipText   = = Displays the Text data from clipboard
Offset     = = Displays the results of GetOffset2 or GetRange
s1  = FindText
s2  = Gray|GrayDiff|Color|ColorPos|ColorDiff|MultiColor
s3  = Capture Image To Text
s4  = Capture Image To Text and Find Text Tool
s5  = First click RButton\nMove the mouse away\nSecond click RButton
s6  = Unbind Window using
s7  = Please drag a range with the LButton\nCoordinates are copied to clipboard
s8  = Found|Time|ms|Pos|Result|value can be get from|Wait 3 seconds for appear|Wait indefinitely for disappear
s9  = Success
s10 = The Capture Position|Perspective binding window\nRight click to finish capture
s11 = Please Set Gray Difference First
s12 = Please select the core color first
s13 = Please convert the image to black or white first
s14 = Can't be used in ColorPos mode, because it can cause position errors
s15 = ReTry|ToFile|GetRange|ToClipboard
s16 = LButton Drag to select range\nDirection keys to fine tune\nRButton or ESC to get range\nDouble-Click copy to Clipboard
    )"
    Lang1:=Map(), Lang1.Default:="", Lang2:=Map(), Lang2.Default:=""
    Loop Parse, s, "`n", "`r"
      if InStr(v:=A_LoopField, "=")
        r:=StrSplit(StrReplace(v "==","\n","`n"), "=", "`t ")
        , Lang1[r[1]]:=r[2], Lang2[r[1]]:=r[3]
  }
  return getLang=1 ? Lang1 : getLang=2 ? Lang2 : Lang1[text]
}

}  ;// Class End

Script_End() {
}

;================= The End =================

;