#Requires AutoHotkey v2.0 
#include ..\lib\packages.ahk

A_FileEncoding := "UTF-8"

if !(ForumsJson := FileRead("forums.json"))
    throw Error("Empty file")

if !(Content := JSON.Load(ForumsJson))
    throw Error("Problem loading JSON from file content")

if !(Dump := JSON.Dump(Content, true))
    throw Error("Problem dumping JSON")

FileOpen("forums.json", "w").Write(Dump)