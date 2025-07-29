#Requires AutoHotkey v2.1-alpha.14
/**
 * MIT License
 *
 * Copyright (c) 2024 Tyler J. Colby-Wolter (Komrad Toast)
 * URL: <>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/**
 * __Cursor class__
 *
 * Contains methods and properties for working with the Windows Cursor.
 * ___
 * Note: The functions in this class have system-wide effects. For example, if you enable cursor trails,
 * they will remain enabled even after exiting your script. You can call `Cursor.Restore()` to restore all
 * System Cursors to their default state. `Cursor.RestoreDefaults()` will restore all System Cursors, along
 * with calling `Cursor.Show()`, and disabling cursor trails. You must handle all cleanup yourself.
 */
class Cursor
{
    static __cursorIds     => [32512  , 32513  , 32514 , 32515  , 32516    , 32631, 32642     , 32643     , 32644   , 32645   , 32646    , 32648, 32649 , 32650        , 32651 , 32652     , 32653     , 32654      , 32655     , 32656       , 32657       , 32658        , 32659     , 32660     , 32661     , 32662     , 32663    , 32671, 32672]
    static __cursorNames   => ["Arrow", "IBeam", "Wait", "Cross", "UpArrow", "Pen", "SizeNWSE", "SizeNESW", "SizeWE", "SizeNS", "SizeAll", "No" , "Hand", "AppStarting", "Help", "ScrollNS", "ScrollWE", "ScrollAll", "ScrollN" , "ScrollS"   , "ScrollW"   , "ScrollE"    , "ScrollNW", "ScrollNE", "ScrollSW", "ScrollSE", "CDArrow", "Pin", "Person"]
    static __cursorIDC     => ["IDC_ARROW", "IDC_IBEAM", "IDC_WAIT", "IDC_CROSS", "IDC_UPARROW", "", "IDC_SIZENWSE", "IDC_SIZENESW", "IDC_SIZEWE", "IDC_SIZENS", "IDC_SIZEALL", "IDC_NO", "IDC_HAND", "IDC_APPSTARTING", "IDC_HELP", "", "", "", "", "", "", "", "", "", "", "", "", "IDC_PIN", "IDC_PERSON"]
    static __cursorMap := Map()

    /**
     * Current cursor's resource ID
     * @type {Integer}
     */
    static ID
    {
        get
        {
            if (info := Cursor.GetCURSORINFO())
                if Cursor.__cursorMap.Has(info.hCursor.Ptr)
                    return Cursor.__cursorMap[info.hCursor.Ptr].ID

            return Cursor.__cursorMap[Cursor.GetCurrent().Ptr].ID
        }
    }

    /**
     * Current cursor's name
     * @type {String}
     */
    static Name
    {
        get => Cursor.GetName(Cursor.ID)
    }

    /**
     * Current cursor's IDC_ constant name
     * @type {String}
     * @returns {String} Windows IDC_ constant name or Empty String if not found
     */
    static IDCName
    {
        get => Cursor.GetIDCName(Cursor.ID)
    }

    /**
     * Current cursor handle
     * @type {Integer}
     * @returns {UPtr} Handle to current cursor
     */
    static Handle
    {
        get => Cursor.GetHCURSOR(Cursor.ID).Ptr
    }

    /**
     * Whether cursor is currently visible
     * @type {Boolean}
     * @returns {Boolean} True if visible, false if hidden
     */
    static IsVisible
    {
        get => Cursor.GetCURSORINFO().flags & 0x1
    }

    /**
     * Whether cursor drawing is suppressed
     * @type {Boolean}
     * @returns {Boolean} True if suppressed, false if normal
     */
    static IsSuppressed
    {
        get => Cursor.GetCURSORINFO().flags & 0x2
    }

    /**
     * Current cursor position on screen
     * @type {POINT}
     * @returns {x: Integer, y: Integer}
     */
    static Position
    {
        get => (pt := Cursor.POINT(), DllCall("GetCursorPos", "Ptr", pt), pt)
        set => DllCall("SetCursorPos", "Int", value.X, "Int", value.Y)
    }

    /**
     * Current physical cursor position on screen
     * @type {POINT}
     * @returns {x: Integer, y: Integer}
     */
    static PhysicalPosition
    {
        get => (pt := Cursor.POINT(), DllCall("GetPhysicalCursorPos", "Ptr", pt), pt)
        set => DllCall("SetPhysicalCursorPos", "Int", value.X, "Int", value.Y)
    }

    /**
     * Current cursor clipping rectangle
     * @type {RECT}
     * @returns {RECT} Rectangle defining cursor boundaries
     */
    static ClipRect
    {
        get => (rct := Cursor.RECT(), DllCall("GetClipCursor", "Ptr", rct), rct)
        set => DllCall("ClipCursor", "Ptr", value)
    }

    /**
     * Controls cursor shadow effect
     * @type {Boolean}
     * @returns {Boolean} True if shadow is enabled
     */
    static Shadow
    {
        get => (enabled := 0, DllCall("SystemParametersInfo", "UInt", 0x101A, "UInt", 0, "Ptr*", &enabled, "UInt", 0), enabled)
        set => DllCall("SystemParametersInfo", "UInt", 0x101B, "UInt", 0, "Ptr", value, "UInt", 0)
    }

    static __New()
    {
        for i, id in Cursor.__cursorIds
            Cursor.__cursorMap.Set(Cursor.GetHCURSOR(id).Ptr, { ID: id, Name: Cursor.__cursorNames[i] })
    }

    /**
     * Gets information about the current cursor
     * @returns {CURSORINFO} Structure containing cursor information
     */
    static GetCURSORINFO()
    {
        info := Cursor.CURSORINFO()

        if DllCall("GetCursorInfo", "Ptr", info)
            return info
        else
            return false
    }

    /**
     * Gets a handle to a system cursor
     * @param {Integer|String} cursorNameOrID System cursor Name or ID
     * @returns {HCURSOR} Handle to the system cursor
     */
    static GetHCURSOR(cursorNameOrID) => DllCall("LoadCursor", "Ptr", 0, "Int", Cursor.GetID(cursorNameOrID), Cursor.HCURSOR)

    /**
     * Gets the handle of the current thread's cursor
     * @returns {HCURSOR} Handle to the current cursor
     */
    static GetCurrent() => DllCall("GetCursor", Cursor.HCURSOR)

    /**
     * Sets the current thread's cursor
     * @param {HCURSOR} hCursor Handle to cursor to set as current
     * @returns {HCURSOR} Handle to previously displayed cursor
     */
    static SetCurrent(hCursor) => DllCall("SetCursor", "Ptr", hCursor)

    /**
     * Gets the ID for a cursor from its name or handle
     * @param {String|Integer|HCURSOR} cursorNameOrHandle Cursor identifier
     * @returns {Integer} System cursor ID
     */
    static GetID(cursorNameOrHandle)
    {
        ; Handle HCURSOR instance
        if (cursorNameOrHandle is Cursor.HCURSOR)
        {
            if Cursor.__cursorMap.Has(cursorNameOrHandle.Ptr)
                return Cursor.__cursorMap[cursorNameOrHandle.Ptr].ID
        }

        ; Handle numeric handle
        if (cursorNameOrHandle is Integer)
        {
            if Cursor.__cursorMap.Has(cursorNameOrHandle)
                return Cursor.__cursorMap[cursorNameOrHandle].ID
        }

        ; Handle string name
        if (cursorNameOrHandle is String)
        {
            for i, name in Cursor.__cursorNames
                if (cursorNameOrHandle = name)
                    return Integer(Cursor.__cursorIds[i])
        }

        return cursorNameOrHandle
    }

    /**
     * Gets the name of a cursor from its ID or handle
     * @param {Integer|HCURSOR} cursorIDOrHandle Cursor identifier
     * @returns {String} Human-readable cursor name
     */
    static GetName(cursorIDOrHandle)
    {
        ; First get the ID from any input type
        id := Cursor.GetID(cursorIDOrHandle)

        ; Then get the name from the ID
        for i, cursorId in Cursor.__cursorIds
            if (id = cursorId)
                return Cursor.__cursorNames[i]

        return "Unknown"
    }

    /**
     * Gets the IDC_ constant name for a cursor
     * @param {Integer|HCURSOR} cursorIDOrHandle Cursor identifier
     * @returns {String} Windows IDC_ constant name
     */
    static GetIDCName(cursorIDOrHandle)
    {
        ; First get the ID from any input type
        id := Cursor.GetID(cursorIDOrHandle)

        ; Then get the name from the ID
        for i, cursorId in Cursor.__cursorIds
            if (id = cursorId)
                if Cursor.__cursorIDC.Has(i)
                    return Cursor.__cursorIDC[i]

        return "Not Found"
    }

    /**
     * Sets a system cursor
     * @param {Integer|String} id System cursor ID or name to replace
     * @param {HCURSOR} hCursor Handle to new cursor
     */
    static Set(cursorID, hCursor)
    {
        cursorID := Cursor.GetID(cursorID)
        hCursor := !(hCursor is Cursor.HCURSOR) ? Cursor.GetHCURSOR(Cursor.GetID(hCursor)) : hCursor

        return DllCall("SetSystemCursor", "Ptr", hCursor, "UInt", cursorID)
    }

    /**
     * Sets all system cursors to the specified cursor
     * @param {HCURSOR} hCursor Handle to cursor to use for all system cursors
     */
    static SetAll(hCursor)
    {
        hCursor := !(hCursor is Cursor.HCURSOR) ? Cursor.GetHCURSOR(Cursor.GetID(hCursor)) : hCursor

        for id in Cursor.__cursorIds
            Cursor.Set(id, DllCall("CopyImage", "Ptr", hCursor, "UInt", 2, "Int", 0, "Int", 0, "UInt", 0, Cursor.HCURSOR))
    }

    /**
     * Restores all, system cursors to their defaults
     */
    static Restore(cursorNameOrID?) => DllCall("SystemParametersInfo", "UInt", 0x57, "UInt", 0, "UInt", 0, "UInt", 0)

    /**
     * Sets the current cursor to the default system cursor,
     * Shows the cursor, and disables the cursor trail.
     */
    static RestoreDefaults()
    {
        Cursor.Restore()
        Cursor.Show()
        Cursor.Trail.Disable()
        Cursor.Shadow := False
    }

    /**
     * Creates a cursor from an image file
     * @param {String} filePath Path to cursor file (.cur, .ani, .ico, or .bmp)
     * @param {Integer} [width=0] Desired width (0 for default)
     * @param {Integer} [height=0] Desired height (0 for default)
     * @returns {HCURSOR} Handle to created cursor
     */
    static FromFile(filePath, width := 0, height := 0)
    {
        SplitPath(filePath, &fileName, , &fileExt)

        type := fileExt = "bmp" ? 0x0 ; Bitmap File
              : fileExt = "ico" ? 0x1 ; Icon File
              : fileExt = "cur" ? 0x2 ; Cursor File
              : fileExt = "ani" ? 0x2 ; Animated Cursor File
              : throw(OSError(A_LastError, -1))

        hCursor := DllCall("LoadImageW", "Ptr", 0, "Str", filePath, "UInt", type, "Int", width, "Int", height, "UInt", 0x10 | 0x40 , Cursor.HCURSOR)
        Cursor.__cursorMap.Set(hCursor.Ptr, { ID: hCursor.Ptr, Name: fileName })
        return hCursor
    }

    /**
     * Increments cursor display counter, showing cursor if counter is >= 0
     * @returns {Integer} The cursor display counter
     */
    static Show() => DllCall("ShowCursor", "Int", True)

    /**
     * Decrements cursor display counter, hiding cursor if counter is < 0
     * @returns {Integer} The cursor display counter
     */
    static Hide() => DllCall("ShowCursor", "Int", False)

    /**
     * Creates a new cursor
     * @param {String} name Name for the new cursor
     * @param {Integer} width Width in pixels
     * @param {Integer} height Height in pixels
     * @param {Integer} xHotspot X coordinate of hotspot
     * @param {Integer} yHotspot Y coordinate of hotspot
     * @param {Mask} andMask AND mask bitmap data
     * @param {Mask} xorMask XOR mask bitmap data
     * @returns {HCURSOR} Handle to created cursor
     */
    static Create(name, width, height, xHotspot, yHotspot, andMask, xorMask)
    {
        hCursor := DllCall("CreateCursor",
            "Ptr", 0,           ; hInst
            "Int", xHotspot,    ; xHotSpot
            "Int", yHotspot,    ; yHotSpot
            "Int", width,       ; nWidth
            "Int", height,      ; nHeight
            "Ptr", andMask,     ; pvANDPlane
            "Ptr", xorMask,     ; pvXORPlane
            Cursor.HCURSOR)

        if !Cursor.__cursorMap.Has(hCursor.Ptr)
            Cursor.__cursorMap.Set(hCursor.Ptr, { ID: hCursor.Ptr, Name: name })

        return hCursor
    }

    /**
     * Creates a copy of an existing cursor
     * @param {HCURSOR} hCursor Handle to cursor to copy
     * @returns {HCURSOR} Handle to copied cursor
     */
    static Copy(hCursor) => DllCall("CopyImage", "Ptr", hCursor, "UInt", 2, "Int", 0, "Int", 0, "UInt", 0, Cursor.HCURSOR)

    /**
     * Destroys a cursor, freeing system resources.
     * Do Not use this to destroy a shared or in use cursor.
     * @param {HCURSOR} hCursor Handle to cursor to destroy
     * @returns {Boolean} True if successful
     */
    static Destroy(hCursor)
    {
        cursorID := Cursor.GetID(hCursor)
        for i, id in Cursor.__cursorIds
        {
            if cursorID = id
            {
                throw Error("Cursor.Destroy() can not destroy a shared or system cursor.")
                return false
            }
        }

        if Cursor.__cursorMap.Has(hCursor.Ptr)
            Cursor.__cursorMap.Delete(hCursor.Ptr)

        return DllCall("DestroyCursor", "Ptr", hCursor)
    }

    /**
     * Windows POINT structure wrapper
     * @struct
     */
    class POINT
    {
        X : i32
        Y : i32

        __New(x?, y?)
        {
            if IsSet(x) and IsSet(y)
            {
                this.X := x
                this.Y := y
            }
        }
    }

    /**
     * Windows RECT structure wrapper
     * @struct
     */
    class RECT
    {
        Left   : i32 := 0
        Top    : i32 := 0
        Right  : i32 := 0
        Bottom : i32 := 0

        __New(l?, t?, r?, b?)
        {
            if IsSet(l) and IsSet(t) and IsSet(r) and IsSet(b)
            {
                this.Left   := l
                this.Top    := t
                this.Right  := r
                this.Bottom := b
            }
        }
    }

    /**
     * Windows HCURSOR handle wrapper
     * @struct
     */
    class HCURSOR
    {
        Ptr : UPtr
    }

    /**
     * Windows CURSORINFO structure wrapper
     * @struct
     */
    class CURSORINFO
    {
        cbSize      : u32 := 24
        flags       : u32
        hCursor     : Cursor.HCURSOR
        ptScreenPos : Cursor.POINT
        __Value => this.hCursor ? this : throw(OSError(A_LastError, -1))
    }

    /**
     * Bitmap mask data for cursor creation
     * @extends {Buffer}
     */
    class Mask extends Buffer
    {
        Ptr : UPtr

        /**
         * @type {Integer}
         * @property {Integer} [Width=0] Mask width in pixels
         */
        Width := 0

        /**
         * @type {Integer}
         * @property {Integer} [Height=0] Mask height in pixels
         */
        Height := 0

        __New(width, height?, initialValue?)
        {
            initialValue ??= 0

            if width is Array {
                this.Height := width.Length
                this.Width := width[1].Length * 8
                super.__New((this.Width * this.Height) // 8, 0)

                for y, row in width
                    for x, byte in row
                        this[x, y] := byte
            }
            else
            {
                this.Width := width
                this.Height := height
                super.__New((this.Width * this.Height) // 8, initialValue)
            }

            this.Ptr := super.Ptr
        }

        __Item[x, y]
        {
            get => NumGet(this, (y - 1) * (this.Width // 8) + (x - 1), "UChar")
            set => NumPut("UChar", value, this, (y - 1) * (this.Width // 8) + (x - 1))
        }

        __Enum(num)
        {
            i := 0
            len := this.Width * this.Height

            ; Value only
            one(&value)
            {
                if ++i > len
                    return false

                value := this[Mod(i - 1, this.Width) + 1, ((i - 1) // this.Width) + 1]

                return true
            }

            ; X, Y
            two(&x?, &y?)
            {
                if ++i > len
                    return false

                x := Mod(i - 1, this.Width) + 1
                y := ((i - 1) // this.Width) + 1

                return true
            }

            ; X, Y, Value
            three(&x?, &y?, &value?)
            {
                if ++i > len
                    return false

                x := Mod(i - 1, this.Width) + 1
                y := ((i - 1) // this.Width) + 1
                value := this[x, y]

                return true
            }

            switch (num)
            {
                case 1: return one
                case 2: return two
                case 3: return three
                default: return Error("Invalid number of elements requested")
            }
        }
    }

    /**
     * Controls cursor trailing effects
     */
    class Trail
    {
        /**
         * Determines if cursor trails are enabled.
         * @type {Bool}
         * @returns {Bool} True if enabled
         */
        static IsEnabled => (Cursor.Trail.Length > 1) ? True : False

        /**
         * Gets current trail length.
         * @type {Integer}
         * @returns {Integer} Current trail length
         */
        static Length => (length := 0, DllCall("SystemParametersInfo", "UInt", 0x005E, "UInt", 0, "Ptr*", &length, "UInt", 0), length)

        /**
         * Enables cursor trail and sets length.
         * Length is clamped from 0 to 16.
         * 0 and 1 disable trails alltogether.
         * @param {Integer} length
         * @returns {Bool} Non-Zero if Successful.
         */
        static Enable(length := 10) => (length := Max(0, Min(16, length)), DllCall("SystemParametersInfo", "UInt", 0x005D, "UInt", length, "Ptr", 0, "UInt", 1))

        /**
         * Disables cursor trailing effects
         * @returns {Bool} Non-Zero if Successful.
         */
        static Disable() => DllCall("SystemParametersInfo", "UInt", 0x005D, "UInt", 0, "Ptr", 0, "UInt", 1)
    }

    /** Handle to the system "Arrow" cursor
     * @type {HCURSOR} */
    static Arrow       => Cursor.GetHCURSOR("Arrow")

    /** Handle to the system "I-Beam" text editing cursor
     * @type {HCURSOR} */
    static IBeam       => Cursor.GetHCURSOR("IBeam")

    /** Handle to the system "Wait" processing cursor
     * @type {HCURSOR} */
    static Wait        => Cursor.GetHCURSOR("Wait")

    /** Handle to the system "Cross" precision selection cursor
     * @type {HCURSOR} */
    static Cross       => Cursor.GetHCURSOR("Cross")

    /** Handle to the system "UpArrow" vertical arrow cursor
     * @type {HCURSOR} */
    static UpArrow     => Cursor.GetHCURSOR("UpArrow")

    /** Handle to the system "Pen" handwriting cursor
     * @type {HCURSOR} */
    static Pen         => Cursor.GetHCURSOR("Pen")

    /** Handle to the system "SizeNWSE" diagonal resize cursor
     * @type {HCURSOR} */
    static SizeNWSE    => Cursor.GetHCURSOR("SizeNWSE")

    /** Handle to the system "SizeNESW" diagonal resize cursor
     * @type {HCURSOR} */
    static SizeNESW    => Cursor.GetHCURSOR("SizeNESW")

    /** Handle to the system "SizeWE" horizontal resize cursor
     * @type {HCURSOR} */
    static SizeWE      => Cursor.GetHCURSOR("SizeWE")

    /** Handle to the system "SizeNS" vertical resize cursor
     * @type {HCURSOR} */
    static SizeNS      => Cursor.GetHCURSOR("SizeNS")

    /** Handle to the system "SizeAll" four-way resize cursor
     * @type {HCURSOR} */
    static SizeAll     => Cursor.GetHCURSOR("SizeAll")

    /** Handle to the system "No" slashed circle cursor
     * @type {HCURSOR} */
    static No          => Cursor.GetHCURSOR("No")

    /** Handle to the system "Hand" pointing cursor
     * @type {HCURSOR} */
    static Hand        => Cursor.GetHCURSOR("Hand")

    /** Handle to the system "AppStarting" arrow with processing cursor
     * @type {HCURSOR} */
    static AppStarting => Cursor.GetHCURSOR("AppStarting")

    /** Handle to the system "Help" arrow with question mark cursor
     * @type {HCURSOR} */
    static Help        => Cursor.GetHCURSOR("Help")

    /** Handle to the system "ScrollNS" vertical scroll cursor
     * @type {HCURSOR} */
    static ScrollNS    => Cursor.GetHCURSOR("ScrollNS")

    /** Handle to the system "ScrollWE" horizontal scroll cursor
     * @type {HCURSOR} */
    static ScrollWE    => Cursor.GetHCURSOR("ScrollWE")

    /** Handle to the system "ScrollAll" omnidirectional scroll cursor
     * @type {HCURSOR} */
    static ScrollAll   => Cursor.GetHCURSOR("ScrollAll")

    /** Handle to the system "ScrollN" north scroll cursor
     * @type {HCURSOR} */
    static ScrollN     => Cursor.GetHCURSOR("ScrollN")

    /** Handle to the system "ScrollS" south scroll cursor
     * @type {HCURSOR} */
    static ScrollS     => Cursor.GetHCURSOR("ScrollS")

    /** Handle to the system "ScrollW" west scroll cursor
     * @type {HCURSOR} */
    static ScrollW     => Cursor.GetHCURSOR("ScrollW")

    /** Handle to the system "ScrollE" east scroll cursor
     * @type {HCURSOR} */
    static ScrollE     => Cursor.GetHCURSOR("ScrollE")

    /** Handle to the system "ScrollNW" northwest scroll cursor
     * @type {HCURSOR} */
    static ScrollNW    => Cursor.GetHCURSOR("ScrollNW")

    /** Handle to the system "ScrollNE" northeast scroll cursor
     * @type {HCURSOR} */
    static ScrollNE    => Cursor.GetHCURSOR("ScrollNE")

    /** Handle to the system "ScrollSW" southwest scroll cursor
     * @type {HCURSOR} */
    static ScrollSW    => Cursor.GetHCURSOR("ScrollSW")

    /** Handle to the system "ScrollSE" southeast scroll cursor
     * @type {HCURSOR} */
    static ScrollSE    => Cursor.GetHCURSOR("ScrollSE")

    /** Handle to the system "CDArrow" alternative arrow cursor
     * @type {HCURSOR} */
    static CDArrow     => Cursor.GetHCURSOR("CDArrow")

    /** Handle to the system "Pin" location marker cursor
     * @type {HCURSOR} */
    static Pin         => Cursor.GetHCURSOR("Pin")

    /** Handle to the system "Person" user selection cursor
     * @type {HCURSOR} */
    static Person      => Cursor.GetHCURSOR("Person")

    /** Handle to a blank cursor. */
    static Blank => Cursor.Create("Blank", 32, 32, 16, 16, Cursor.Mask(32, 32, 0xFF), Cursor.Mask(32, 32))
}
