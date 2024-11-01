#Requires AutoHotkey v2.0 
#include <packages>

global g_Config, g_MainRepo := "ahkscript/ScriptHub/main", g_Forums := LoadJson(".\assets\forums.json")
global g_CacheDir := "cache", g_CheckIntervalInDays := 30, g_ErroredEntries := [], g_Verbose := 1
A_FileEncoding := "UTF-8"

LoadConfig()
Main()

Main() {
    global g_ErroredEntries
    for Author, Entries in g_Forums {
        For Entry in Entries {
            Entry["author"] := Author
            WriteStdOut "Processing entry for " Entry["author"] "/" Entry["main"]
            if !(Entry["main"] ~= "\.ahk?\d?$") && !InStr(Entry["main"], ".")
                Entry["main"] := Entry["author"] ".ahk"
            if !FileExist("..\..\" Entry["author"] "\" Entry["main"]) {
                if g_Verbose
                    WriteStdOut "Entry not found, querying snapshots from Wayback Machine"
                if !DirExist("..\..\" Entry["author"])
                    DirCreate("..\..\" Entry["author"])
                AddCommitsFromWayback(Entry)
            }
            
            if Entry.Has("last_check") {
                if (LastCheck := Abs(DateDiff(A_NowUTC, Entry["last_check"], "Days"))) < g_CheckIntervalInDays {
                    if g_Verbose
                        WriteStdOut "Last check was " LastCheck " days ago, skipping..."
                    goto Cleanup
                }
            }
            if g_Verbose
                WriteStdOut "Querying latest version from live forums"
            
            Result := MaybeAddLatestCommit(Entry)
            WriteStdOut ""

            if Result {
                g_ErroredEntries.Push(Author "/" Entry["main"])
            }

            Cleanup:
            Entry.Delete("author")
        }
    }
    if (NewContent := JSON.Dump(g_Forums, true))
        FileOpen("assets/forums.json", "w").Write(NewContent)
    if g_ErroredEntries.Length {
        WriteStdOut "There were problems with the following entries:"
        for Entry in g_ErroredEntries {
            WriteStdOut "`t" Entry
        }
    }
}

AddCommitsFromWayback(Entry) {
    local thread, start
    if !RegExMatch(Entry["url"], "t=(\d+)", &thread:="")
        throw Error("Detected AutoHotkey forums link, but couldn't find thread id", -1, Entry["url"])
    try Matches := QueryForumsWaybackSnapshots(thread[1], RegExMatch(Entry["url"], "&start=(\d+)", &start:="") ? start[1] : unset)
    catch {
        WriteStdOut "Error downloading Wayback snapshots"
        return 2
    }
    if !Matches.Count {
        if g_Verbose
            WriteStdOut "No Wayback snapshots found"
        return 1
    }
    LastCode := ""
    for Version, Url in Matches {
        if g_Verbose
            WriteStdOut "Adding snapshot dated " Version " for URL " Url
        SourceUrl := "http://web.archive.org/web/" Version "/" Url
        Code := ExtractCodeFromForums(SourceUrl, Entry.Has("codebox") ? Entry["codebox"] : unset, Entry.Has("post_id") ? Entry["post_id"] : unset)
        if Code = "" || (Entry.Has("required_substring") && !InStr(Code, Entry["required_substring"])) {
            WriteStdOut "Error extracting code from snapshot"
            WriteStdOut "`tSpecifically: " (Code = "" ? "extracted code was empty" : "code was missing the required substring `"" Entry["required_substring"] "`"")
            continue
        }
        Code := "; Source: " Entry["url"] "`n; Author: " Entry["author"] "`n" (Entry.Has("license") ? "; License: " Entry["license"] "`n" : "") "`n" Code
        if Code = LastCode {
            if g_Verbose
                WriteStdOut "File content hasn't changed, no commit made"
            continue
        }
        WriteStdOut "Creating git commit for " Version
        FileOpen("..\..\" Entry["author"] "\" Entry["main"], "w").Write(Code)
        RunWait('git add "' Entry["author"] '/' Entry["main"] '"', "..\..\", "Hide")
        RunWait('git commit -m "' Version '"', "..\..\", "Hide")
        LastCode := Code
    }
    return 0
}

MaybeAddLatestCommit(Entry) {
    Code := ExtractCodeFromForums(Entry["url"], Entry.Has("codebox") ? Entry["codebox"] : unset, Entry.Has("post_id") ? Entry["post_id"] : unset)
    Version := A_NowUTC
    if Code = "" || (Entry.Has("required_substring") && !InStr(Code, Entry["required_substring"])) {
        WriteStdOut "Error extracting code from live forums"
        WriteStdOut "`tSpecifically: " (Code = "" ? "extracted code was empty" : "code was missing the required substring `"" Entry["required_substring"] "`"")
        return 1
    }
    Code := "; Source: " Entry["url"] "`n; Author: " Entry["author"] "`n" (Entry.Has("license") ? "; License: " Entry["license"] "`n" : "") "`n" Code
    if FileExist("..\..\" Entry["author"] "\" Entry["main"]) && (Code == FileRead("..\..\" Entry["author"] "\" Entry["main"])) {
        if g_Verbose
            WriteStdOut "File content hasn't changed, no commit made"
        Entry["last_check"] := Version
        return 0
    }
    WriteStdOut "Creating git commit for " Version
    FileOpen("..\..\" Entry["author"] "\" Entry["main"], "w").Write(Code)
    RunWait('git add "' Entry["author"] '/' Entry["main"] '"', "..\..\", "Hide")
    RunWait('git commit -m "' Version '"', "..\..\", "Hide")
    Entry["last_check"] := Version
    return 0
}

ExtractCodeFromForums(SourceUrl, CodeBox:=1, PostId:=0) {
    try Page := DownloadURL(SourceUrl)
    catch as err {
        WriteStdOut "Problem downloading the code"
        WriteStdOut "`t" err.Message (err.Extra ? ": " err.Extra : "")
        return ""
    }
    if PostId && RegExMatch(Page, '<div id="p' PostId '([\w\W]+?)<div id="p\d+', &Post:="") {
        Page := Post[1]
    }
    CodeMatches := RegExMatchAll(Page, "<code [^>]*>([\w\W]+?)<\/code>")
    if !CodeMatches.Length
        return ""
    return UnHTM(CodeMatches[CodeBox][1])
}

LoadConfig() {
    global g_Config
    if !FileExist(A_ScriptDir "\assets\config.json")
        g_Config := Map()
    else
        g_Config := LoadJson(A_ScriptDir "\assets\config.json")
}
LoadJson(fileName, &RawContent:="") => JSON.Load(RawContent := FileRead(fileName))

WriteStdOut(msg) => FileAppend(msg "`n", "*")

QueryForumsWaybackSnapshots(ThreadId, Start?) {
    CdxJson := JSON.Load(DownloadURL("https://web.archive.org/cdx/search/cdx?url=autohotkey.com%2Fboards%2Fviewtopic.php&matchType=prefix&output=json&filter=statuscode:200&filter=urlkey:.*t=" ThreadId))
    if CdxJson.Length < 2
        return Map()
    CdxJson.RemoveAt(1)
    Matches := Map()
    for Entry in CdxJson {
        if IsSet(start) {
            if !(RegExMatch(Entry[3], "start=(\d+)", &match:="") && match[1] = start)
                continue
        } else {
            if InStr(Entry[3], "start=")
                continue
        }
        Matches[Entry[2]] := Entry[3]
    }
    return Matches
}

DownloadURL(url) {
    local req := ComObject("Msxml2.XMLHTTP")
    req.open("GET", url, true)
    req.send()
    while req.readyState != 4
        Sleep 100
    if req.status == 200 {
        return req.responseText
    } else
        throw Error("Download failed", -1, url)
}

; Forum Topic: www.autohotkey.com/forum/topic51342.html
UnHTM( HTM ) { ; Remove HTML formatting / Convert to ordinary text     by SKAN 19-Nov-2009
    Static HT := "&aacuteá&acircâ&acute´&aeligæ&agraveà&amp&aringå&atildeã&au" 
        . "mlä&bdquo„&brvbar¦&bull•&ccedilç&cedil¸&cent¢&circˆ&copy©&curren¤&dagger†&dagger‡&deg" 
        . "°&divide÷&eacuteé&ecircê&egraveè&ethð&eumlë&euro€&fnofƒ&frac12½&frac14¼&frac34¾&gt>&h" 
        . "ellip…&iacuteí&icircî&iexcl¡&igraveì&iquest¿&iumlï&laquo«&ldquo“&lsaquo‹&lsquo‘&lt<&m" 
        . "acr¯&mdash—&microµ&middot·&nbsp &ndash–&not¬&ntildeñ&oacuteó&ocircô&oeligœ&ograveò&or" 
        . "dfª&ordmº&oslashø&otildeõ&oumlö&para¶&permil‰&plusmn±&pound£&quot`"&raquo»&rdquo”&reg" 
        . "®&rsaquo›&rsquo’&sbquo‚&scaronš&sect§&shy­&sup1¹&sup2²&sup3³&szligß&thornþ&tilde˜&tim" 
        . "es×&trade™&uacuteú&ucircû&ugraveù&uml¨&uumlü&yacuteý&yen¥&yumlÿ"
    TXT := RegExReplace(HTM, "<[^>]+>"), R := ""               ; Remove all tags between  "<" and ">"
    Loop Parse, TXT, "&`;"                              ; Create a list of special characters
      L := "&" A_LoopField ";", R .= (InStr(HT, "&" A_LoopField) && !InStr(R, L, 1) ? L:"")
    R := SubStr(R, 1, -1)
    Loop Parse, R, "`;"                                ; Parse Special Characters
     If F := InStr(HT, A_LoopField)                  ; Lookup HT Data
       ; StrReplace() is not case sensitive
       ; check for StringCaseSense in v1 source script
       ; and change the CaseSense param in StrReplace() if necessary
       TXT := StrReplace(TXT, A_LoopField "`;", SubStr(HT, (F+StrLen(A_LoopField))<1 ? (F+StrLen(A_LoopField))-1 : (F+StrLen(A_LoopField)), 1))
     Else If ( SubStr(A_LoopField, 2, 1)="#" )
       ; StrReplace() is not case sensitive
       ; check for StringCaseSense in v1 source script
       ; and change the CaseSense param in StrReplace() if necessary
       TXT := StrReplace(TXT, A_LoopField "`;", SubStr(A_LoopField, 3))
   Return RegExReplace(TXT, "(^\s*|\s*$)")            ; Remove leading/trailing white spaces
}

ObjToQuery(oData) { ; https://gist.github.com/anonymous1184/e6062286ac7f4c35b612d3a53535cc2a?permalink_comment_id=4475887#file-winhttprequest-ahk
    static HTMLFile := InitHTMLFile()
    if (!IsObject(oData)) {
        return oData
    }
    out := ""
    for key, val in (oData is Map ? oData : oData.OwnProps()) {
        out .= HTMLFile.parentWindow.encodeURIComponent(key) "="
        out .= HTMLFile.parentWindow.encodeURIComponent(val) "&"
    }
    return "?" RTrim(out, "&")
}

InitHTMLFile() {
    doc := ComObject("HTMLFile")
    doc.write("<meta http-equiv='X-UA-Compatible' content='IE=Edge'>")
    return doc
}

EncodeDecodeURI(str, encode := true) {
    VarSetStrCapacity(&result:="", pcchEscaped:=500)
    if encode {
        DllCall("Shlwapi.dll\UrlEscape", "str", str, "ptr", StrPtr(result), "uint*", &pcchEscaped, "uint", 0x00080000 | 0x00002000)
    } else {
        DllCall("Shlwapi.dll\UrlUnescape", "str", str, "ptr", StrPtr(result), "uint*", &pcchEscaped, "uint", 0x10000000)
    }
    VarSetStrCapacity(&result, -1)
    return result
}

RegExMatchAll(haystack, needleRegEx, startingPosition := 1) {
	out := [], end := StrLen(haystack)+1
	While startingPosition < end && RegExMatch(haystack, needleRegEx, &outputVar, startingPosition)
		out.Push(outputVar), startingPosition := outputVar.Pos + (outputVar.Len || 1)
	return out
}