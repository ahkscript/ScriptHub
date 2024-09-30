; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=133138
; Author: FanaticGuru

;{ [Function] SpellCurrency
; Fanatic Guru
;
; Version: 2024 09 16
;
; #Requires AutoHotkey v2
;
; FUNCTION to Convert a Number to Currency Words
;------------------------------------------------
; Converts:  123.45  ==>  One Hundred Twenty-Three Dollars and Forty-Five cents
;
; Function:
;	SpellCurrency(MyNumber, NoDollars := true, NoCents := true, Bill := 'Dollar', Coin := 'cent', BillPlural := 'Dollars', CoinPlural := 'cents')
;
; Examples:
; MsgBox SpellCurrency(1000000012344.02, , , 'Pound', 'Penny', 'Pounds', 'Pence')
; MsgBox SpellCurrency(1000000012344.02, , , 'Euro', , 'Euro')
; MsgBox SpellCurrency(1000000012344.00, false, false) 	; do not put 'No cents'
; MsgBox SpellCurrency(0.12, false, false)				; do not put 'No Dollars'
; MsgBox SpellCurrency('123.456,12',,,,,,, true)	; string: invert . and ,
; MsgBox SpellCurrency('$123 456,12',,,,,,, true)	; string: invert and ignore space and $
;
SpellCurrency(MyNumber, NoDollars := true, NoCents := true, Bill := 'Dollar', Coin := 'cent', BillPlural := 'Dollars', CoinPlural := 'cents', InvertDecimal := false)
{
	If InvertDecimal
	{
		MyNumber := RegExReplace(MyNumber, ' |\.|\$')
		MyNumber := RegExReplace(MyNumber, ',', '.')
	}
	Else
		MyNumber := RegExReplace(MyNumber, ' |,|\$')
	Place := Array('', ' Thousand ', ' Million ', ' Billion ', ' Trillion ')
	Count := 1, Dollars := '', Cents := ''
	MyNumber := Trim(String(MyNumber))
	DecimalPlace := InStr(MyNumber, '.')
	If DecimalPlace
	{
		Cents := GetTens(SubStr(SubStr(MyNumber '00', DecimalPlace + 1), 1, 2))
		MyNumber := Trim(SubStr(MyNumber, 1, DecimalPlace - 1))
	}
	While MyNumber
	{
		Temp := GetHundreds(SubStr(MyNumber, -3))
		If Temp
			Dollars := Temp Place[Count] Dollars
		If StrLen(MyNumber) > 3
			MyNumber := SubStr(MyNumber, 1, StrLen(MyNumber) - 3)
		Else
			MyNumber := ''
		Count := Count + 1
	}
	Switch Dollars
	{
		Case '': (NoDollars ? Dollars := 'No ' BillPlural : Dollars := '')
		Case 'One': Dollars := 'One ' Bill
		Default: Dollars := Dollars ' ' BillPlural
	}
	Switch Cents
	{
		Case '': (NoCents ? Cents := ' No ' CoinPlural : Cents := '')
		Case 'One': Cents := ' One ' Coin
		Default: Cents := ' ' Cents ' ' CoinPlural
	}
	If Dollars and Cents
		Cents := ' and' Cents
	Return Dollars Cents

	GetHundreds(MyNumber)
	{
		Result := ''
		If !Number(MyNumber)
			Return
		MyNumber := SubStr('000' MyNumber, -3)
		; Convert the hundreds place.
		If SubStr(MyNumber, 1, 1) != '0'
			Result := GetDigit(SubStr(MyNumber, 1, 1)) ' Hundred '
		; Convert the tens and ones place.
		If SubStr(MyNumber, 2, 1) != '0'
			Result := Result GetTens(SubStr(MyNumber, 2))
		Else
			Result := Result GetDigit(SubStr(MyNumber, 3))
		Return Result
	}
	GetTens(TensText)
	{
		Result := '' ; Null out the temporary function value.
		If Number(SubStr(TensText, 1, 1)) = 1 ; If value between 10-19
		{
			Switch Number(TensText)
			{
				Case 10: Result := "Ten"
				Case 11: Result := "Eleven"
				Case 12: Result := "Twelve"
				Case 13: Result := "Thirteen"
				Case 14: Result := "Fourteen"
				Case 15: Result := "Fifteen"
				Case 16: Result := "Sixteen"
				Case 17: Result := "Seventeen"
				Case 18: Result := "Eighteen"
				Case 19: Result := "Nineteen"
			}
		}
		Else ; If value between 20-99
		{
			Switch Number(SubStr(TensText, 1, 1))
			{
				Case 2: Result := "Twenty"
				Case 3: Result := "Thirty"
				Case 4: Result := "Forty"
				Case 5: Result := "Fifty"
				Case 6: Result := "Sixty"
				Case 7: Result := "Seventy"
				Case 8: Result := "Eighty"
				Case 9: Result := "Ninety"
			}
			If (Digits := GetDigit(SubStr(TensText, -1)))
				If Result
					Result := Result '-' Digits
				Else
					Result := Digits

		}
		Return Result
	}
	GetDigit(Digit)
	{
		Switch Number(Digit)
		{
			Case 1: Result := "One"
			Case 2: Result := "Two"
			Case 3: Result := "Three"
			Case 4: Result := "Four"
			Case 5: Result := "Five"
			Case 6: Result := "Six"
			Case 7: Result := "Seven"
			Case 8: Result := "Eight"
			Case 9: Result := "Nine"
			Default: Result := ""
		}
		Return Result
	}
}
;}