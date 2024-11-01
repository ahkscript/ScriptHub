class ObjMap {
    static Call(obj) {
        switch Type(Obj) {
            case "Map":
                obj.__Get:=MapGet
                return obj
            case "Object":
                obj.DefineProp("__Item",{ get: ObjGet })
                obj.__Enum := (_,NumberOfVars) { ;manually exclude "__Item" and "__Enum" from the Enumerator
                    obj_enumerator := obj.OwnProps()
                    return (&k, &v?) {
                        loop { ;loop until ret==0 or k isn't one of these "meta" functions
                            ret := obj_enumerator(&k, &v)
                            if (ret) {
                                switch k {
                                    case "__Item", "__Enum":continue
                                }
                            }
                            return ret
                        }
                    }
                }
                return obj
        }
        ObjGet(_, name, params*) {
            if (!obj.HasOwnProp(name)) {
                Throw ValueError("key does not exist", -2, name)
            }
            return obj.%name%
        }
        MapGet(_, name, params*) {
            if (!obj.Has(name)) {
                Throw ValueError("key does not exist", -2, name)
            }
            return obj[name]
        }
    }
}

class OrderedMap {

    static Call(some_map,keys,arr) {
        static __ItemFunc :=Map.Prototype.GetOwnPropDesc("__Item").get
        some_map.DefineProp("__Item",{ get: MapGet })
        some_map.DefineProp("__Enum",{ value: (_, NumberOfVars) {
            idx:=1
            return (&OutputVar1, &OutputVar2?) {
                if (idx > keys.Length) {
                    return 0
                }
                OutputVar1:=keys[idx]
                OutputVar2:=arr[idx]
                ++idx
                return 1
            }
        } })
        some_map.__Get := MapGet
        return some_map
        MapGet(_, name, params*) {
            if (Type(name) == "Integer") {
                return arr[name]
            }
            if (!some_map.Has(name)) {
                Throw ValueError("key does not exist", -2, name)
            }
            return __ItemFunc(some_map, name)
        }
    }
}

sqlite(db_path,sqlite_path:="sqlite3.dll") { ;sqlite version 3460000
    hModule:=DllCall("GetModuleHandleW","WStr","sqlite3.dll","Ptr") || DllCall("LoadLibraryW","WStr",sqlite_path,"Ptr")
    if (!hModule) {
        throw "failed to load sqlite3.dll using path: " sqlite_path
    }

    filename:=Buffer(StrPut(db_path,"UTF-8")),StrPut(db_path,filename,"UTF-8")
    DllCall("sqlite3\sqlite3_open","Ptr",filename,"Ptr*",&sqlite3:=0,"Int")

    prepare(_,statement) {
        zSql:=Buffer(StrPut(statement,"UTF-8")),StrPut(statement,zSql,"UTF-8")
        ret:=DllCall("sqlite3\sqlite3_prepare_v2","Ptr",sqlite3,"Ptr",zSql,"Int",zSql.Size,"Ptr*",&sqlite3_stmt:=0,"Ptr",0,"Int") ;small performance advantage to passing an nByte parameter that is the number of bytes in the input string including the nul-terminator ;https://www.sqlite.org/c3ref/prepare.html
        if (ret) {
            errmsg:=StrGet(DllCall("sqlite3\sqlite3_errmsg","Ptr",sqlite3,"Ptr"),"UTF-8")
            throw "(" ret ") " errmsg
        }

        bind_parameter_count:=DllCall("sqlite3\sqlite3_bind_parameter_count","Ptr",sqlite3_stmt,"Int")
        parameter_names:=[]
        N:=1
        indexed_or_named:=0
        while (N <= bind_parameter_count) {
            param_name_ptr:=DllCall("sqlite3\sqlite3_bind_parameter_name","Ptr",sqlite3_stmt,"Int",N,"Ptr")
            if (param_name_ptr) {
                param_name:=StrGet(param_name_ptr,"UTF-8")
                switch SubStr(param_name,1,1) {
                    case "?":
                        indexed_or_named|=2 ;"?NNN"
                        parameter_names.Push(N)
                    case ":","$","@":
                        indexed_or_named|=1 ;":AAA" or "@AAA" or "$AAA"
                        parameter_names.Push(SubStr(param_name,2))
                }
            } else {
                indexed_or_named|=2 ;"?"
                parameter_names.Push(N)
            }

            if (indexed_or_named == 3) {
                throw Error("prepare(sql): can't mix Array mode with Object mode`neither use only indexed params (`"?`" , `"?NNN`") for Array mode`nor use only named params (`":AAA`", `"@AAA`", `"$AAA`") for Object mode")
            }
            ++N
        }

        column_count:=DllCall("sqlite3\sqlite3_column_count","Ptr",sqlite3_stmt,"Int")
        column_names:=[]
        N:=0
        while (N < column_count) {
            column_names.Push(StrGet(DllCall("sqlite3\sqlite3_column_name","Ptr",sqlite3_stmt,"Int",N,"Ptr"),"UTF-8"))
            ++N
        }

        all(_,obj:={},no_additional_params_here*) {
            switch indexed_or_named {
                case 1:
                    switch Type(obj) {
                        case "Map","Object":
                        default:
                            throw Error("cannot use .all(arg1, arg2, arg3, ...) for Object mode (named params)`ncorrect usage for Object mode is .all({key1:arg1, key2:arg2, key3:arg3})`nor use: .all(Map(`"key1`",arg1, `"key2`",arg2, `"key3`",arg3))`nor use .all(some_obj_or_map)")
                    }
                    some_map:=ObjMap(obj)
                case 2:
                    for arg in obj {
                        switch Type(arg) {
                            case "Map","Object":
                                throw Error("cannot pass Map or Object to Array mode (indexed params)`ncorrect usage for Array mode is .all(arg1, arg2, arg3, ...)")
                        }
                    }
                    if (obj.Length !== bind_parameter_count) {
                        throw Error("expected N params for .all(arg1, arg2, arg3, ...), didn't get N params",, "expected: " bind_parameter_count ", got: " obj.Length)
                    }
                    some_map:=obj
            }
            DllCall("sqlite3\sqlite3_reset","Ptr",sqlite3_stmt,"Int")
            saveBufArr:=[]
            for parameter_name in parameter_names { ;A_Index=bind_parameter_idx
                arg:=some_map[parameter_name]
                switch Type(arg) {
                    case "Integer":
                        ret:=DllCall("sqlite3\sqlite3_bind_int64","Ptr",sqlite3_stmt,"Int",A_Index,"Int64",arg,"Int")
                    case "Float":
                        ret:=DllCall("sqlite3\sqlite3_bind_double","Ptr",sqlite3_stmt,"Int",A_Index,"Double",arg,"Int")
                    case "Buffer":
                        ret:=DllCall("sqlite3\sqlite3_bind_blob","Ptr",sqlite3_stmt,"Int",A_Index,"Ptr",arg,"Int",arg.size,"Ptr",0,"Int")
                        case "NULL":
                        ret:=DllCall("sqlite3\sqlite3_bind_null","Ptr",sqlite3_stmt,"Int",A_Index,"Int")
                    case "String":
                        bindStr:=Buffer(StrPut(arg,"UTF-8")),StrPut(arg,bindStr,"UTF-8")
                        saveBufArr.Push(bindStr)
                        ret:=DllCall("sqlite3\sqlite3_bind_text","Ptr",sqlite3_stmt,"Int",A_Index,"Ptr",bindStr,"Int",bindStr.size - 1,"Ptr",0,"Int") ;where the NUL terminator would occur ;https://www.sqlite.org/c3ref/bind_blob.html
                    default:
                        throw arg
                }
                if (ret) {
                    throw ret
                }
            }

            rows:=[]
            loop {
                rescode:=DllCall("sqlite3\sqlite3_step","Ptr",sqlite3_stmt,"Int")
                switch (rescode) {
                    case 100: ;SQLITE_ROW
                        columns:=Map(),keys_arr:=[],values_arr:=[]
                        iCol:=0
                        while (iCol < column_count) {
                            datatype:=DllCall("sqlite3\sqlite3_column_type","Ptr",sqlite3_stmt,"Int",iCol,"Int")
                            switch (datatype) {
                                case 1: ;SQLITE_INTEGER
                                    column_value:=DllCall("sqlite3\sqlite3_column_int64","Ptr",sqlite3_stmt,"Int",iCol,"Int64")
                                case 2: ;SQLITE_FLOAT
                                    column_value:=DllCall("sqlite3\sqlite3_column_double","Ptr",sqlite3_stmt,"Int",iCol,"Double")
                                case 4: ;SQLITE_BLOB
                                    column_value:={
                                        Ptr:DllCall("sqlite3\sqlite3_column_blob","Ptr",sqlite3_stmt,"Int",iCol,"Ptr"),
                                        Size:DllCall("sqlite3\sqlite3_column_bytes","Ptr",sqlite3_stmt,"Int",iCol,"Int"),
                                        Base:{__Class:"Buffer"},
                                    }
                                case 5: ;SQLITE_NULL
                                    column_value:={Base:{__Class:"NULL"}}
                                case 3: ;SQLITE3_TEXT
                                    column_value:=StrGet(DllCall("sqlite3\sqlite3_column_text","Ptr",sqlite3_stmt,"Int",iCol,"Ptr"),"UTF-8")
                                default:
                                    throw datatype
                            }
                            column_name:=column_names[iCol+1]
                            keys_arr.push(column_name)
                            values_arr.push(column_value) ;Array notation
                            columns[column_name] := column_value ;Map notation
                            ++iCol
                        }
                        rows.Push(OrderedMap(columns,keys_arr,values_arr)) ;Object notation
                    case 101: ;SQLITE_DONE
                        break
                    case 19: ;SQLITE_CONSTRAINT
                        throw "SQLITE_CONSTRAINT"
                    default:
                        throw rescode
                }
            }
            return rows
        }
        all_Array_mode(_,args*) {
            return all(_,args)
        }
        return {
            mode:indexed_or_named==2 ? "Array" : "Object",
            all:indexed_or_named==2 ? all_Array_mode : all,
        }
    }
    return {
        prepare:prepare,
        NULL:{Base:{__Class:"NULL"}},
    }
}

; assertEquals(a,b) {
;     if (a!==b) {
;         throw "assertEquals failed"
;     }
; }

; assert_Enumerator(a,expected) {
;     idx:=0
;     for k, v in a {
;         assertEquals(k,expected[A_Index].key)
;         assertEquals(v,expected[A_Index].value)
;         idx:=A_Index
;     }
;     assertEquals(idx,expected.Length)

;     idx:=0
;     for k in a {
;         assertEquals(k,expected[A_Index].key)
;         idx:=A_Index
;     }
;     assertEquals(idx,expected.Length)
; }

; assertThrows(a,message) {
;     failed:=true
;     try {
;         a()
;     } catch Error as e {
;         if (e.Message == message) {
;             failed:=false
;         }
;     }
;     if (failed) {
;         throw "assertThrows failed"
;     }
; }

; db:=sqlite(":memory:","C:\Users\notme\Downloads\sqlite-dll-win-x64-3460000\sqlite3.dll")

; for some_obj_or_map in [
;     {ccc:"124",abc:232323},
;     Map("ccc","124","abc",232323)
; ] {
;     rows:=db.prepare("select $ccc, $abc").all(some_obj_or_map)
;     assertEquals(rows[1][1],"124")
;     assertEquals(rows[1][2],232323)
;     assertEquals(rows[1].%"$ccc"%,"124")
;     assertEquals(rows[1]["$ccc"],"124")
;     assertEquals(rows[1].%"$abc"%,232323)
;     assertEquals(rows[1]["$abc"],232323)
;     assert_Enumerator(rows[1],[
;         {key:"$ccc",value:"124"},
;         {key:"$abc",value:232323},
;     ])
; }

; rows:=db.prepare("select ?, ?").all("124",232323)
; assertEquals(rows[1][1],"124")
; assertEquals(rows[1][2],232323)
; assert_Enumerator(rows[1],[
;     {key:"?",value:"124"},
;     {key:"?",value:232323},
; ])

; assertThrows(()=>db.prepare("select $ccc, $abc").all("124",232323),"cannot use .all(arg1, arg2, arg3, ...) for Object mode (named params)`ncorrect usage for Object mode is .all({key1:arg1, key2:arg2, key3:arg3})`nor use: .all(Map(`"key1`",arg1, `"key2`",arg2, `"key3`",arg3))`nor use .all(some_obj_or_map)")
; assertThrows(()=>db.prepare("select ?, ?").all({ccc:"124",abc:232323}),"cannot pass Map or Object to Array mode (indexed params)`ncorrect usage for Array mode is .all(arg1, arg2, arg3, ...)")
; assertThrows(()=>db.prepare("select ?, $ccc"),"prepare(sql): can't mix Array mode with Object mode`neither use only indexed params (`"?`" , `"?NNN`") for Array mode`nor use only named params (`":AAA`", `"@AAA`", `"$AAA`") for Object mode")
; assertThrows(()=>db.prepare("select ?, ?").all(1),"expected N params for .all(arg1, arg2, arg3, ...), didn't get N params")
; db.prepare("select ?, ?").all(1,2)
; assertThrows(()=>db.prepare("select ?, ?").all(1,2,3),"expected N params for .all(arg1, arg2, arg3, ...), didn't get N params")


; db:=sqlite(":memory:","C:\Users\notme\Downloads\sqlite-dll-win-x64-3460000\sqlite3.dll")
; db.prepare("
; (
; CREATE TABLE debts (
;    DebtName TEXT,
;    Amount TEXT,
;    CreatedDate TEXT
; `)
; )").all()
; view_db() {
;     rows:=db.prepare("select DebtName,Amount,CreatedDate from debts").all()
;     for row in rows {
;         OutputDebug row.DebtName ": " row.Amount "`n"
;     }
; }

; db.prepare("insert into debts (DebtName,Amount,CreatedDate) VALUES (?,?,?)").all("Medical Bill",2000,"2024-08-25")
; db.prepare("update debts set Amount=? where DebtName=?").all(1500,"Medical Bill") ;Array mode: indexed params ("?" , "?NNN")
; view_db()
; db.prepare("update debts set Amount=$Amount where DebtName=$DebtName").all({Amount:1000,DebtName:"Medical Bill"}) ;Object mode: named params (":AAA", "@AAA", "$AAA")
; view_db()
; db.prepare("update debts set Amount=:Amount where DebtName=:DebtName").all(Map("Amount",500,"DebtName","Medical Bill")) ;Object mode: named params (":AAA", "@AAA", "$AAA")
; view_db()
