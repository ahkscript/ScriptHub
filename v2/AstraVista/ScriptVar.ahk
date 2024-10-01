; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=127205
; Author: AstraVista

; ----------------------------------------------------------------------------------------------------------------------------------
; ScriptVar
; Packet creator: Object deep clone, compile, and parse
;
; AutoHotkey V2 (2.0.11)
;
; Author: AstraVista
; Version: 2024.03.17
;
; Part of ScriptSock project:
;	https://www.autohotkey.com/boards/viewtopic.php?f=83&t=126320&p=559938#p559938
; ----------------------------------------------------------------------------------------------------------------------------------

class ScriptVar
{
	; Attribute are defined as a name in base, and a value in the class.
	static Attribute :=
	{
		; TEST1
		aAttribute: Map(),
	}

	; Property are defined as a name in the class, and a value in the class instance.
	static Property :=
	{
		sTargetScript: "",
		sSourceScript: "",
		sCommand: "",
		aData: Map(),
		aMsg: Map(),
		aFlag: Map(),
	}

	; Externals are defined only in the class.
	static External :=
	{
		; TEST1
		sExternal: "",
	}

	; Internals are defined both the class and the class instance. Therefore, it can accessed with "this." in both.
	static Internal :=
	{
		Delim:
		{
			PACK: ";",
			PACK_TRAN: "^PACKET^",
			DESC: ":",
			DESC_TRAN: "^DESCRIPTOR^",
			KIND: "@",
			KIND_TRAN: "^KIND^",
			OBJS: "{",
			OBJS_TRAN: "^OBJSTART^",
			OBJE: "}",
			OBJE_TRAN: "^OBJEND^",
		}
	}

	static __New()
	{
		ScriptVar.DeleteProp("__New")

		; OwnProps() returns not in defining order but randomly.
		; Thus, creating order is random.
		for vName, vValue in ScriptVar.OwnProps()
		{
			if (vName = "Attribute")
			{
				for vName, vValue in ScriptVar.%vName%.OwnProps()
				{
					ScriptVar.base.DefineProp(vName, {Value: vName})
				}

				for vName, vValue in ScriptVar.%vName%.OwnProps()
				{
					ScriptVar.DefineProp(vName, {Value: vValue})
				}
			}

			if (vName = "Property")
			{
				for vName, vValue in ScriptVar.%vName%.OwnProps()
				{
					ScriptVar.DefineProp(vName, {Value: vName})
				}

				for vName, vValue in ScriptVar.%vName%.OwnProps()
				{
					ScriptVar.Prototype.DefineProp(vName, {Value: vValue})
				}
			}

			if (vName = "External")
			{
				for vName, vValue in ScriptVar.%vName%.OwnProps()
				{
					ScriptVar.DefineProp(vName, {Value: vValue})
				}
			}

			if (vName = "Internal")
			{
				for vName, vValue in ScriptVar.%vName%.OwnProps()
				{
					ScriptVar.base.Prototype.DefineProp(vName, {Value: vValue})
				}
			}
		}
	}

	__New(sTargetScript := "", sCommand := "", aData := Map(), aMsg := Map(), aFlag := Map())
	{
		for vName, vValue in ScriptVar.Property.OwnProps()
		{
			this.%vName% := vValue
		}

		this.sTargetScript := sTargetScript
		this.sSourceScript := A_ScriptFullPath
		this.sCommand := sCommand
		this.aData := aData.Clone()
		this.aMsg := aMsg.Clone()
		this.aFlag := aFlag.Clone()
	}

	Call(sTargetScript := "", sCommand := "", aData := Map(), aMsg := Map(), aFlag := Map())
	{
		this.__New(sTargetScript, sCommand, aData, aMsg, aFlag)
		return(this)
	}

	; ==============================================================================================================================
	; ObjDeepClone() Method
	; ==============================================================================================================================

	static ObjDeepClone(oSource)
	{
		bDebugA := true
		bDebugB := false

		; --------------------------------------------------------------------------------------------------------------------------
		; Clone Object
		; --------------------------------------------------------------------------------------------------------------------------

		; Object must have Clone() method. But, use try {}.
		if (bDebugB)
		{
			MsgBox("Type " Type(oSource) " is cloning.")
		}

		try
		{
			oTarget := oSource.Clone()
		}
		catch
		{
			if (bDebugA)
			{
				MsgBox("Type '" Type(oSource) "' is skipped in Clone() of ObjDeepClone().")
			}
			return (oSource)
		}

		; --------------------------------------------------------------------------------------------------------------------------
		; Enumerate Properties
		; --------------------------------------------------------------------------------------------------------------------------

		if (Type(oTarget) = "Array")
		{
			for vPropName, vPropData in oTarget
			{
				if (IsObject(vPropData))
				{
					if (bDebugB)
					{
						MsgBox("Array Start: " vPropName " -> Data: " Type(vPropData))
					}
					oTarget[vPropName] := this.ObjDeepClone(vPropData)
					if (bDebugB)
					{
						MsgBox("Array End: " vPropName " -> Data: " Type(oTarget[vPropName]))
					}
				}
			}
		}
		else if (Type(oTarget) = "Map")
		{
			for vPropName, vPropData in oTarget
			{
				; If Map has an object in the left side, it has to be skipped.
				; For, if the left side object is cloned, Map cannot search the object with the same name any more unfortunately.
				if (IsObject(vPropName))
				{
					if (bDebugA)
					{
						MsgBox("[" Type(oTarget) " Property Left] Reference `"" Type(vPropName) "`" is skipped in the enumeration of ObjDeepClone().")
					}
				}
				else
				{
					if (IsObject(vPropData))
					{
						if (bDebugB)
						{
							MsgBox("Map Start: " vPropName " -> Data: " Type(vPropData))
						}
						oTarget[vPropName] := this.ObjDeepClone(vPropData)
						if (bDebugB)
						{
							MsgBox("Map End: " vPropName " -> Data: " Type(oTarget[vPropName]))
						}
					}
				}
			}
		}
		; Object must have OwnProps() method.
		else if (oTarget is Object)
		{
			oEnumerator := 0
			try
			{
				oEnumerator := oSource.OwnProps()
			}
			if (oEnumerator)
			{
				for vPropName, vPropData in oEnumerator
				{
					if (IsObject(vPropData))
					{
						if (bDebugB)
						{
							MsgBox("Object Start: " vPropName " -> Data: " Type(vPropData))
						}

						; Down to the next level.
						oTarget.%vPropName% := this.ObjDeepClone(vPropData)
						if (bDebugB)
						{
							MsgBox("Object End: " vPropName " -> Data: " Type(oTarget.%vPropName%))
						}
					}
				}
			}
		}

		if (bDebugB)
		{
			MsgBox("Type " Type(oTarget) " is returning.")
		}

		return (oTarget)
	}

	; ==============================================================================================================================
	; ObjCompile() Method
	; ==============================================================================================================================

	static ObjCompile(oSource, &sPacket := -1)
	{
		bDebugA := true

		; --------------------------------------------------------------------------------------------------------------------------
		; Top Level
		; --------------------------------------------------------------------------------------------------------------------------

		if (sPacket = -1)
		{
			sPacket := ""

			if (Type(oSource) = "Array")
			{
				sPacket .= this.Delim.KIND "Array"
			}
			else if (Type(oSource) = "Map")
			{
				sPacket .= this.Delim.KIND "Map"
			}
			else if (oSource is Object)
			{
				try
				{
					%Type(oSource)%()
				}
				catch
				{
					if (bDebugA)
					{
						MsgBox(" Type `"" Type(oSource) "`" is skipped in Call() of ObjCompile().")
					}
					return ("")
				}

				sPacket .= this.Delim.KIND Type(oSource)
			}

			; Down to the main level.
			sPacket .= this.Delim.OBJS
			this.ObjCompile(oSource, &sPacket)
			sPacket .= this.Delim.OBJE

			return (sPacket)
		}

		; --------------------------------------------------------------------------------------------------------------------------
		; Main Level
		; --------------------------------------------------------------------------------------------------------------------------

		oEnumerator := 0

		if (Type(oSource) = "Map" Or Type(oSource) = "Array")
		{
			oEnumerator := oSource
		}
		; Object must have OwnProps() method.
		else if (oSource is Object)
		{
			oEnumerator := oSource.OwnProps()
		}

		if (oEnumerator)
		{
			for vPropName, vPropData in oEnumerator
			{
				if (IsObject(vPropName))
				{
					if (bDebugA)
					{
						MsgBox("[" Type(oSource) " Property Left] Reference `"" Type(vPropName) "`" is skipped in the enumeration of ObjCompile().")
					}

					continue
				}

				; All classes have prototype, which is enumerated.
				if (vPropName = "Prototype")
				{
					if (bDebugA)
					{
						MsgBox("[" Type(oSource) " Property Left] `"" vPropName "`" is skipped in the enumeration of ObjCompile().")
					}

					continue
				}

				; Limitation:
				; - static Property[]{Get, Set} is included in the enumerator.
				; - But there is no way to check and skip them. So, the name and the value of current data is inserted.

				sPacket .= vPropName
				sPacket .= this.Delim.DESC

				if (IsObject(vPropData))
				{
					try
					{
						%Type(vPropData)%()
					}
					catch
					{
						if (bDebugA)
						{
							MsgBox("[" Type(oSource) " Property " vPropName "] Type `"" Type(vPropData) "`" is skipped in Call() of ObjCompile().")
						}
					}
					else
					{
						sPacket .= this.Delim.KIND Type(vPropData)

						; Down to the next level.
						sPacket .= this.Delim.OBJS
						this.ObjCompile(vPropData, &sPacket)
						sPacket .= this.Delim.OBJE
					}
				}
				else
				{
					for vName, vValue in this.Delim.OwnProps()
					{
						if (!InStr(vName, this.Delim.TRAN))
						{
							vPropData := StrReplace(vPropData, vValue, this.Delim.%(vName this.Delim.TRAN)%)
						}
					}

					sPacket .= vPropData
				}

				sPacket .= this.Delim.PACK
			}

			sPacket := RTrim(sPacket, this.Delim.PACK)
		}

		return
	}

	; ==============================================================================================================================
	; ObjParse() Method
	; ==============================================================================================================================

	static ObjParse(sPacket, oTarget := -1)
	{
		bDebugA := true
		bDebugB := false

		bUseCallMethod := true
		bUseMapDefault := true

		if (bUseMapDefault)
		{
			sMapDefault := ""
		}

		; --------------------------------------------------------------------------------------------------------------------------
		; Top Level
		; --------------------------------------------------------------------------------------------------------------------------

		if (oTarget = -1)
		{
			if (Type(sPacket) != "String")
			{
				return (0)
			}

			aPack := StrSplit(sPacket, this.Delim.PACK)
			if (aPack.Length = 0)
			{
				return (0)
			}

			aDesc := StrSplit(aPack[1], this.Delim.DESC)

			vPropData := aDesc[1]

			if (RegExMatch(vPropData, this.Delim.KIND "(.*?)\" this.Delim.OBJS, &sKindName))
			{
				if (bUseCallMethod)
				{
					oTarget := %sKindName[1]%()
				}
				else
				{
					oTarget := {}
					oTarget.base := %sKindName[1]%.Prototype
				}
			}
			else
			{
				return (0)
			}

			if (bDebugB)
			{
				MsgBox("Top level start:`n`nPacket: " sPacket "`n`n" Type(oTarget) "`n`n-> " SubStr(sPacket, InStr(sPacket, this.Delim.OBJS) + 1))
			}

			; Down to the main level.
			sPacket := SubStr(sPacket, InStr(sPacket, this.Delim.OBJS) + 1)
			sPacket := this.ObjParse(sPacket, oTarget)

			if (bDebugB)
			{
				MsgBox("Top level end:`n`n" sKindName[1] "`n`nPacket: " sPacket)
			}

			return (oTarget)
		}

		; --------------------------------------------------------------------------------------------------------------------------
		; Main Level
		; --------------------------------------------------------------------------------------------------------------------------

		Loop
		{
			; ----------------------------------------------------------------------------------------------------------------------
			; Parse Packet
			; ----------------------------------------------------------------------------------------------------------------------
			aPack := StrSplit(sPacket, this.Delim.PACK)

			if (aPack.Length = 0)
			{
				if (bDebugB)
				{
					MsgBox("Packet: " sPacket "`n`nReturn: End of packet")
				}

				return (sPacket)
			}

			aDesc := StrSplit(aPack[1], this.Delim.DESC)

			if (aDesc.Length <= 1)
			{
				if (aDesc.Length = 1)
				{
					if (InStr(aDesc[1], this.Delim.OBJE))
					{
						if (bDebugB)
						{
							MsgBox("Packet: " sPacket "`n`nReturn: " aDesc[1] "`n`n-> " LTrim(SubStr(sPacket, InStr(sPacket, this.Delim.OBJE) + 1), this.Delim.PACK))
						}

						; Up to the previous level.
						sPacket := LTrim(SubStr(sPacket, InStr(sPacket, this.Delim.OBJE) + 1), this.Delim.PACK)
						return (sPacket)
					}
					else
					{
						iPackStartPos := InStr(sPacket, this.Delim.PACK)
						sPacket := (iPackStartPos) ? SubStr(sPacket, iPackStartPos + 1) : ""
					}
				}
				else
				{
					sPacket := ""
				}
			}

			vPropName := aDesc[1]
			vPropData := aDesc[2]

			if (bDebugB)
			{
				MsgBox("Seperate property:`n`nPacket: " sPacket "`n`n" vPropName "`n" vPropData)
			}

			; ----------------------------------------------------------------------------------------------------------------------
			; Create Object
			; ----------------------------------------------------------------------------------------------------------------------
			if (InStr(vPropData, this.Delim.OBJS))
			{
				if (RegExMatch(vPropData, this.Delim.KIND "(.*?)\" this.Delim.OBJS, &sKindName))
				{
					oCreateObj := 0
					try
					{
						oCreateObj := %sKindName[1]%()
					}

					if (!oCreateObj)
					{
						if (bDebugA)
						{
							MsgBox("[" Type(oTarget) " Property " vPropName "] Type `"" sKindName[1] "`" is skipped in Call() of ObjParse().")
						}
					}
					else
					{
						; Make a shallow copy of Map's Default property to the created object in only first level.
						; Because, below first level, all structures of object are newly created,
						; and previously created data are all removed already.
						; If avoiding this, must make objects from bottom to top. But this is almost impossible to make.
						; Or do not create object if it already exist, but this makes object's stuctures corrupted.

						if (IsSet(sMapDefault))
						{
							if (Type(oCreateObj) = "Map")
							{
								try
								{
									sMapDefault := oTarget[vPropName].Default
								}
								catch
								{
									try
									{
										sMapDefault := oTarget.%vPropName%.Default
									}
								}
								oCreateObj.Default := sMapDefault
							}
						}

						if (Type(oTarget) = "Array")
						{
							oTarget.InsertAt(vPropName, oCreateObj)
						}
						else if (Type(oTarget) = "Map")
						{
							oTarget[vPropName] := oCreateObj
						}
						else if (IsObject(oTarget))
						{
							oTarget.%vPropName% := oCreateObj
						}
					}

					if (bDebugB)
					{
						MsgBox("Object begin:`n`nPacket: " sPacket "`n`n" sKindName[1] "`n`n-> " SubStr(sPacket, InStr(sPacket, this.Delim.OBJS) + 1))
					}

					; Down to the next level.
					sPacket := SubStr(sPacket, InStr(sPacket, this.Delim.OBJS) + 1)
					sPacket := this.ObjParse(sPacket, oCreateObj)

					if (bDebugB)
					{
						MsgBox("Object end:`n`n" sKindName[1] "`n`nPacket: " sPacket)
					}
				}
			}
			; ----------------------------------------------------------------------------------------------------------------------
			; Input Data
			; ----------------------------------------------------------------------------------------------------------------------
			else
			{
				iObjEndPos := 0

				if (InStr(vPropData, this.Delim.OBJE))
				{
					iObjEndPos := InStr(sPacket, this.Delim.OBJE)
					vPropData := StrReplace(vPropData, this.Delim.OBJE)
				}

				for vName, vValue in this.Delim.OwnProps()
				{
					if (!InStr(vName, this.Delim.TRAN))
					{
						vPropData := StrReplace(vPropData, this.Delim.%(vName this.Delim.TRAN)%, vValue)
					}
				}

				if (Type(oTarget) = "Array")
				{
					if (oTarget.Has(vPropName))
					{
						oTarget.RemoveAt(vPropName)
					}
					oTarget.InsertAt(vPropName, vPropData)
				}
				else if (Type(oTarget) = "Map")
				{
					oTarget[vPropName] := vPropData
				}
				else if (IsObject(oTarget))
				{
					oTarget.%vPropName% := vPropData
				}

				if (iObjEndPos)
				{
					if (bDebugB)
					{
						MsgBox("Set value: `n`nPacket: " sPacket "`n`n" vPropName "`n" vPropData "`nReturn: " "true" "`n`n->" LTrim(SubStr(sPacket, iObjEndPos + 1), this.Delim.PACK))
					}

					; Up to the previous level.
					sPacket := LTrim(SubStr(sPacket, iObjEndPos + 1), this.Delim.PACK)
					return (sPacket)
				}
				else
				{
					if (bDebugB)
					{
						MsgBox("Set value: `n`nPacket: " sPacket "`n`n" vPropName "`n" vPropData "`nReturn: " "false" "`n`n->" SubStr(sPacket, InStr(sPacket, this.Delim.PACK) + 1))
					}

					iPackStartPos := InStr(sPacket, this.Delim.PACK)
					sPacket := (iPackStartPos) ? SubStr(sPacket, iPackStartPos + 1) : ""
				}
			}
		}

		return (sPacket)
	}
}