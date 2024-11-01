; Source: https://www.autohotkey.com/boards/viewtopic.php?t=122655
; Author: Delta Pythagorean

/**
 * # Lua.ahk
 * Extend *your* AHK program with Lua!
 *
 * ## Requirements
 * | Library | Tested Version | External Link |
 * | --- | --- | --- |
 * | AutoHotkey | 2.0.6 | https://www.autohotkey.com/download |
 * | Lua | 5.4.2 (Release 1) | https://luabinaries.sourceforge.net |
 *
 * # How To Install
 * 1. Download this script into your `/lib/` folder for your current project or into your AutoHotkey library directory.
 * Read more here: https://www.autohotkey.com/docs/v2/Scripts.htm#lib
 * 2. Use `#include` to include the library into your AHK program.
 * 3. Validate you have `lua54.dll` with your project. Make sure to use `#DllLoad` and set it to the path of the Lua DLL, for example: `#DllLoad %A_ScriptDir%\lua54.dll`
 * 4. Look up a tutorial for using Lua in C (with some minor adjustments to the syntax) and you're on your way.
 *
 * # Notes
 * - Lua does not have *all* of the functions defined publically for the Lua DLL.
 *   Therefore, translating the functions directly to a DllCall won't be easy.
 *   There are some functions that are just macros (read the Macros section below for more information),
 *   However some functions downright don't exist externally, such as `lua_call`, `lua_pcall`, and many others.
 *   So directly translating C code into AHK won't be a perfect solution.
 * - I have provided a list of functions that the lua54 DLL has and removed the functions that are currently present in this file.
 *   You may add them yourself if you so desire.
 * - I have not tested all functions (within this file) to see if they work.
 *   I only have used various examples strewn about within Lua's documentation to see if they work.
 *   A lot of the functions do in fact work :)
*/

#Requires AutoHotkey v2.0

; Attempt to load the lua DLL if present.
#DllLoad *i lua54.dll

; =============================================================================
; # Global Variables

; This is not defined in Lua's source, this is a simple NULL variable added to AHK.
; In C, NULL is a null pointer with the position of 0.
; In AHK, I recommend to use a blank string.
global NULL                     := ""

global LUA_MULTRET              := -1

global LUA_OK                   := 0
global LUA_YIELD                := 1
global LUA_ERRRUN               := 2
global LUA_ERRSYNTAX            := 3
global LUA_ERRMEM               := 4
global LUA_ERRERR               := 5

/*
 * LUAI_MAXSTACK limits the size of the Lua stack.
 * Its only purpose is to stop Lua from consuming unlimited stack
 * space (and to reserve some numbers for pseudo-indices).
 * (It must fit into max(size_t)/32 and max(int)/2.)
*/
; SO. The provided lua DLL is compiled in 32 bit.
; Regardless of AHK's bit size (32 or 64) Lua's stack size will always be 32 bit.
global LUAI_MAXSTACK            := 1000000 ; A_PtrSize == 4 ? 1000000 : 15000

; minimum Lua stack available to a C function
global LUA_MINSTACK             := 20

global LUA_REGISTRYINDEX        := (-LUAI_MAXSTACK - 1000)

global LUA_TNONE                := -1

global LUA_TNIL                 := 0
global LUA_TBOOLEAN             := 1
global LUA_TLIGHTUSERDATA       := 2
global LUA_TNUMBER              := 3
global LUA_TSTRING              := 4
global LUA_TTABLE               := 5
global LUA_TFUNCTION            := 6
global LUA_TUSERDATA            := 7
global LUA_TTHREAD              := 8

global LUA_NUMTYPES             := 9

global LUA_RIDX_MAINTHREAD      := 1
global LUA_RIDX_GLOBALS         := 2
global LUA_RIDX_LAST            := LUA_RIDX_GLOBALS

global LUA_NOREF                := -2
global LUA_REFNIL               := -1

; =============================================================================
; # To-Be-Created Functions

/*
lua_arith
lua_atpanic
lua_checkstack
lua_compare
lua_concat
lua_dump
lua_gc
lua_getallocf
lua_getfield
lua_gethook
lua_gethookcount
lua_gethookmask
lua_geti
lua_getinfo
lua_getiuservalue
lua_getlocal
lua_getmetatable
lua_getstack
lua_isyieldable
lua_len
lua_load
lua_newstate
lua_newthread
lua_newuserdatauv
lua_next
lua_pushboolean
lua_pushfstring
lua_pushlightuserdata
lua_pushlstring
lua_pushthread
lua_pushvalue
lua_pushvfstring
lua_rawequal
lua_rawgetp
lua_rawsetp
lua_resetthread
lua_resume
lua_setallocf
lua_setcstacklimit
lua_sethook
lua_seti
lua_setiuservalue
lua_setlocal
lua_setmetatable
lua_setwarnf
lua_status
lua_stringtonumber
lua_tocfunction
lua_toclose
lua_tointegerx
lua_tothread
lua_touserdata
lua_upvalueid
lua_upvaluejoin
lua_version
lua_warning
lua_xmove
lua_yieldk
lual_addgsub
lual_addlstring
lual_addstring
lual_addvalue
lual_argerror
lual_buffinit
lual_buffinitsize
lual_callmeta
lual_checkany
lual_checkinteger
lual_checklstring
lual_checknumber
lual_checkoption
lual_checkstack
lual_checkudata
lual_checkversion_
lual_error
lual_execresult
lual_fileresult
lual_getmetafield
lual_getsubtable
lual_gsub
lual_len
lual_loadbufferx
lual_loadstring
lual_newmetatable
lual_optinteger
lual_optlstring
lual_optnumber
lual_prepbuffsize
lual_pushresult
lual_pushresultsize
lual_requiref
lual_setfuncs
lual_setmetatable
lual_testudata
lual_tolstring
lual_traceback
lual_typeerror
lual_where
*/

; =============================================================================
; # Functions

luaL_loadfilex(L, filename, mode) => DllCall("lua54.dll\luaL_loadfilex", "ptr", L, "astr", String(filename), mode == null ? "int" : "str", mode == null ? 0 : String(mode))
luaL_newstate() => DllCall("lua54.dll\luaL_newstate", "ptr")
luaL_openlibs(L) => DllCall("lua54.dll\luaL_openlibs", "ptr", L)
luaL_checktype(L, arg, t) => DllCall("lua54.dll\luaL_checktype", "ptr", L, "int", Integer(arg), "int", Integer(t))

; As of currently, this doesn't seem to do what I want it to do. It throws an access violation.
; Perhaps I'm using these functions wrong/in the wrong place. I don't know.
; For now, it's up for usage and you're free to run with it.
; Just be aware.
luaL_ref(L, t) => DllCall("lua54.dll\luaL_ref", "ptr", L, "int", t)
luaL_unref(L, t) => DllCall("lua54.dll\luaL_unref", "ptr", L, "int", t)

lua_absindex(L, idx) => DllCall("lua54.dll\lua_absindex", "ptr", L, "int", idx)
lua_close(L) => DllCall("lua54.dll\lua_close", "ptr", L)
lua_copy(L, fromidx, toidx) => DllCall("lua54.dll\lua_copy", "ptr", L, "int", Integer(fromidx), , "int", Integer(toidx))
lua_createtable(L, narr, nrec) => DllCall("lua54.dll\lua_createtable", "ptr", L, "int", Integer(narr), "int", Integer(nrec))
lua_error(L) => DllCall("lua54.dll\lua_error", "ptr", L)
lua_getglobal(L, name) => DllCall("lua54.dll\lua_getglobal", "ptr", L, "astr", name)
lua_getupvalue(L, funcindex, n) => DllCall("lua54.dll\lua_getupvalue", "ptr", L, "int", funcindex, "int", n)
lua_gettable(L, index) => DllCall("lua54.dll\lua_gettable", "ptr", L, "int", Integer(index))
lua_gettop(L) => DllCall("lua54.dll\lua_gettop", "ptr", L)
lua_iscfunction(L, index) => DllCall("lua54.dll\lua_iscfunction", "ptr", L, "int", Integer(index))
lua_pcallk(L, nargs, nresults, msgh, ctx, k) => DllCall("lua54.dll\lua_pcallk", "ptr", L, "int", Integer(nargs), "int", Integer(nresults), "int", Integer(msgh), "int", ctx, k == null ? "int" : "ptr", k || 0)
lua_pushcclosure(L, f, n) => DllCall("lua54.dll\lua_pushcclosure", "ptr", L, "ptr", f, "int", Integer(n))
lua_pushnumber(L, n) => DllCall("lua54.dll\lua_pushnumber", "ptr", L, "double", Float(n))
lua_pushinteger(L, n) => DllCall("lua54.dll\lua_pushinteger", "ptr", L, "int", Integer(n))
lua_pushliteral(L, s) => DllCall("lua54.dll\lua_pushliteral", "ptr", L, "astr", String(s))
lua_pushnil(L) => DllCall("lua54.dll\lua_pushnil", "ptr", L)
lua_pushstring(L, s) => DllCall("lua54.dll\lua_pushstring", "ptr", L, "astr", String(s))
lua_rawget(L, index) => DllCall("lua54.dll\lua_rawget", "ptr", L, "int", Integer(index))
lua_rawgeti(L, index, n) => DllCall("lua54.dll\lua_rawgeti", "ptr", L, "int", Integer(index), "int", Integer(n))
lua_rawlen(L, index) => DllCall("lua54.dll\lua_rawlen", "ptr", L, "int", index)
lua_rawset(L, index) => DllCall("lua54.dll\lua_rawset", "ptr", L, "int", Integer(index))
lua_rawseti(L, index, i) => DllCall("lua54.dll\lua_rawseti", "ptr", L, "int", Integer(index), "int", Integer(i))
lua_requiref(L, modname, openf, glb) => DllCall("lua54.dll\lua_rawseti", "ptr", L, "str", String(modname), "ptr", openf, "int", Integer(glb))
lua_rotate(L, idx, n) => DllCall("lua54.dll\lua_rotate", "ptr", L, "int", Integer(idx), "int", Integer(n))
lua_setfield(L, index, k) => DllCall("lua54.dll\lua_setfield", "ptr", L, "int", Integer(index), "astr", String(k))
lua_setglobal(L, name) => DllCall("lua54.dll\lua_setglobal", "ptr", L, "astr", name)
lua_setupvalue(L, funcindex, n) => DllCall("lua54.dll\lua_setupvalue", "ptr", L, "int", funcindex, "int", n)
lua_settable(L, index) => DllCall("lua54.dll\lua_settable", "ptr", L, "int", Integer(index))
lua_settop(L, index) => DllCall("lua54.dll\lua_settop", "ptr", L, "int", Integer(index))
lua_toboolean(L, index) => DllCall("lua54.dll\lua_toboolean", "ptr", L, "int", Integer(index))
lua_tointeger(L, index) => DllCall("lua54.dll\lua_tointegerx", "ptr", L, "int", Integer(index), "int", 0)

; NOTE:
; lua_tolstring returns 0 (or NULL) if it couldn't cast it to being a string.
; To make it easier for AHK to handle (and to not get an error thrown in StrGet())
; I've forced it to return a blank string if it could not return a string.
lua_tolstring(L, index, len)
{
	result := DllCall("lua54.dll\lua_tolstring", "ptr", L, "int", Integer(index), len == null ? "int" : "int*", len == null ? 0 : Integer(len))
	; We must check if the value returned was NULL, otherwise StrGet will silent crash AHK.
	return result == 0 ? "" : StrGet(result, "UTF-8")
}

lua_tonumberx(L, index, &isnum?) => DllCall("lua54.dll\lua_tonumberx", "ptr", L, "int", Integer(index), !IsSet(isnum) ? "int" : "int*", !IsSet(isnum) ? 0 : &isnum, "double")
lua_topointer(L, index) => Format("<pointer: {:#x}>", DllCall("lua54.dll\lua_topointer", "ptr", L, "int", Integer(index)))
lua_type(L, index) => DllCall("lua54.dll\lua_type", "ptr", L, "int", Integer(index))
lua_typename(L, tp) => StrGet(DllCall("lua54.dll\lua_typename", "ptr", L, "int", Integer(tp)), "UTF-8")
lua_callk(L, nargs, nresults, ctx, k) => DllCall("lua54.dll\lua_typename", "ptr", L, "int", Integer(nargs), "int", Integer(nresults), "int", ctx, k == null ? "int" : "ptr", k || 0)
luaopen_base(L) => DllCall("lua54.dll\luaopen_base", "ptr", L)
luaopen_package(L) => DllCall("lua54.dll\luaopen_package", "ptr", L)
luaopen_coroutine(L) => DllCall("lua54.dll\luaopen_coroutine", "ptr", L)
luaopen_table(L) => DllCall("lua54.dll\luaopen_table", "ptr", L)
luaopen_io(L) => DllCall("lua54.dll\luaopen_io", "ptr", L)
luaopen_os(L) => DllCall("lua54.dll\luaopen_os", "ptr", L)
luaopen_string(L) => DllCall("lua54.dll\luaopen_string", "ptr", L)
luaopen_math(L) => DllCall("lua54.dll\luaopen_math", "ptr", L)
luaopen_utf8(L) => DllCall("lua54.dll\luaopen_utf8", "ptr", L)
luaopen_debug(L) => DllCall("lua54.dll\luaopen_debug", "ptr", L)

; =============================================================================
; # Macro Functions
; These functions are not present (or not defined publicly for use) in the Lua DLL.
; However, they are macros in Lua's source code, available to read/use for yourself.
; Seeing as Lua has provided these for us, we can create them here.
; I don't know of any others, but it's pretty easy to translate them from C into AHK.

luaL_loadfile(L, filename) => luaL_loadfilex(L, filename, null)
luaL_dofile(L, filename) => (luaL_loadfile(L, filename) || lua_pcallk(L, 0, LUA_MULTRET, 0, 0, null))
lua_call(L, n, r) => lua_callk(L, n, r, 0, null)
lua_pcall(L, n, r, f) => lua_pcallk(L, n, r, f, 0, null)
lua_tostring(L, index) => lua_tolstring(L, index, null)
lua_tonumber(L, index) => lua_tonumberx(L, index)
lua_newtable(L) => lua_createtable(L, 0, 0)
lua_pop(L, n) => lua_settop(L, 0 - n - 1)
lua_register(L, n, f) => (lua_pushcfunction(L, f), lua_setglobal(L, n))
lua_pushcfunction(L, f) => lua_pushcclosure(L, f, 0)
lua_isnil(L, n) => (lua_type(L, n) == LUA_TNIL)
lua_isboolean(L, n) => (lua_type(L, n) == LUA_TBOOLEAN)
lua_islightuserdata(L, n) => (lua_type(L, n) == LUA_TLIGHTUSERDATA)
lua_isnumber(L, n) => (lua_type(L, n) == LUA_TNUMBER)
lua_isstring(L, n) => (lua_type(L, n) == LUA_TSTRING)
lua_istable(L, n) => (lua_type(L, n) == LUA_TTABLE)
lua_isfunction(L, n) => (lua_type(L, n) == LUA_TFUNCTION)
lua_isuserdata(L, n) => (lua_type(L, n) == LUA_TUSERDATA)
lua_isthread(L, n) => (lua_type(L, n) == LUA_TTHREAD)
lua_isnone(L, n) => (lua_type(L, n) == LUA_TNONE)
lua_isnoneornil(L,  n) => (lua_type(L, n) <= 0)
lua_pushglobaltable(L) => lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS)
lua_insert(L, idx) => lua_rotate(L, idx, 1)
lua_remove(L, idx) => (lua_rotate(L, idx, -1), lua_pop(L, 1))
lua_replace(L, idx) => (lua_copy(L, -1, idx), lua_pop(L, 1))
lua_upvalueindex(i) => (LUA_REGISTRYINDEX - (i))