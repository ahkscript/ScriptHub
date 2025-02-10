; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=135125
; Author: prasad383

class HotKeyChain {
    ; Storage for subkey mappings
    subkeys := Map()
    ; Timer duration for GUI popup (default 2000ms)
    timeout := 2000
     ; Track if waiting for subkey
    waitingForSubkey := false
    ; Store GUI reference
    guiwindow := ""
    ; Store ListView reference
    lv := ""
    ; Track parent HotKeyChain instance
    parent := ""
    ; Track if this is a child instance
    isChild := false

    ; GUI options storage
    _gui_options := Map(
        "width", 500,
        "height", "Auto",
        "x", "Center",
        "y", "Center",
        "font_size", 12,
        "font_name", "Segoe UI",
        "background_color", ""
    )

    __New() {
        this.InitializeGui()
    }

    InitializeGui() {
        ; Create GUI with basic options
        this.guiwindow := Gui("+AlwaysOnTop -DPIScale +Owner", "Available Hotkeys")

        ; Set background color if specified
        if this._gui_options["background_color"]
            this.guiwindow.BackColor := this._gui_options["background_color"]

        ; Set font
        this.guiwindow.SetFont(
            "s" this._gui_options["font_size"] " Q5",
            this._gui_options["font_name"]
        )

        ; Add ListView with specified width
        this.lv := this.guiwindow.Add("ListView", "w" this._gui_options["width"] " -Hdr Report -E0x200", ["Key", "Function"])
        this.lv.opt("Background" this._gui_options["background_color"])
        ; Set up event handlers
        this.guiwindow.OnEvent("Close", (*) => this.Reset())
        this.lv.OnEvent("doubleclick", (*) => this.lv_clicked())
        this.lv.ModifyCol(1, this._gui_options["width"] * 0.3)
        this.lv.ModifyCol(2, this._gui_options["width"] * 0.69)
        this.guiwindow.Add("Button", "Hidden Default", "OK").OnEvent("Click", this.LV_Enter.Bind(this))
    }

    ; Property to set GUI options
    gui_options {
        set {
            ; Parse options string
            options := StrSplit(Value, " ")
            for option in options {
                if (SubStr(option, 1, 1) = "w")
                    this._gui_options["width"] := Integer(SubStr(option, 2))
                else if (SubStr(option, 1, 1) = "h")
                    this._gui_options["height"] := Integer(SubStr(option, 2))
                else if (SubStr(option, 1, 1) = "x")
                    this._gui_options["x"] := SubStr(option, 2)
                else if (SubStr(option, 1, 1) = "y")
                    this._gui_options["y"] := SubStr(option, 2)
                else if (SubStr(option, 1, 1) = "c")
                    this._gui_options["background_color"] := SubStr(option, 2)
                else if (SubStr(option, 1, 1) = "s")
                    this._gui_options["font_size"] := Integer(SubStr(option, 2))
            }
            ; Reinitialize GUI with new options
            this.InitializeGui()
            this.UpdateGui()
        }
    }

    ; Property to set show delay
    show_delay {
 
        ;set => this.timeout := Value
        set => this.timeout := Value = 0 ? 1 : Value

    }

    ; Property to set launch key
    launchkey {
        set => this.SetLaunchKey(Value)
    }


    SetLaunchKey(key) {
        Hotkey(key, (*) => this.Launch())
    }

    ; Add multiple functions with their subkeys
    AddFunctions(functionMap) {
        for key, func in functionMap {
            this.subkeys[key] := func
        }
        this.UpdateGui()
    }

    ; Add single function or HotKeyChain instance with subkey
    AddFunction(key, funcOrInstance) {
        if (Type(funcOrInstance) = "HotKeyChain") {
            funcOrInstance.parent := this
            funcOrInstance.isChild := true
        }
        this.subkeys[key] := funcOrInstance
        this.UpdateGui()
    }

    CreateSubkeyHandler(keyToHandle) {
        return (*) => this.SubkeyPressed(keyToHandle)
    }

    Launch() {
        if this.waitingForSubkey
            return
        Critical(1)
        this.waitingForSubkey := true

        for key, _ in this.subkeys {
            Try Hotkey(key, this.CreateSubkeyHandler(key), "On")
        }

        SetTimer(() => this.ShowGui(), -this.timeout)
        Hotkey("Escape", (*) => this.Reset(), "On")
        Critical(0)

        Try SoundPlay "C:\Windows\Media\Windows Default.wav"
        ; settimer((*) => SoundBeep(200,100), -10)

    }

    SubkeyPressed(key) {
        if !this.waitingForSubkey
            return

        this.Reset()

        if (this.subkeys.Has(key)) {
            value := this.subkeys[key]
            if (Type(value) = "Func")
                value()
            else if (Type(value) = "HotKeyChain")
                value.Launch()
        }
    }

    lv_clicked() {
        if (rowNumber := this.lv.GetNext()) {
            key := this.lv.GetText(rowNumber, 1)
            if (this.subkeys.Has(key)) {
                value := this.subkeys[key]
                this.Reset()  ; Hide GUI first
                if (Type(value) = "Func")
                    value()
                else if (Type(value) = "HotKeyChain")
                    value.Launch()
            }
        } else {
            this.Reset()
        }
    }

    Reset() {
        this.waitingForSubkey := false
        this.guiwindow.Hide()

        for key, _ in this.subkeys {
            try Hotkey(key, "Off")
        }

        Hotkey("Escape", "Off")

        if (this.isChild && this.parent)
            this.parent.Reset()

    }

    UpdateGui() {
        this.lv.Delete()

        for key, value in this.subkeys {
            description := Type(value) = "Func"
                ? value.Name
                : Type(value) = "HotKeyChain"
                    ? "Nested Hotkeys"
                : "Anonymous Function"
            this.lv.Add(, key, description)
        }

        ; Set ListView height
        if (this._gui_options["height"] = "Auto") {
            LVM_CalculateSize(this.lv.hwnd, , &Wdth, &rht)
            height := Max(Min(rht, 700), 50)			; You can change max listview height here. 
            this.lv.Move(, , , height)
        } else {
            this.lv.Move(, , , this._gui_options["height"])
        }
    }

    ShowGui() {
        if !this.waitingForSubkey
            return

        ; Build show options string
        showOpts := "AutoSize"  ; NoActivate"

        ; Add position if not centered
        if (this._gui_options["x"] != "Center")
            showOpts .= " x" this._gui_options["x"]
        if (this._gui_options["y"] != "Center")
            showOpts .= " y" this._gui_options["y"]

        this.guiwindow.Show(showOpts)
    }

    LV_Enter(*) {
        if this.guiwindow.FocusedCtrl != this.lv
            return

        if (rowNumber := this.lv.GetNext(0, "Focused")) {
            key := this.lv.GetText(rowNumber, 1)
            if (this.subkeys.Has(key)) {
                value := this.subkeys[key]
                this.Reset()  ; Hide GUI first
                if (Type(value) = "Func")
                    value()
                else if (Type(value) = "MasterKey")
                    value.Launch()
            }
        }
    }


}

; Helper function.  https://www.autohotkey.com/boards/viewtopic.php?style=23&t=42570
/**
 * Calculate the width and height required to display a given number of rows of a ListView control.
 * @param hLV The handle to the ListView control
 * @param p_NumberOfRows The number of rows to be displayed (-1 to use current number of rows)
 * @param &r_Width Output variable for the calculated width
 * @param &r_Height Output variable for the calculated height
 * @returns Integer containing width (LOWORD) and height (HIWORD) in pixels
 */
LVM_CalculateSize(hLV, p_NumberOfRows := -1, &r_Width := 0, &r_Height := 0) {
    ; Define messages
    static LVM_GETITEMCOUNT := 0x1004        ; LVM_FIRST + 4
    static LVM_APPROXIMATEVIEWRECT := 0x1040 ; LVM_FIRST + 64

    ; Collect and/or adjust the number of rows
    if (p_NumberOfRows < 0) {
        p_NumberOfRows := SendMessage(LVM_GETITEMCOUNT, 0, 0, , "ahk_id " hLV)
    }

    ; Adjust number of rows (if not zero)
    if p_NumberOfRows {
        p_NumberOfRows -= 1
    }

    ; Calculate size
    result := SendMessage(LVM_APPROXIMATEVIEWRECT, p_NumberOfRows, -1, , "ahk_id " hLV)

    ; Extract and adjust values
    r_Width := (result & 0xFFFF) + 4     ; LOWORD
    r_Height := (result >> 16) + 4       ; HIWORD

    ; Return combined result
    return (r_Height << 16) | r_Width
}