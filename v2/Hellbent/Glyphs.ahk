; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=135966
; Author: Hellbent

#Requires AutoHotkey v2.0
;#####<<<()>>>#####|#####<<<()>>>#####|#####<<<()>>>#####|#####<<<()>>>#####|#####<<<()>>>#####|#####<<<()>>>#####|#####<<<()>>>#####|
;#####<<<()>>>#####|#####<<<()>>>#####|#####<<<()>>>#####|#####<<<()>>>#####|#####<<<()>>>#####|#####<<<()>>>#####|#####<<<()>>>#####|
;#####<<<()>>>#####|#####<<<()>>>#####|#####<<<()>>>#####|#####<<<()>>>#####|#####<<<()>>>#####|#####<<<()>>>#####|#####<<<()>>>#####|
class Glyphs {
    ;Class: Glyphs
    ;Purpose: Render multi color text in an ahk gui (+More)
    ;Written By: Hellbent
    ;Date: Feb 18th 2025
    ;Version: 1.4
    ;Version Date: Mar 15th 2025        ;1.3: Feb 25th 2025         ;1.2: Feb 25th 2025        ;1.1: Feb 20th 2025
    ;Credits: buliasz - GDI+ Code and insights
    ;Credits: just me - https://www.autohotkey.com/boards/viewtopic.php?p=598625#p598625 (font unit size: This.CreateFont())
    static init := This._SetDefaults()
    static _SetDefaults(){
        blank                           := "0x00000000"
        This._DefaultColor              := This._Color              := "0xFF000000"
        This._DefaultColor2             := This._Color2             := blank
        This._DefaultShadowColor        := This._ShadowColor        := blank
        This._DefaultShadowColor2       := This._ShadowColor2       := blank
        This._DefaultBackgroundColor    := This._BackgroundColor    := blank
        This._DefaultBackgroundColor2   := This._BackgroundColor2   := blank
        This._DefaultType               := This._Type               := "Segoe ui"
        This._DefaultSize               := This._Size               := 16
        This._DefaultQuality            := This._Quality            := 6
        This._DefaultBold               := This._Bold               := 0
        This._DefaultItalic             := This._Italic             := 0
        This._DefaultUnderline          := This._Underline          := 0
        This._DefaultStrikeout          := This._Strikeout          := 0
        This._DefaultTrimLeft           := This._TrimLeft           := 0
        This._DefaultTrimTop            := This._TrimTop            := 0
        This._DefaultTrimRight          := This._TrimRight          := 0
        This._DefaultTrimBottom         := This._TrimBottom         := 0
        This._DefaultShadowOffset       := This._ShadowOffset       := 1
        This._Character                 := ""
        This._Style                     := ""
    }
    Static RestoreDefaults(){
        propList := [ "Type" , "Size" , "Quality" , "Bold" , "Italic" 
                    , "UnderLine" , "StrikeOut" , "Color" , "color2" 
                    , "ShadowColor" , "ShadowColor2" , "BackgroundColor" 
                    , "BackgroundColor2" , "TrimLeft" , "TrimTop" 
                    , "TrimRight" , "TrimBottom" , "ShadowOffset" ]
        for v in propList   
            This.%v% := This.Default%v%                
    }
    static DefaultColor {
        Get => This._DefaultColor
        Set => ( ( !This._IsNumber( "DEFAULTCOLOR" , value ) || !This._IsStrLen( "DEFAULTCOLOR" , value , 10 ) ) || ( This._DefaultColor := value ) )
    }
    static Color {
        Get => This._Color
        Set => ( ( !This._IsNumber( "COLOR" , value ) || !This._IsStrLen( "COLOR" , value , 10 ) ) || ( This._Color := value ) )
    }
    static DefaultColor2 {
        Get => This._DefaultColor2
        Set => ( ( !This._IsNumber( "DEFAULTCOLOR2" , value ) || !This._IsStrLen( "DEFAULTCOLOR2" , value , 10 ) ) || ( This._DefaultColor2 := value ) )
    }
    static Color2 {
        Get => This._Color2
        Set => ( ( !This._IsNumber( "COLOR2" , value ) || !This._IsStrLen( "COLOR2" , value , 10 ) ) || ( This._Color2 := value ) )
    }
    static DefaultShadowColor {
        Get => This._DefaultShadowColor
        Set => ( ( !This._IsNumber( "DEFAULTSHADOWCOLOR" , value ) || !This._IsStrLen( "DEFAULTSHADOWCOLOR" , value , 10 ) ) || ( This._DefaultShadowColor := value ) )
    }
    static ShadowColor {
        Get => This._ShadowColor
        Set => ( ( !This._IsNumber( "SHADOWCOLOR" , value ) || !This._IsStrLen( "SHADOWCOLOR" , value , 10 ) ) || ( This._ShadowColor := value ) )
    }
    static DefaultShadowColor2 {
        Get => This._DefaultShadowColor2
        Set => ( ( !This._IsNumber( "DEFAULTSHADOWCOLOR2" , value ) || !This._IsStrLen( "DEFAULTSHADOWCOLOR2" , value , 10 ) ) || ( This._DefaultShadowColor2 := value ) )
    }
    static ShadowColor2 {
        Get => This._ShadowColor2
        Set => ( ( !This._IsNumber( "SHADOWCOLOR2" , value ) || !This._IsStrLen( "SHADOWCOLOR2" , value , 10 ) ) || ( This._ShadowColor2 := value ) )
    }
    static DefaultBackgroundColor {
        Get => This._DefaultBackgroundColor
        Set => ( ( !This._IsNumber( "DEFAULTBACKGROUNDCOLOR" , value ) || !This._IsStrLen( "DEFAULTBACKGROUNDCOLOR" , value , 10 ) ) || ( This._DefaultBackgroundColor := value ) )
    }
    static BackgroundColor {
        Get => This._BackgroundColor
        Set => ( ( !This._IsNumber( "BACKGROUNDCOLOR" , value ) || !This._IsStrLen( "BACKGROUNDCOLOR" , value , 10 ) ) || ( This._BackgroundColor := value ) )
    }
    static DefaultBackgroundColor2 {
        Get => This._DefaultBackgroundColor2
        Set => ( ( !This._IsNumber( "DEFAULTBACKGROUNDCOLOR2" , value ) || !This._IsStrLen( "DEFAULTBACKGROUNDCOLOR2" , value , 10 ) ) || ( This._DefaultBackgroundColor2 := value ) )
    }
    static BackgroundColor2 {
        Get => This._BackgroundColor2
        Set => ( ( !This._IsNumber( "BACKGROUNDCOLOR2" , value ) || !This._IsStrLen( "BACKGROUNDCOLOR2" , value , 10 ) ) || ( This._BackgroundColor2 := value ) )
    }
    static DefaultType {
        Get => This._DefaultType
        Set => ( !This._IsInStr( "DEFAULTTYPE" , This._GetFontTypesList() , value ) ) || ( This._DefaultType := value )
    }
    static Type {
        Get => This._Type
        Set => ( ( !This._IsInStr( "TYPE" , This._GetFontTypesList() , value ) ) || This._Type := value )
    }
    static DefaultSize {
        Get => This._DefaultSize
        Set => ( !This._IsNumber( "DEFAULTSIZE" , value ) ) || ( This._DefaultSize := value )
    }
    static Size {
        Get => This._Size
        Set => ( !This._IsNumber( "SIZE" , value ) ) || ( This._Size := value )
    }
    static DefaultQuality {
        Get => This._DefaultQuality
        Set => ( !This._IsNumber( "DEFAULTQUALITY" , value ) ) || ( This._DefaultQuality := value )
    }
    static Quality {
        Get => This._Quality
        Set => ( !This._IsNumber( "QUALITY" , value ) ) || ( This._Quality := value )
    }
    static DefaultBold {
        Get => This._DefaultBold
        Set => ( !This._IsBoolean( "DEFAULTBOLD" , value ) ) || This._DefaultBold := !!value
    }
    static Bold {
        Get => This._Bold
        Set => ( !This._IsBoolean( "BOLD" , value ) ) || This._Bold := !!value
    }
    static DefaultItalic {
        Get => This._DefaultItalic
        Set => ( !This._IsBoolean( "DEFAULTITALIC" , value ) ) || This._DefaultItalic := !!value
    }
    static Italic {
        Get => This._Italic
        Set => ( !This._IsBoolean( "ITALIC" , value ) ) || This._Italic := !!value
    }
    static DefaultUnderline {
        Get => This._DefaultUnderline
        Set => ( !This._IsBoolean( "DEFAULTUNDERLINE" , value ) ) || This._DefaultUnderline := !!value
    }
    static Underline {
        Get => This._Underline
        Set => ( !This._IsBoolean( "UNDERLINE" , value ) ) || This._Underline := !!value
    }
    static DefaultStrikeout {
        Get => This._DefaultStrikeout
        Set => ( !This._IsBoolean( "DEFAULTSTRIKEOUT" , value ) ) || This._DefaultStrikeout := !!value
    }
    static Strikeout {
        Get => This._Strikeout
        Set => ( !This._IsBoolean( "STRIKEOUT" , value ) ) || This._Strikeout := !!value
    }
    static DefaultTrimLeft {
        Get => This._DefaultTrimLeft
        Set => ( !This._IsNumber( "DEFAULTTRIMLEFT" , value ) ) || ( This._DefaultTrimLeft := value )
    }
    static TrimLeft {
        Get => This._TrimLeft
        Set => ( !This._IsNumber( "TRIMLEFT" , value ) ) || ( This._TrimLeft := value )
    }
    static DefaultTrimTop {
        Get => This._DefaultTrimTop
        Set => ( !This._IsNumber( "DEFAULTTRIMTOP" , value ) ) || ( This._DefaultTrimTop := !!value )
    }
    static TrimTop {
        Get => This._TrimTop
        Set => ( !This._IsNumber( "TRIMTOP" , value ) ) || ( This._TrimTop := value )
    }
    static DefaultTrimRight {
        Get => This._DefaultTrimRight
        Set => ( !This._IsNumber( "DEFAULTTRIMRIGHT" , value ) ) || ( This._DefaultTrimRight := value )
    }
    static TrimRight {
        Get => This._TrimRight
        Set => ( !This._IsNumber( "TRIMRIGHT" , value ) ) || ( This._TrimRight := value )
    }
    static DefaultTrimBottom {
        Get => This._DefaultTrimBottom
        Set => ( !This._IsNumber( "DEFAULTTRIMBOTTOM" , value ) ) || ( This._DefaultTrimBottom := value )
    }
    static TrimBottom {
        Get => This._TrimBottom
        Set => ( !This._IsNumber( "TRIMBOTTOM" , value ) ) || ( This._TrimBottom := value )
    }
    static DefaultShadowOffset {
        Get => This._DefaultShadowOffset
        Set => ( !This._IsNumber( "DEFAULTSHADOWOFFSET" , value ) ) || ( This._DefaultShadowOffset := value )
    }
    static ShadowOffset {
        Get => This._ShadowOffset
        Set => ( !This._IsNumber( "SHADOWOFFSET" , value ) ) || ( This._ShadowOffset := value )
    }
    static Character {
        Get => This._Character
        Set => ( This._Character := value )
    }
    static Style {
        Get => This._GetStyleOptions( This._GetFontStyle() )
        Set => MsgBox( "You can't set the Style property in this manner." )
    }
    static Rect {
        Get => This._MeasureCharacter()
        Set => MsgBox( "You can't set the rect property in this manner." )
    }
    static Startup(){
        ;From The gdi+ lib for ahk v2: https://raw.githubusercontent.com/buliasz/AHKv2-Gdip/master/Gdip_All.ahk
        if( !DllCall( "LoadLibrary" , "str" , "gdiplus" , "UPtr" ) ) 
            MsgBox "Unable to load the gdip lib."
            
        si := Buffer( A_PtrSize = 4 ? 20 : 32 , 0 ) ; sizeof(GdiplusStartupInputEx) = 20, 32
        NumPut( "uint" , 0x2 , si )
        NumPut( "uint" , 0x4 , si , A_PtrSize = 4 ? 16:24 )
        DllCall( "gdiplus\GdiplusStartup" , "UPtr*" , &pToken := 0 , "Ptr" , si , "UPtr" , 0 )
        if( !pToken ) 
            MsgBox "Unable to load the gdip lib."    
        return pToken
    }
    static Shutdown( pToken ){
        DllCall( "gdiplus\GdiplusShutdown" , "Ptr" , pToken )
    }
    static _IsNumber( key , value ){
        if( !IsNumber( value ) ){
            MsgBox "The Font " key " must be a number" , "Font " key " Error" , 0x2000
            return 0
        }
        return 1
    }
    static _IsInStr( key , string , value ){
        if( !InStr( string , value ) ){
            MsgBox "The font " key " isn't in the list" , "Error setting " key , 0x2000
            return 0
        }
        return 1
    }
    static  _IsStrLen( key , string , length ){
        if( StrLen( string ) != length ){
            MsgBox "The " key " length must be " length " characters long" , "Error setting the " key , 0x2000
            return 0
        }
        return 1
    }
    static _IsBoolean( key , value ){
        if( value != false && value != true ){
            MsgBox "Font " key " must be a value of 1/0 or true/false"
            return 0
        }
        return 1
    }
    static _GetFontTypesList(){
        return "8514oem|Malgun Gothic|Malgun Gothic Semilight|Microsoft JhengHei|Microsoft JhengHei Light|Microsoft JhengHei UI|Microsoft JhengHei UI Light|Microsoft YaHei|Microsoft YaHei Light|Microsoft YaHei UI|Microsoft YaHei UI Light|MingLiU-ExtB|MingLiU_HKSCS-ExtB|MS Gothic|MS PGothic|MS UI Gothic|NSimSun|PMingLiU-ExtB|SimSun|SimSun-ExtB|Yu Gothic|Yu Gothic Light|Yu Gothic Medium|Yu Gothic UI|Yu Gothic UI Light|Yu Gothic UI Semibold|Yu Gothic UI Semilight|Arial|Arial Black|Bahnschrift|Bahnschrift Condensed|Bahnschrift Light|Bahnschrift Light Condensed|Bahnschrift Light SemiCondensed|Bahnschrift SemiBold|Bahnschrift SemiBold Condensed|Bahnschrift SemiBold SemiConden|Bahnschrift SemiCondensed|Bahnschrift SemiLight|Bahnschrift SemiLight Condensed|Bahnschrift SemiLight SemiConde|Calibri|Calibri Light|Cambria|Cambria Math|Candara|Candara Light|Comic Sans MS|Consolas|Constantia|Corbel|Corbel Light|Courier|Courier New|Ebrima|Fixedsys|Franklin Gothic Medium|Gabriola|Gadugi|Georgia|HoloLens MDL2 Assets|Impact|Ink Free|Javanese Text|Leelawadee UI|Leelawadee UI Semilight|Lucida Console|Lucida Sans Unicode|Malgun Gothic|Malgun Gothic Semilight|Marlett|Microsoft Himalaya|Microsoft JhengHei|Microsoft JhengHei Light|Microsoft JhengHei UI|Microsoft JhengHei UI Light|Microsoft New Tai Lue|Microsoft PhagsPa|Microsoft Sans Serif|Microsoft Tai Le|Microsoft YaHei|Microsoft YaHei Light|Microsoft YaHei UI|Microsoft YaHei UI Light|Microsoft Yi Baiti|MingLiU-ExtB|MingLiU_HKSCS-ExtB|Modern|Mongolian Baiti|MS Gothic|MS PGothic|MS Sans Serif|MS Serif|MS UI Gothic|MV Boli|Myanmar Text|Nirmala UI|Nirmala UI Semilight|NSimSun|Palatino Linotype|PMingLiU-ExtB|Roman|Script|Segoe MDL2 Assets|Segoe Print|Segoe Script|Segoe UI|Segoe UI Black|Segoe UI Emoji|Segoe UI Historic|Segoe UI Light|Segoe UI Semibold|Segoe UI Semilight|Segoe UI Symbol|SimSun|SimSun-ExtB|Sitka Banner|Sitka Display|Sitka Heading|Sitka Small|Sitka Subheading|Sitka Text|Small Fonts|Sylfaen|Symbol|System|Tahoma|Terminal|Times New Roman|Trebuchet MS|Verdana|Webdings|Wingdings|Yu Gothic|Yu Gothic Light|Yu Gothic Medium|Yu Gothic UI|Yu Gothic UI Light|Yu Gothic UI Semibold|Yu Gothic UI Semilight"
    }
    static _GetStyleOptions( style ){
        styleStr := ""
        if ( style & 1 )
            styleStr .= " Bold"
        if ( style & 2 )
            styleStr .= " Italic"
        if ( style & 4 )
            styleStr .= " Underline"
        if ( style & 8 )
            styleStr .= " StrikeOut"
        return styleStr
    }
    static _GetFontStyle(){
        style := 0
        ( !This.Bold )      || style |= 1
        ( !This.Italic )    || style |= 2
        ( !This.UnderLine ) || style |= 4
        ( !This.StrikeOut ) || style |= 8
        return style
    }
    static _MeasureCharacter(){
        static pBitmap      := 0
        static pGraphics    := 0
        if( pBitmap = 0 ){
            pBitmap := This.CreateBitmap( 100 , 100 )
            ; DllCall("gdiplus\GdipCreateBitmapFromScan0" , "Int" , 10 , "Int" , 10 , "Int" , 0 , "Int" , 0x26200A , "UPtr" , 0 , "UPtr*" , &pBitmap := 0 )
            pGraphics := This.GetGraphicsFromImage( pBitmap )
            ; DllCall( "gdiplus\GdipGetImageGraphicsContext" , "UPtr" , pBitmap , "UPtr*" , &pGraphics := 0 )
        }
        options := "s" This.Size " NoWrap " This.Style
        sizeArr := StrSplit( This.TextToGraphics( pGraphics , This.Character , options , This.Type , 0 , 0 , 1 ) , "|" )
        
        return { X: 0 , Y: 0 , W: sizeArr[ 3 ] , H: sizeArr[ 4 ] }
    }
    __New( inputString := "" , alignmentMode := 2 ){
        This.pToken := Glyphs.Startup()
        This._pBitmap := 0
        This._hBitmap := 0
        This._pGraphics := 0
        This._pColorBrush := 0
        This._pShadowBrush := 0
        This._pBackgroundBrush := 0

        This.AlignmentMode := alignmentMode
        This.BitmapHeight := 0
        This.BitmapWidth := 0

        This._SplitInput( inputString )

        This._ReadMarkers()
        
        This._GetBitmapDimensions()

        This._GetWords()
    }
    _SplitInput( inputString ){
        lines := StrSplit( inputString , "`n" )
        This.Lines := []
        for v in lines  {
            This.Lines.Push( {} )
            This.Lines[ A_Index ].String    := v 
            This.Lines[ A_Index ].Words     := [] 
            This.Lines[ A_Index ].Segments  := []
            This.Lines[ A_Index ].Rect      := {}
            This.Lines[ A_Index ].Rect.X    := 0
            This.Lines[ A_Index ].Rect.Y    := 0
            This.Lines[ A_Index ].Rect.W    := 0
            This.Lines[ A_Index ].Rect.H    := 0
        }
    }
    _GetWords(){
        pos := 0
        for line in This.Lines  {
            words := StrSplit( line.String , " " )
            pos := 1
            for word in words   {
                if( pos := InStr( line.String , word ,, pos ) ){
                    line.Words.Push( { Word: word , Position: pos , Count: StrLen( word ) } )                    
                }      
                pos += StrLen( word )    
            }            
        }
    }
    _ReadMarkers(){
        Markers := {}
        
        Markers.Color             := { Open: "[c]"        , Close: "[/c]"         , Error: "COLOR"            , Property: "Color"             , Depth: 3 }
        Markers.Color2            := { Open: "[c2]"       , Close: "[/c2]"        , Error: "COLOR2"           , Property: "Color2"            , Depth: 4 }
        Markers.ShadowColor       := { Open: "[sc]"       , Close: "[/sc]"        , Error: "SHADOWCOLOR"      , Property: "ShadowColor"       , Depth: 4 }
        Markers.ShadowColor2      := { Open: "[sc2]"      , Close: "[/sc2]"       , Error: "SHADOWCOLOR2"     , Property: "ShadowColor2"      , Depth: 5 }
        Markers.BackgroundColor   := { Open: "[bgc]"      , Close: "[/bgc]"       , Error: "BACKGROUNDCOLOR"  , Property: "BackgroundColor"   , Depth: 5 }
        Markers.BackgroundColor2  := { Open: "[bgc2]"     , Close: "[/bgc2]"      , Error: "BACKGROUNDCOLOR2" , Property: "BackgroundColor2"  , Depth: 6 }
        Markers.Type              := { Open: "[t]"        , Close: "[/t]"         , Error: "TYPE"             , Property: "Type"              , Depth: 3 }
        Markers.Size              := { Open: "[s]"        , Close: "[/s]"         , Error: "SIZE"             , Property: "Size"              , Depth: 3 }
        Markers.Quality           := { Open: "[q]"        , Close: "[/q]"         , Error: "QUALITY"          , Property: "Quality"           , Depth: 3 }
        Markers.Bold              := { Open: "[b]"        , Close: "[/b]"         , Error: "BOLD"             , Property: "Bold"              , Depth: 3 }
        Markers.Italic            := { Open: "[i]"        , Close: "[/i]"         , Error: "ITALIC"           , Property: "Italic"            , Depth: 3 }
        Markers.Underline         := { Open: "[u]"        , Close: "[/u]"         , Error: "UNDERLINE"        , Property: "Underline"         , Depth: 3 }
        Markers.Strikeout         := { Open: "[Strike]"   , Close: "[/Strike]"    , Error: "STRIKEOUT"        , Property: "Strikeout"         , Depth: 8 }
        Markers.TrimLeft          := { Open: "[LTrim]"    , Close: "[/LTrim]"     , Error: "TRIMLEFT"         , Property: "TrimLeft"          , Depth: 7 }
        Markers.TrimTop           := { Open: "[TTrim]"    , Close: "[/TTrim]"     , Error: "TRIMTOP"          , Property: "TrimTop"           , Depth: 7 }
        Markers.TrimRight         := { Open: "[RTrim]"    , Close: "[/RTrim]"     , Error: "TRIMRIGHT"        , Property: "TrimRight"         , Depth: 7 }
        Markers.TrimBottom        := { Open: "[BTrim]"    , Close: "[/BTrim]"     , Error: "TRIMBOTTOM"       , Property: "TrimBottom"        , Depth: 7 }
        Markers.ShadowOffset      := { Open: "[sOff]"     , Close: "[/sOff]"      , Error: "SHADOWOFFSET"     , Property: "ShadowOffset"      , Depth: 6 }
        Loop( This.Lines.Length ){
            index := A_Index
            currentLine := This.Lines[ A_Index ].String
            errorState := 0
            updateString := ""
            Loop( StrLen( currentLine ) ){
                if( SubStr( currentLine , 1 , 1 ) = "[" ){
                    for k , v in Markers.OwnProps()    {
                        marker := Markers.%k%
                        if( SubStr( currentLine , 1 , marker.Depth ) = marker.Open ){
                            if( !( ClosingPos := InStr( currentLine , marker.Close ,, marker.Depth + 1  , 1 ) ) ){
                                errorState := marker.Error
                                break 2
                            }
                            prop := marker.Property
                            Glyphs.%prop% := SubStr( currentLine , marker.Depth + 1 , ClosingPos - ( marker.Depth + 1 ) )
                            currentLine := SubStr( currentLine , ClosingPos + StrLen( marker.Close ) )
                        }
                    } 
                }else{
                    This.Lines[ Index ].Segments.Push( glyph := This._NewGlyph( SubStr( currentLine , 1 , 1 ) ) )
                    updateString .= glyph.Character
                    currentLine := SubStr( currentLine , 2 )   
                }
                if( !StrLen( currentLine ) )
                    break
            }
            This.Lines[ A_Index ].String := updateString
        }
        if( errorState ){
            msgbox "Error setting the font " errorState
            return
        }
    }
    _GetBitmapDimensions(){
        This.BitmapWidth    := 0
        This.BitmapHeight   := 0
        for line in This.Lines  {
            line.Rect.W := 0 
            line.Rect.H := 0 
            for segment in line.Segments    {
                line.Rect.W += segment.Rect.W
                ( line.Rect.H >= segment.Rect.H ) || line.Rect.H := segment.Rect.H                 
            }
            ( This.BitmapWidth >= line.Rect.W ) || This.BitmapWidth := line.Rect.W
            This.BitmapHeight += line.Rect.H                
        }
    }
    _NewGlyph( character ){
        if( StrLen( character ) != 1 ){
            MsgBox( "You must pass a single character")
        }
        nGlyph := {}
        Glyphs.Character := character
        propList := [ "Type" , "Size" , "Quality" , "Bold" , "Italic" 
                    , "UnderLine" , "StrikeOut" , "Character" 
                    , "Color" , "color2" , "ShadowColor" , "ShadowColor2" 
                    , "BackgroundColor" , "BackgroundColor2" , "Style" 
                    , "TrimLeft" , "TrimTop" , "TrimRight" , "TrimBottom" 
                    , "ShadowOffset" , "Rect" ]

        for v in propList   
            nGlyph.%v% := Glyphs.%v%
        return nGlyph 
    }
    RestoreDefaults(){
        propList := [ "Type" , "Size" , "Quality" , "Bold" , "Italic" 
                    , "UnderLine" , "StrikeOut" , "Color" , "color2" 
                    , "ShadowColor" , "ShadowColor2" , "BackgroundColor" 
                    , "BackgroundColor2" , "Style" , "TrimLeft" , "TrimTop" 
                    , "TrimRight" , "TrimBottom" , "ShadowOffset" , "Rect" ]
        for line in This.Lines {
            for segment in line.segments    {
                for prop in propList    {
                    segment.%prop% := Glyphs.%prop%
                }
                
            }
        }
                
    }
    pBitmap{
        Get{
            try{
                if( This._pBitmap != 0 ){
                    Glyphs.DisposeImage( This._pBitmap )
                    This._pBitmap := 0
                }
            }
            This._pBitmap := Glyphs.CreateBitmap( This.BitmapWidth , This.BitmapHeight )
            This.DrawText()
            return This._pBitmap
        }Set{
            try{
                if( This._pBitmap != 0 ){
                    Glyphs.DisposeImage( This._pBitmap )
                    This._pBitmap := 0
                }
            }
        }
    }
    hBitmap{
        Get{
            try{
                if( This._hBitmap != 0 ){
                    Glyphs.DeleteObject( This._hBitmap )
                    This._hBitmap := 0
                }                
            }
            This._hBitmap := Glyphs.CreateHBITMAPFromBitmap( This.pBitmap )
            return This._hBitmap
        }Set{
            try{
                if( This._hBitmap != 0 ){
                    Glyphs.DisposeImage( This._hBitmap )
                    This._hBitmap := 0
                }
            }
        }
    }
    DrawText(){        
        pGraphics := Glyphs.GetGraphicsFromImage( This._pBitmap )
        Glyphs.SetSmoothingMode( pGraphics , 3 )
        lY := 0
        y := 0
        for k , v in This.Lines {
            index := A_Index
            line := This.Lines[ k ]
            x := 0
            for i , j in line.Segments  {
                char := line.Segments[ i ]
                rect := char.Rect
                if( This.AlignmentMode = 0 )
                    y := ly
                else if( This.AlignmentMode = 1 )
                    y := ly + ( line.Rect.H - rect.H )
                else if( This.AlignmentMode = 2 )
                    y := ly + ( line.Rect.H - rect.H ) / 2     
                        
                if( SubStr( char.BackgroundColor , 3 , 2 ) != "00" ){
                    if( SubStr( char.BackgroundColor2 , 3 , 2 ) != "00" )
                        pBrush := Glyphs.GradientBrush( x , y , rect.W , rect.H , char.BackgroundColor , char.BackgroundColor2 , 1 , 1 )
                    else                   
                        pBrush := Glyphs.SolidBrush( char.BackgroundColor )   
                    Glyphs.FillRectangle( pGraphics , pBrush , x , y , rect.W , rect.H )
                    Glyphs.DeleteBrush( pBrush )
                }
                if( SubStr( char.ShadowColor , 3 , 2 ) != "00" ){
                    if( SubStr( char.ShadowColor2 , 3 , 2 ) != "00" )
                        pBrush := Glyphs.GradientBrush( x , y , rect.W , rect.H , char.ShadowColor , char.ShadowColor2 , 1 , 1 )
                    else                     
                        pBrush := Glyphs.SolidBrush( char.ShadowColor )                    
                    options := "s" char.Size " NoWrap " char.Style " x" x + char.ShadowOffset " y" y + char.ShadowOffset " c" pBrush " r" char.Quality
                    Glyphs.TextToGraphics( pGraphics , char.Character , options , char.Type , rect.W , rect.H )
                    Glyphs.DeleteBrush( pBrush )
                }
                if( SubStr( char.Color , 3 , 2 ) != "00" ){                    
                    if( SubStr( char.Color2 , 3 , 2 ) != "00" )
                        pBrush := Glyphs.GradientBrush( x , y , rect.W , rect.H , char.Color , char.Color2 , 1 , 1 )
                    else
                        pBrush := Glyphs.SolidBrush( char.Color )
                    options := "s" char.Size " NoWrap " char.Style " x" x " y" y " c" pBrush " r" char.Quality
                    Glyphs.TextToGraphics( pGraphics , char.Character , options , char.Type , rect.W , rect.H )
                    Glyphs.DeleteBrush( pBrush )
                }
                x += rect.W
            }
            ly += line.Rect.H
        }    
        Glyphs.DeleteGraphics( pGraphics )        
    }
    static CreateBitmap( width , height , format := 0x26200A ){
        DllCall("gdiplus\GdipCreateBitmapFromScan0" , "Int" , width , "Int" , height , "Int" , 0 , "Int" , format , "UPtr" , 0 , "UPtr*" , &pBitmap := 0 )
        return pBitmap 
    }
    static SolidBrush( color ){ ;0xAARRGGBB
        DllCall( "gdiplus\GdipCreateSolidFill" , "UInt" , color , "UPtr*" , &pBrush := 0 )
        return pBrush
    }
    static GradientBrush( x , y , w , h , color1 , color2 , gradientMode , wrapMode ){ ;0xAARRGGBB
        Rect := Buffer( 16 )
	    NumPut( "Float" , x , "Float" , y , "Float" , w , "Float" , h , Rect )
        DllCall( "gdiplus\GdipCreateLineBrushFromRect" , "UPtr" , Rect.Ptr , "Int" , color1 , "Int", color2 , "Int", gradientMode, "Int", wrapMode, "UPtr*", &pBrush := 0 )
        return pBrush
    }
    static DeleteBrush( pBrush ){
        return DllCall( "gdiplus\GdipDeleteBrush" , "UPtr" , pBrush )
    }
    static CloneBrush( pBrush ){
        DllCall( "gdiplus\GdipCloneBrush" , "UPtr" , pBrush , "UPtr*" , &pClone := 0 )
        return pClone
    }
    static GetGraphicsFromImage( pBitmap ){
        DllCall( "gdiplus\GdipGetImageGraphicsContext" , "UPtr" , pBitmap , "UPtr*" , &pGraphics := 0 )
        return pGraphics
    }
    static SetSmoothingMode( pGraphics , mode := 2 ){
        DllCall( "gdiplus\GdipSetSmoothingMode" , "UPtr" , pGraphics , "Int" , mode )
    }
    static DeleteGraphics( pGraphics ){
        DllCall( "gdiplus\GdipDeleteGraphics" , "UPtr" , pGraphics )
    }
    static FillRectangle( pGraphics , pBrush , x , y , w , h ){
        return DllCall("gdiplus\GdipFillRectangle" , "UPtr" , pGraphics , "UPtr" , pBrush , "Float" , x , "Float" , y , "Float" , w , "Float" , h )
    }
    static TextToGraphics(pGraphics, Text, Options, Font:="Arial", Width:="", Height:="", Measure:=0){ 
        ;From The gdi+ lib for ahk v2: https://raw.githubusercontent.com/buliasz/AHKv2-Gdip/master/Gdip_All.ahk
        IWidth := Width
        IHeight := Height
        PassBrush := 0

        pattern_opts := "i)"
        RegExMatch(Options, pattern_opts "X([\-\d\.]+)(p*)", &xpos:="")
        RegExMatch(Options, pattern_opts "Y([\-\d\.]+)(p*)", &ypos:="")
        RegExMatch(Options, pattern_opts "W([\-\d\.]+)(p*)", &Width:="")
        RegExMatch(Options, pattern_opts "H([\-\d\.]+)(p*)", &Height:="")
        RegExMatch(Options, pattern_opts "C(?!(entre|enter))([a-f\d]+)", &Colour:="")
        RegExMatch(Options, pattern_opts "Top|Up|Bottom|Down|vCentre|vCenter", &vPos:="")
        RegExMatch(Options, pattern_opts "NoWrap", &NoWrap:="")
        RegExMatch(Options, pattern_opts "R(\d)", &Rendering:="")
        RegExMatch(Options, pattern_opts "S(\d+)(p*)", &Size:="")
    
        ; if Colour && IsInteger(Colour[2]) && !Gdip_DeleteBrush(Gdip_CloneBrush(Colour[2])) {
        if( Colour && IsInteger( Colour[ 2 ] ) && !This.DeleteBrush( This.CloneBrush( Colour[ 2 ] ) ) ){
            PassBrush := 1
            pBrush := Colour[ 2 ]
        }
    
        if( !( IWidth && IHeight ) && ( ( xpos && xpos[ 2 ] ) || ( ypos && ypos[ 2 ] ) || ( Width && Width[ 2 ] ) || ( Height && Height[ 2 ] ) || ( Size && Size[ 2 ] ) ) ){
            return -1
        }
    
        Style := 0
        Styles := "Regular|Bold|Italic|BoldItalic|Underline|Strikeout"
        for eachStyle, valStyle in StrSplit( Styles, "|" ) {
            if RegExMatch( Options , "\b" valStyle )
                Style |= ( valStyle != "StrikeOut" ) ? ( A_Index - 1 ) : 8
        }
    
        Align := 0
        Alignments := "Near|Left|Centre|Center|Far|Right"
        for eachAlignment, valAlignment in StrSplit( Alignments, "|" ) {
            if RegExMatch(Options, "\b" valAlignment) {
                Align |= A_Index*10//21	; 0|0|1|1|2|2
            }
        }
    
        xpos := (xpos && (xpos[1] != "")) ? xpos[2] ? IWidth*(xpos[1]/100) : xpos[1] : 0
        ypos := (ypos && (ypos[1] != "")) ? ypos[2] ? IHeight*(ypos[1]/100) : ypos[1] : 0
        Width := (Width && Width[1]) ? Width[2] ? IWidth*(Width[1]/100) : Width[1] : IWidth
        Height := (Height && Height[1]) ? Height[2] ? IHeight*(Height[1]/100) : Height[1] : IHeight
    
        if !PassBrush {
            Colour := "0x" (Colour && Colour[2] ? Colour[2] : "ff000000")
        }
    
        Rendering := (Rendering && (Rendering[1] >= 0) && (Rendering[1] <= 5)) ? Rendering[1] : 4
        Size := (Size && (Size[1] > 0)) ? Size[2] ? IHeight*(Size[1]/100) : Size[1] : 12
    
        hFamily := This.CreateFontFamilyFromName( Font )
        
        hFont := This.CreateFont( hFamily , Size , Style )
        FormatStyle := NoWrap ? 0x4000 | 0x1000 : 0x4000
        
        hFormat := This.CreateStringFormat( FormatStyle )
        
        pBrush := PassBrush ? pBrush : This.SolidBrush( Colour )
    
        if !(hFamily && hFont && hFormat && pBrush && pGraphics) {
            return !pGraphics ? -2 : !hFamily ? -3 : !hFont ? -4 : !hFormat ? -5 : !pBrush ? -6 : 0
        }
    
        
        RC := Buffer( 16 )
	    NumPut( "Float" , xpos , "Float" , ypos , "Float" , Width , "Float" , Height , RC )

        
        This.SetStringFormatAlign( hFormat , Align )
        
        This.SetTextRenderingHint( pGraphics , Rendering )
        
        ReturnRC := This.MeasureString(pGraphics, Text, hFont, hFormat, &RC)
    
        if vPos {
            ReturnRC := StrSplit(ReturnRC, "|")
    
            if (vPos[0] = "vCentre") || (vPos[0] = "vCenter")
                yPos += Floor( ( Height - ReturnRC[ 4 ] ) / 2 )
            else if (vPos[0] = "Top") || (vPos[0] = "Up")
                ypos := 0
            else if (vPos[0] = "Bottom") || (vPos[0] = "Down")
                ypos := Height-ReturnRC[4]
    
            
            RC := Buffer( 16 )
            NumPut( "Float" , xpos , "Float" , ypos , "Float" , Width , "Float" , ReturnRC[ 4 ] , RC )
            
            ReturnRC := This.MeasureString( pGraphics , Text , hFont , hFormat , &RC )
        }
    
        if !Measure {
            
            ReturnRC := This.DrawString(pGraphics, Text, hFont, hFormat, pBrush, &RC)
        }
    
        if !PassBrush {
            
            This.DeleteBrush(pBrush)
        }
    
        
        This.DeleteStringFormat( hFormat )
        
        This.DeleteFont( hFont )
        
        This.DeleteFontFamily( hFamily )
    
        return ReturnRC
    }
    static CreateFontFamilyFromName( type ){
        DllCall( "gdiplus\GdipCreateFontFamilyFromName" , "UPtr" , StrPtr( type ) , "UInt" , 0 , "UPtr*" , &hFamily := 0 )
	    return hFamily
    }
    static CreateFont( hFamily , size , style ){ ;edited feb 25th 2025 - credit @just me: https://www.autohotkey.com/boards/viewtopic.php?p=598625#p598625
        local UnitSize := 3
        DllCall( "gdiplus\GdipCreateFont" , "UPtr" , hFamily , "Float" , Size , "Int" , Style , "Int" , UnitSize , "UPtr*" , &hFont := 0 )
        return hFont
    }
    static CreateStringFormat( format ){
        DllCall( "gdiplus\GdipCreateStringFormat" , "Int" , format , "Int", 0 , "UPtr*" , &hFormat := 0 )
        return hFormat
    }
    static SetStringFormatAlign( hFormat , Align ){
        DllCall( "gdiplus\GdipSetStringFormatAlign" , "UPtr" , hFormat , "Int" , Align )
    }
    static SetTextRenderingHint( pGraphics , RenderingHint ){
        DllCall( "gdiplus\GdipSetTextRenderingHint" , "UPtr" , pGraphics , "Int" , RenderingHint )
    }
    static MeasureString( pGraphics , sString , hFont , hFormat , &RectF ){
        RC := Buffer( 16 )
        DllCall( "gdiplus\GdipMeasureString" , "UPtr" , pGraphics , "UPtr" , StrPtr( sString ) , "Int" , -1 , "UPtr" , hFont , "UPtr" , RectF.Ptr , "UPtr" , hFormat , "UPtr" , RC.Ptr , "uint*" , &Chars := 0 , "uint*" , &Lines := 0 )
        return RC.Ptr ? NumGet( RC , 0 , "Float" ) "|" NumGet( RC , 4 , "Float" ) "|" NumGet( RC , 8 , "Float" ) "|" NumGet( RC , 12 , "Float" ) "|" Chars "|" Lines : 0
    }
    static DrawString( pGraphics , sString , hFont , hFormat , pBrush , &RectF ){
        DllCall( "gdiplus\GdipDrawString" , "UPtr" , pGraphics , "UPtr" , StrPtr( sString ) , "Int" , -1 , "UPtr" , hFont , "UPtr" , RectF.Ptr , "UPtr" , hFormat , "UPtr" , pBrush )
    }
    static DeleteStringFormat( hFormat ){
        DllCall( "gdiplus\GdipDeleteStringFormat" , "UPtr" , hFormat )
    }
    static DeleteFont( hFont ){
        DllCall( "gdiplus\GdipDeleteFont" , "UPtr" , hFont )
    }
    static DeleteFontFamily( hFamily ){
        DllCall( "gdiplus\GdipDeleteFontFamily" , "UPtr" , hFamily )
    }
    static DisposeImage( pBitmap ){
        return DllCall( "gdiplus\GdipDisposeImage" , "UPtr" , pBitmap )
    }
    static DeleteObject( hObject ){
        return DllCall( "DeleteObject" , "UPtr" , hObject )
    }
    static CreateHBITMAPFromBitmap( pBitmap , Background := 0xffffffff ){
        DllCall( "gdiplus\GdipCreateHBITMAPFromBitmap" , "UPtr" , pBitmap , "UPtr*" , &hbm := 0 , "Int" , Background )
        return hbm
    }
    __Delete(){
        This.pBitmap := 0
        This.hBitmap := 0
        Glyphs.Shutdown( This.pToken )
    }
}