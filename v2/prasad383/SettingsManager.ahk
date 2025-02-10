; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=135324
; Author: prasad383

#Requires AutoHotkey v2.0

; Create default settings
defaultSettings := Map(
    "width", "500",
    "height","700",
    "Theme", "Dark"
)

; Initialize settings manager
preferences := SettingsManager("sample settings.ini", defaultSettings)


; Get a setting
width := preferences.getSetting("WindowWidth")

; Update one setting at a time.
preferences.setSetting("Theme", "Light")
preferences.setSetting("width", "900")

; or add/Update multiple settings at once
newSettings := Map("width", "1024", "colour", "ffffff")
preferences.updateSettings(newSettings)

; Get all current settings and store to a map for quick access
settings_map := preferences.getAllSettings()

MsgBox("width - " settings_map["width"])
MsgBox("Theme - " settings_map["Theme"])

;Reset all settings to default if needed and then again obtain the map.
preferences.resetToDefault()
settings_map := preferences.getAllSettings()

; now it will show default values.
MsgBox("width - " settings_map["width"])
MsgBox("Theme - " settings_map["Theme"])

; to delete a setting --
; preferences.deleteSetting("width")


;==================================================================

class SettingsManager {
    ; Private properties
    _filePath := ""
    _settings := Map()
    _defaultSettings := Map()
    
    /**
     * Constructor - Initialize the settings manager with file path and default settings
     * @param filePath The path to the .ini file
     * @param defaultSettings Map containing default settings
     */
    __New(filePath, defaultSettings := Map()) {
        this._filePath := filePath
        this._defaultSettings := defaultSettings
        
        ; Check if settings file exists, if not create it with defaults
        if !FileExist(this._filePath) {
            this._createDefaultSettings()
        }
        
        ; Load all settings from file
        this._loadSettings()
    }
    
    /**
     * Create the settings file with default values
     */
    _createDefaultSettings() {
        for key, value in this._defaultSettings {
            IniWrite(value, this._filePath, "Settings", key)
        }
    }
    
    /**
     * Load all settings from the .ini file into the settings map
     */
    _loadSettings() {
        try {
            ; Read the Settings section contents
            sectionContent := IniRead(this._filePath, "Settings")
            
            ; Parse the section content into key-value pairs
            Loop Parse, sectionContent, "`n", "`r" {
                if (A_LoopField = "")
                    continue
                    
                ; Split each line into key and value
                if (colonPos := InStr(A_LoopField, "=")) {
                    key := SubStr(A_LoopField, 1, colonPos - 1)
                    value := SubStr(A_LoopField, colonPos + 1)
                    this._settings[key] := value
                }
            }
        } catch Error as err {
            ; If section doesn't exist, create it with default settings
            this._createDefaultSettings()
        }
    }
    

    /**
     * Get a setting value
     * @param key The setting key
     * @param defaultValue Optional default value if setting doesn't exist
     * @returns The setting value or defaultValue if not found
     */
    getSetting(key, defaultValue := "") {
        try {
            value := IniRead(this._filePath, "Settings", key)
            this._settings[key] := value  ; Update cache
            return value
        } catch Error as err {
            return defaultValue
        }
    }
    
    /**
     * Update a single setting
     * @param key The setting key
     * @param value The new value
     */
    setSetting(key, value) {
        this._settings[key] := value
        IniWrite(value, this._filePath, "Settings", key)
    }
    
    /**
     * Update multiple settings at once
     * @param settingsMap Map of settings to update
     */
    updateSettings(settingsMap) {
        for key, value in settingsMap {
            this.setSetting(key, value)
        }
    }
    
    /**
     * Get all current settings
     * @returns Map of all settings
     */
    getAllSettings() {
        return this._settings.Clone()
    }
    
    /**
     * Reset all settings to default values
     */
    resetToDefault() {
        FileDelete(this._filePath)
        this._createDefaultSettings()
        this._loadSettings()
    }
    
    /**
     * Delete a setting
     * @param key The setting key to delete
     */
    deleteSetting(key) {
        if this._settings.Has(key) {
            this._settings.Delete(key)
            IniDelete(this._filePath, "Settings", key)
        }
    }
}