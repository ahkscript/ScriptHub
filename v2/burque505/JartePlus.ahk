; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=135720
; Author: burque505

#Requires AutoHotkey v2
;
; Do not modify this file! This file will be overwritten by subsequent Jarte
; upgrades, so any modifications made to it will be lost. Instead, create
; a separate AutoHotKey library script file and use #Include to use it in
; your Jarte script files.
;
; Note that the helper functions in this file only work for Jarte Plus.
; However, this file is also provided with the standard (free) edition
; of Jarte for reference purposes.
;


; Informs the Jarte program that the currently running script is finished. A call 
; to this function must be the last line in the script. This function must be called 
; from Jarte scripts that will be run from a Jarte template, but it can also be safely run 
; in scripts not associated with a template (in that case this function has no effect).
; 
;
JarteScriptEnd() {
;-------------
    ErrorLevel := SendMessage(32808, 0, 0, , "A")
}


; Returns the character position of the text cursor's current location.
; The first character in the document is at character position zero.
;
JarteGetSelPos() {
;-------------
    ErrorLevel := SendMessage(32809, 0, 0, , "A")
    return ErrorLevel
}


; Returns the length of the current text selection.
;
JarteGetSelLength() {
;----------------
    ErrorLevel := SendMessage(32810, 0, 0, , "A")
    return ErrorLevel
}


; Returns the text of the current text selection (up to the first 255 characters).
;
JarteGetSelText() {
    textContent := ""
    atom := SendMessage(32811, 0, 0, , "A")    ; SendMessage returns the result directly in v2
    
    if (atom != 0) {
        textBuffer := Buffer(256, 0)
        DllCall("GlobalGetAtomName", "Ptr", atom, "Ptr", textBuffer.Ptr, "Int", 255, "Cdecl UInt")
        textContent := StrGet(textBuffer)
        DllCall("GlobalDeleteAtom", "Ptr", atom)
    }
    
    Return textContent
}


; Sets the text selection to the specified start character position and the specified length.
; The first character in the document is at character position zero.
; If "length" is not specified then text cursor will move to the specified start position 
; and no text will be selected.
; If a "length" value of -1 is specified then the text selection will extend from the
; specified start position to the end of the document.
; If neither "start" nor "length" are specified then the entire document is selected.
; Returns the resulting text selection length.
;
JarteSetSel(start:=0, length:=0)
;----------
{
    ErrorLevel := SendMessage(32812, start, length, , "A")
    return ErrorLevel
}


; Returns the character position of the first occurrence of the specified target text.
; -1 is returned if the target text is not found.
; The first character in the document is at character position zero.
; The search begins at the character position specified by "startAt" (defaults to zero).
; If "select" equals true then the found target will be selected in the document (defaults to false).
; The length of the target text is limited to 255 characters.
;
JarteFind(target, startAt:=0, select:=false) {
;--------
    if (StrLen(target) > 255) {
        throw "JarteFind target length is greater than 255"
    }

    if (StrLen(target) = 0) {
        return startAt
    }

    if (select) {
        startAt := (startAt = 0) ? 0xFFFFFFFF : -startAt
    }

    atom := DllCall("GlobalAddAtom", "Str", target, "Cdecl Ptr")
    ErrorLevel := SendMessage(32813, atom, startAt, , "A")
    retCode := (ErrorLevel = 0xFFFFFFFF) ? -1 : ErrorLevel
    Return retCode
}


; Replaces the currently selected text with the specified replacement.
; If no replacement is specified then the currently selected text is deleted.
; The length of the replacement text is limited to 255 characters.
;
JarteReplaceSel(replacement) {
;--------------
    if (StrLen(replacement) > 255) {
        throw "JarteReplaceSel replacement length is greater than 255"
    }

    atom := replacement ? DllCall("GlobalAddAtom", "Str", replacement, "Cdecl Ptr") : 0
    ErrorLevel := SendMessage(32814, atom, 0, , "A")
    return ErrorLevel
}


; Replaces all occurrences of the specified target with the specified replacement.
; If no replacement is specified then all occurrences of the target are deleted.
; Returns the number of times the target was found and replaced.
; The target and replacement lengths are each limited to 255 characters.
;
JarteReplaceAll(target, replacement) {
;--------------
    if (StrLen(target) == 0) {
       Return 0
    }

    if (StrLen(target) > 255) {
        throw "JarteReplaceAll target length is greater than 255"
    }

    if (StrLen(replacement) > 255) {
        throw "JarteReplaceAll replacement length is greater than 255"
    }

    if (target = replacement) {
        if not (target == replacement) {
            throw "JarteReplaceAll cannot perform replacements where the target and replacement differ only in case"
        }
    } else {
       atom1 := DllCall("GlobalAddAtom", "Str", target, "Cdecl Ptr")
       atom2 := replacement ? DllCall("GlobalAddAtom", "Str", replacement, "Cdecl Ptr") : 0
       ErrorLevel := SendMessage(32815, atom1, atom2, , "A")
    }

    return ErrorLevel
}


; Runs the specified Jarte command. The valid Jarte command names can be found by
; viewing the list commands in Jarte's custom shortcut keys dialog window (i.e.,
; Options > Customize Shortcut Keys). Returns a value of 1 if the command is a 
; valid Jarte command, otherwise zero is returned.
;
JarteRunCommand(command) {
;--------------
    if (StrLen(command) == 0) {
       Return 0
    }

    if (StrLen(command) > 255) {
        throw "JarteRunCommand command length is greater than 255"
    }

    atom := DllCall("GlobalAddAtom", "Str", command, "Cdecl Ptr")
    ErrorLevel := SendMessage(32816, atom, 0, , "A")
    return ErrorLevel
}