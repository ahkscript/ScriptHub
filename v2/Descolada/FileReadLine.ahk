; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=117999
; Author: Descolada

FileReadLine(FileName, LineNum) => (content := FileRead(Filename), Trim(SubStr(content, start := LineNum = 0 ? IndexError() : (LineNum = 1 ? 0 : (InStr(content, "`n",,, LineNum < 0 ? LineNum : LineNum-1) || (LineNum < 0 && (LineNum = -1 || InStr(content, "`n",,, LineNum+1)) ? 0 : IndexError()))) + 1, (next := InStr(content, "`n",, start)) ? next-start : unset), "`r"))