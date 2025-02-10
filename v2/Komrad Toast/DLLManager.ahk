; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=134661
; Author: Komrad Toast

class DLLManager
{
    static Loaded := Map()
    static RefCounts := Map()

    static Load(dllPath)
    {
        if this.Loaded.Has(dllPath)
        {
            this.RefCounts[dllPath]++
            return this.Loaded[dllPath]
        }

        if (dll := DLLManager.DLL(dllPath))
        {
            this.Loaded[dllPath] := dll
            this.RefCounts[dllPath] := 1
            return dll
        }

        return false
    }

    static Unload(dllPath)
    {
        if this.Loaded.Has(dllPath)
        {
            this.RefCounts[dllPath]--

            if this.RefCounts[dllPath] <= 0
            {
                this.Loaded.Delete(dllPath)
                this.RefCounts.Delete(dllPath)
            }

            return true
        }

        return false
    }

    class DLL
    {
        Ptr := 0
        Path := ""
        ProcCache := Map()

        __New(dllPath)
        {
            if !(this.Ptr := DllCall("LoadLibrary", "Str", dllPath, "Ptr"))
                throw(OSError(A_LastError, -1))
            this.Path := dllPath
        }

        __Call(name, params)
        {
            if !this.ProcCache.Has(name)
                this.ProcCache[name] := this.GetProc(name)

            return DllCall(this.ProcCache[name], params*)
        }

        __Delete() => DllCall("FreeLibrary", "Ptr", this.Ptr)

        IsLoaded() => DllCall("GetModuleHandle", "Str", this.Path, "Ptr") ? true : false
        GetProc(name)
        {
            if !(funcAddr := DllCall("GetProcAddress", "Ptr", this.Ptr, "AStr", name, "Ptr"))
                throw(OSError(A_LastError, -1))

            return funcAddr
        }
        LoadProc(name) => ((this.ProcCache[name] := this.GetProc(name)) ? true : false)
        DeleteProc(name) => (this.ProcCache.Has(name) ? (this.ProcCache.Delete(name), true) : false)
    }
}