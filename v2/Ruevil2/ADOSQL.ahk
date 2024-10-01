; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=125462
; Author: Ruevil2

/*
###############################################################################################################
######                         ADOSQL v6 - By [VxE], Modified for V2 by Ruevil2                          ######
###############################################################################################################

	Wraps the utility of ADODB to connect to a database, submit a query, and read the resulting recordset.
	Returns the result as a new object (or array of objects, if the query has multiple statements).
	To instead have this function return a string, include a delimiter option in the connection string.

	IMPORTANT! Before you can use this library, you must have access to a database AND know the connection
	string to connect to your database.

	Varieties of databases will have different connection string formats, and different drivers (providers).
	Use the mighty internet to discover the connection string format and driver for your type of database.

	Example connection string for SQLServer (2005) listening on port 1234 and with a static IP:
	DRIVER={SQL SERVER};SERVER=192.168.0.12,3456;DATABASE=mydb;UID=admin;PWD=12345;APP=AHK
*/

Global ADOSQL_LastError := "", ADOSQL_LastQuery := "" ; These super-globals are for debugging your SQL queries.

ADOSQL( Connection_String, Query_Statement ) {
; Uses an ADODB object to connect to a database, submit a query and read the resulting recordset.
; By default, this function returns an object. If the query generates exactly one result set, the object is
; a 2-dimensional array containing that result (the first row contains the column names). Otherwise, the
; returned object is an array of all the results. To instead have this function return a string, append either
; ";RowDelim=`n" or ";ColDelim=`t" to the connection string (substitute your preferences for "`n" and "`t").
; If there is more than one table in the output string, they are separated by 3 consecutive row-delimiters.
; ErrorLevel is set to "Error" if ADODB is not available, or the COM error code if a COM error is encountered.
; Otherwise ErrorLevel is set to zero.

	coer := "",	txtout := 0, rd := "`n", cd := "CSV", str := Connection_String, o3DA := []

	; Examine the connection string for output formatting options.
	If ( 9 < oTbl := 9 + InStr(";" str, ";RowDelim=") ){
		rd := SubStr(str, (oTbl)<1 ? (oTbl)-1 : (oTbl), 0 - oTbl + oRow := InStr(str ";", ";", 0, (oTbl)<1 ? (oTbl)-1 : (oTbl)))
		str := SubStr(str, 1, oTbl - 11) SubStr(str, (oRow)<1 ? (oRow)-1 : (oRow))
		txtout := 1
	}
	If ( 9 < oTbl := 9 + InStr(";" str, ";ColDelim=") ){
		cd := SubStr(str, (oTbl)<1 ? (oTbl)-1 : (oTbl), 0 - oTbl + oRow := InStr(str ";", ";", 0, (oTbl)<1 ? (oTbl)-1 : (oTbl)))
		str := SubStr(str, 1, oTbl - 11) SubStr(str, (oRow)<1 ? (oRow)-1 : (oRow))
		txtout := 1
	}

	; Create a connection object. > https://www.w3schools.com/asp/ado_ref_connection.asp
	; If something goes wrong here, return empty array and set the error message.
	;Try catches all returned error messages and handles them all via catch
	;Catch is jumped to as soon as an error message occurs
	Try{
		oCon := ComObject("ADODB.Connection")	; Create ADOSQL Object
		oCon.ConnectionTimeout := 9 			; Allow 9 seconds to connect to the server.
		oCon.CursorLocation := 3 				; Use a client-side cursor server.
		oCon.CommandTimeout := 1800 			; A generous 30 minute timeout on the actual SQL statement.
		oCon.Open( str ) 						; open the connection.
		oRec := oCon.execute( ADOSQL_LastQuery := Query_Statement )

		While IsObject( oRec ){
			If !oRec.State ; Recordset.State is zero if the recordset is closed, so we skip it.
				oRec := oRec.NextRecordset()
			Else{ ; A row-returning operation returns an open recordset
				oFld := oRec.Fields
				o3DA.Push( oTbl := [] )
				oTbl.Push( oRow := [] )

				Loop oFld.Count ; Put the column names in the first row.
					oRow.Push(oFld.Item[ A_Index - 1 ].Name)
				
				While !oRec.EOF{ ; While the record pointer is not at the end of the recordset...
					oTbl.Push( oRow := [] )
					Loop oFld.Count
						oRow.Push(oFld.Item[ A_Index - 1 ].Value)
					oRec.MoveNext() ; move the record pointer to the next row of values
				}
				oRec := oRec.NextRecordset() ; Get the next recordset.
			}
		}
		If (txtout){ ; If the user wants plaintext output, copy the results into a string
			Query_Statement := "x"
			Loop o3DA.Length{
				Query_Statement .= rd rd
				oTbl := o3DA[ A_Index ]
				Loop oTbl.Length{
					oRow := oTbl[ A_Index ]
					Loop oRow.Length
						If ( cd = "CSV" ){
							str := oRow[ A_Index ]
							str := StrReplace(str, "`"", "`"`"")
							If !ErrorLevel || InStr(str, ",") || InStr(str, rd)
								str := "'" str "'"
							Query_Statement .= ( A_Index = 1 ? rd : "," ) str
						}
						Else
							Query_Statement .= ( A_Index = 1 ? rd : cd ) oRow[ A_Index ]
				}
			}
			Query_Statement := SubStr(Query_Statement, (2 + 3 * StrLen( rd ))<1 ? (2 + 3 * StrLen( rd ))-1 : (2 + 3 * StrLen( rd )))
		}

		; Close the connection and return the result. Local objects are cleaned up as the function returns.
		oCon.Close()
		ErrorLevel := coer
		Return txtout ? Query_Statement : o3DA.Length = 1 ? o3DA[1] : o3DA
	}
	catch as e{ ; Oh NOES!! Put a description of each error in 'ADOSQL_LastError'.
		;MsgBox("Exception thrown!`n`nwhat: " e.what "`n`nfile: " e.file "`n`nline: " e.line "`n`nmessage: " e.message "`n`nextra: " e.extra,, 16)
		
		oErr := oCon.Errors ; > https://www.w3schools.com/asp/ado_ref_error.asp
		Query_Statement := "x"
		Loop oErr.Count
		{
			oFld := oErr.Item( A_Index - 1 )
			str := oFld.Description
			Query_Statement .= "`n`n`n" SubStr(str, (1 + InStr(str, "]", 0, (2 + InStr(str, "][", 0, -1))<1 ? (2 + InStr(str, "][", 0, -1))-1 : (2 + InStr(str, "][", 0, -1))))<1 ? (1 + InStr(str, "]", 0, (2 + InStr(str, "][", 0, -1))<1 ? (2 + InStr(str, "][", 0, -1))-1 : (2 + InStr(str, "][", 0, -1))))-1 : (1 + InStr(str, "]", 0, (2 + InStr(str, "][", 0, -1))<1 ? (2 + InStr(str, "][", 0, -1))-1 : (2 + InStr(str, "][", 0, -1))))) . "`n   Number: " oFld.Number . ", NativeError: " oFld.NativeError . ", Source: " oFld.Source . ", SQLState: " oFld.SQLState . ", User: " A_UserName . ", Date: " FormatTime(A_Now)
		}
		ADOSQL_LastError := SubStr(Query_Statement, 4)
		FileAppend(ADOSQL_LastError, "ADOSQLErrorLog.txt")
		Query_Statement := ""
		txtout := 1
		Return o3DA
	}
}