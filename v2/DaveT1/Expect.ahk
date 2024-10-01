; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=130093
; Author: DaveT1

class ExpectClass
{
    /*  File Info....
    Description:
        - `expect` is a units testing framework. Full description and documentation in the links below.
        - `Expect for ahkv2.ahk` is for AutoHotkey v2. It's based on `expect.ahk`(as of 02-Apr-24).

    Input/Output/Return:
        Input:     		n/a
        Output:			n/a
        Return:			n/a

    Basic data:
        Name:        	Expect for ahkv2.ahk
        AHK Version: 	AutoHotkey 2.0.2
        OS Version: 	Microsoft Windows 11 Pro
        Credits:    	@Chunjee wrote the original `expect.ahk` AHKv1 code (https://www.autohotkey.com/boards/viewtopic.php?f=6&t=95017&e=1&view=unread#unread)
                        @DaveT1 did mods & made for AHKv2.
        Topic:     		ahkv1 at https://www.autohotkey.com/boards/viewtopic.php?f=6&t=95017&e=1&view=unread#unread
                        ahkv2 at https://www.autohotkey.com/boards/viewtopic.php?f=83&t=130093

    Parameters(alphabetical):
        pActual
            The actual value being passed in to compare against the Expected value below.
            Type = {number|string|object}, except in Undefined(...) where it's {number|string}.
            Default = "_Missing_Parameter_".
            
        pExpected
            The value that pActual is expected to be.
            Type = {number|string|object}.
            Default = "_Missing_Parameter_".
            
        psNote
            (optional) additional per-test free-form text.
            Type = {string}.
            Default = "".

        Further parameters are described in each method contained in this class.

    Revision History:
    vX(new or changed functionality / may not be backwards compatible).Y(minor revisons).
    [+=NEW, *=CHANGED, !=FIXED -=REMOVED]
        v1.1 26-May-24 (public)
            * Improved some comments.
            * Renamed report() as ShortReport().
            * Renamed `param_actual` as `pActual`.
            * Renamed `param_expected` as `pExpected`.
            * Renamed `param_note` as `psNote`.
            * Renamed `param_label` as either `psTestLabel` or `psGroupLabel` per method to better
                describe its purpose.
            * Renamed `pAHKFunc` as `psAHKFunc`
            * Renamed `pNote` as `psNote`
            * Renamed `psFilepath` as `psFilepath`
            * Renamed `.lastabel` as `.LastLabel`
            * Renamed `msg1` as `sFailMessage`
            * Renamed `group(...)` as `BatchLabel(...)`.
            * Renamed `returntext` as `sReturnText`.
            * Renamed `writeResultsToFile` as `WriteResultsToFile`.
            * Renamed `fullReport` as `FullReport`.
            * Modified text in msgbox title bar to better describe what's in the msgbox.
            * Streamlined (improved?) reporting text for test failures.
            + New method AHKIsFuncs adding some AHK Is functions. See 'Is Functions' in the AHK help file.
            + Added `iResetVars` to reporting functions to optionally allow class vars to be reset in 
                mid-sequence (of tests) so that subsequent tests are reported free of previous reporting data.
            - Removed `msg` as the was message format from original expect class. Replaced with `sFailMessage`.
            - Removed `this.LastLabel` as no longer serving a purpose.
        v1.0 13-Apr-24 (internal)
            + Initial release of `Expect for ahkv2.ahk`.
            Below are a list of major changes between `expect.ahk(02-Apr-24)` and `Expect for ahkv2.ahk`, 
                excluding, unless significant, ahk v1-->v2 syntax changes.
            + Added `TestType` to use with output to identify what each test was (equal, undefined, etc).
            + Underlining of the 1-line summary added to _build1LineSummaryOfTests() so that
            + Added to report() short code to write out the 1-line summary of tests as a msgbox.
                every time the 1-line summary is asked for it will be underlined.
            + Added blank test labelling in output (`== Lable: ==`) in _logTestFail(). This 
                improves visual clarity of outputs.
            + Added a new results string in _logTestFail() with better formatting of the test results
                ready for output via msgbox and/or file.
            + Added `psNote` to the test results string in _logTestFail().
            * Renamed _buildReport() as _build1LineSummaryOfTests() to better describe its purpose.
            * Renamed _final() as _finalWriteToStdOut() to better reflect its purpose.
            * Renamed _print() as _ConvObj2String() to better describe purpose.
            * Renamed `labelVar` as `TestLabel` to better decribe its purpose.
            * Renamed test() as _test() to better reflect that it is a private method.
            * Renamed `param_msg` as `psNote` in _logTestFail() for better consistency with rest of script.
            * Changed return in true() from false to whatever was returned from test().
            * Changed return in false() from false to whatever was returned from test().
            * Changed return in undefined() from false to whatever was returned from test().
            * Changed `logObj` to `log` in WriteResultsToFile() (`logObj` relic from an earlier version?).
            * Changed(minor) output string created in _final() (or _finalWriteToStdOut()).
            - Removed the underlining of the 1-line summary from FullReport().
            - Removed code in _logTestFail() which wrongly assigned `param_msg` to `labelVar`.
    */

    #Requires AutoHotkey 2.0-
    
	__New() 
    {
        this._ZeroiseClassVars()
	}

    _ZeroiseClassVars()
    {
		this.testTotal := 0
		this.failTotal := 0
		this.successTotal := 0
		this.log := []
		this.GroupLabel := ""
        this.GroupLabelActive := false
        this.iCount := 0
		this.TestLabel := ""
		this.finalTrigger := false
            ;Used in  ShortReport(), FullReport() and WriteResultsToFile() to control the final write 
            ;(of the 1-line summary) to stdOut. Is false until 1 of these methods is called, then is true.
            ;When true it prevents subsequent calls to these methods repeatedly writing the 1-line summary.

        this.TestType := ""
            ;Text to use with output to identify what each test was (equal, undefined, etc).
        
        iResetVars := 0
            ;Var controlling whether to 'reset' the class vars. This is used with `.ShortReport` 
            ;and `.FullReport` and works to allow reporting mid-test suite of the test results 
            ;so far, but then allows subsequent tests to be reported on their own.
            ;  = 0 (default)    false: ie., do not reset the class vars.
            ;  = 1              true: ie., reset the class vars.

        return
    }

    equal(pActual:="_Missing_Parameter_", pExpected:="_Missing_Parameter_", psNote:="") 
    {   ; Checks if `pActual`{number|string|object} and `pExpected`{number|string|object} inputs are equal. 
        ; The comparison is always case-sensitive.
        ; Returns {boolean} true if the values are equal, else false.

		if (A_IsCompiled) 
			return 0

        this.TestType := "equal"
		return this._test(pActual, pExpected, psNote)
	}

	notEqual(pActual:="_Missing_Parameter_", pExpected:="_Missing_Parameter_", psNote:="") 
    {   ; Checks if `pActual`{number|string|object} and `pExpected` {number|string|object} inputs are NOT equal. 
        ; The comparison is always case-sensitive.
        ; Returns {boolean} true if the values are equal, else false.
        ; Mostly, `_test` handles the object-2-string conversion and subsequent comparison tests. 
        ; But as notEqual is the reverse, the conversion and comparison are more easily handled here.

		if (A_IsCompiled)
			return 0

		pActual := this._ConvObj2String(pActual)
		pExpected := this._ConvObj2String(pExpected)

        this.TestType := "notEqual"
		this.testTotal += 1

		if (pActual != pExpected) 
        {
			this.successTotal++
			return true
		} 
        else 
        {
			this._logTestFail(pActual, pExpected, psNote)
			return false
		}
	}

	true(pActual:="_Missing_Parameter_", psNote:="") 
    {   ; checks if `pActual` {number|string} value is true.
        ; Returns {boolean} true if `pActual` is true, else false.

		if (A_IsCompiled)
			return 0

        this.TestType := "true"
		
        return this._test(pActual, true, psNote)
	}

	false(pActual:="_Missing_Parameter_", psNote:="") 
    {   ; Checks if `pActual` input is false.
        ; Returns {boolean}true if the value is false, else false.

		if (A_IsCompiled)
			return 0

        this.TestType := "false"
        
        if (pActual == false)      ;if pActual=0 it is 'false'.
        {
            pActual := "false"
            pExpected := "false"
        }
        else if (pActual == true)  ;if pActual=1 it is 'true'.
        {   
            pActual := "true"
            pExpected := "false"
        }
        else
        {
            pActual := pActual
            pExpected := "true"
        }
        
		return this._test(pActual, pExpected, psNote)
	}

	undefined(pActual:="_Missing_Parameter_", psNote:="") 
    {   ; Checks if `pActual` is undefined, ie is Set, but has no value so = "".
        ; Not originally stated, but assumed that this can only be for strings.
        ; Returns {boolean} true if the value is `""`, else false.

		if (A_IsCompiled)
			return 0

        this.TestType := "undefined"

		return this._test(pActual, "", psNote)
	}

    AHKIsFuncs(psAHKFunc, pValue?, psParam3:="", psNote:="")
    {   ; Allows the 'type | misc | string' to be checked using most of the AHKv2 Is functions.
        ; See "Is Functions" in the AHKv2 helpfile.
        ; Also includes AHKv2 InStr function.

        ; psAHKFunc
        ;   A String defining which of the AHKv2 "Is" function is required
        ;
        ; pValue
        ;   The value being passed to the selected Is function
        ;   Declared with "?" to allow for the possibility that it might be `UnSet` so as to allow
        ;       the UnSet test below to work.
        ;
        ; psNote
        ;   Optional additional free text to associate with the test.
        ;--------------------------------------------------------------------

        switch psAHKFunc
        {
            Case "InStr":
            {   ;Returns true if the needle(pValue) is in the haystack(psAHKFunc), else false.

                this.TestType := "InStr"
                iPos := %psAHKFunc%(pValue, psParam3)
                
                if (iPos > 0)
                    return this._test(1, true, psNote)
                else
                    return this._test(0, true, psNote) 
            }

            Case "IsInteger":
            {   ;Returns true if (pValue) is an integer, else false.

                this.TestType := "IsInteger"

                if IsInteger(pValue)
                    return this._test(1, true, psNote)
                else
                    return this._test(0, true, psNote) 
            }

            Case "IsFloat":
            {   ;Returns true if (pValue) is a real number, else false.

                this.TestType := "IsFloat"
                
                if IsFloat(pValue)
                    return this._test(1, true, psNote)
                else
                    return this._test(0, true, psNote)

            }

            Case "IsNumber":
            {   ;Returns true if (pValue) is an integer or a real number, else false.

                this.TestType := "IsNumber"
                
                if IsNumber(pValue)
                    return this._test(1, true, psNote)
                else
                    return this._test(0, true, psNote) 

            }

            Case "IsObject":
            {   ;Returns true if (pValue) is an object, else false.

                this.TestType := "IsObject"
                
                if IsObject(pValue)
                    return this._test(1, true, psNote)
                else
                    return this._test(0, true, psNote) 
            }
        
            Case "IsSet":
            {   ;Returns true if (pValue) has been assigned a value, else false.
                ;**Im not sure this works...by passing an unset var it seems to become 'set'?**

                this.TestType := "IsSet"
    
                if IsSet(pValue)
                    return this._test(1, true, psNote)
                else
                    return this._test(0, true, psNote) 
            }
        
            Case "IsDigit":
            {   ; Returns true if (pValue) is a positive integer, an empty string, or a string which 
                ; contains only the characters 0 through 9. 
                ;Other characters such as the following are not allowed: spaces, tabs, plus signs, 
                ;    minus signs, decimal points, hexadecimal digits, and the 0x prefix.

                this.TestType := "IsDigit"
                
                if IsDigit(pValue)
                    return this._test(1, true, psNote)
                else
                    return this._test(0, true, psNote) 
            }

            Case "IsAlpha":
            {   ; Returns true if (pValue) is a string and is empty or contains only alphabetic characters. 
                ; Returns False if there are any digits, spaces, tabs, punctuation, or other non-alphabetic 
                ;   characters anywhere in the string. For example, if pValue contains a space followed 
                ;   by a letter, it is not considered to be alpha.

                this.TestType := "IsAlpha"
                
                if IsAlpha(pValue)
                    return this._test(1, true, psNote)
                else
                    return this._test(0, true, psNote) 
            }
        
            Case "IsSpace":
            {   ; Returns true if (pValue) is a string and is empty or contains only whitespace consisting
                ; of the following characters: space (A_Space or `s), tab (A_Tab or `t), linefeed (`n), 
                ; return (`r), vertical tab (`v), and formfeed (`f).

                this.TestType := "IsSpace"
                
                if IsSpace(pValue)
                    return this._test(1, true, psNote)
                else
                    return this._test(0, true, psNote) 
            }
        }

        return
    }

	label(psTestLabel) 
    {   ;Labels the test for logs and readability.
        ;psTestLabel{string} - A human readable label for the next test(s) in sequence.

		if (A_IsCompiled)
			return 0

        this.TestLabel := psTestLabel

		return
	}

	BatchLabel(psGroupLabel) 
    {   ;Creates a free-text line in the output stream to add readability of the output.
        ;psGroupLabel{string} - A human readable label prepend for the next test(s) in sequence
        ;Note that once `psGroupLabel` is invoked, it remains in force until 'turned off' by 
        ;calling `expect.BatchLabel("")`.
        ;Any test results produced while `psGroupLabel` is active, is indented to create visual grouping.

		if (A_IsCompiled)
			return 0

        this.iCount := 1

        if (psGroupLabel)
        {
            this.GroupLabel := psGroupLabel
            this.GroupLabelActive := true
        }
        else
            this.GroupLabelActive := false

		return
	}

	ShortReport(iResetVars:=0) 
    {   ;Returns a string containing a 1-line summary of all the test results, something like:
        ;        "2 tests completed with 0% success (2 failures)"
        ;Write to stdout and to a msgbox.
    
		if (A_IsCompiled)
			return 0

		if (this.finalTrigger = false)
			this._finalWriteToStdOut()

		if (this.failTotal > 0)
			l_options := 48
        else
			l_options := 64

        OneLineSummary := this._build1LineSummaryOfTests()

		msgbox(OneLineSummary, "expect.ahk: 1-Line Summary", l_options)

        if (iResetVars = 1)
            this._ZeroiseClassVars()

        return OneLineSummary
	}

	FullReport(iResetVars:=0)
    {   ;Uses msgbox to display the 1-line summary for all tests together with details of any failures.
        ;Returns{string} with the generated full report message.

		if (A_IsCompiled)
			return 0

		if (this.finalTrigger = false)
			this._finalWriteToStdOut()

		msgReport := this._build1LineSummaryOfTests()

		if (this.failTotal > 0) 
        {   ;Add the logged values from the tests.
			loop this.log.Length
				msgReport .= "`n" this.log[A_Index]
		}

		; choose the msgbox icon
		if (this.failTotal > 0)
			l_options := 48
        else
			l_options := 64

		msgbox(msgReport, "expect.ahk: Details of Failed Tests", l_options)

        if (iResetVars = 1)
            this._ZeroiseClassVars()

		return msgReport
	}

	WriteResultsToFile(iResetVars:=0, psFilepath:=".\results.test.log") 
    {   ;Writes the report to a file.
        ;psFilepath - The path of the file where the report will be written. If not provided, the 
        ;   default logResultPath will be used.
        ;Throws and exception if there is an error writing the report to the disk.
        ;Returns a string containing the report that was written to the file.

		if (A_IsCompiled)
			return 0

        if (this.finalTrigger = false)
			this._finalWriteToStdOut()

		if (subStr(psFilepath, 1, 2) == ".\")
			psFilepath := A_WorkingDir subStr(psFilepath, 2)

		try
        {
			fileDelete(psFilepath)
        }
        catch
        {
			; do nothing
        }

		msgReport := this._build1LineSummaryOfTests() "`n"

        loop this.log.Length
			msgReport .= this.log[A_Index] "`n"            

        fileAppend(msgReport, psFilepath)

        if (iResetVars = 1)
            this._ZeroiseClassVars()

        if (A_LastError > 0)
        {
            Msgbox("Failed to write report to disk")
            ExitApp
        }

		return msgReport
	}

	_test(pActual:="_Missing_Parameter_", pExpected:="_Missing_Parameter_", psNote:="") 
    {   ;Checks if `pActual` and `pExpected` inputs are the same or equal (always case-sensitive).
        ;pActual{number|string|object} - The actual value computed.
        ;pExpected{number|string|object} - The expected value.
        ;psNote{string} - Additional notes for the test (Optional).
        ;Returns{boolean} true if the values are equal, else false.
        
		if (isObject(pActual))
			pActual := this._ConvObj2String(pActual)

		if (isObject(pExpected))
			pExpected := this._ConvObj2String(pExpected)

		; create
		this.testTotal++

        ;In the `If` block below have added 2 lots of `this.TestLabel := "". This fixes the following issue:
        ;If a label is defined before a test, and no label is defined before the next test, the
        ;1st label persists and appears in the output of the 2nd test (assuming it fails). 
        ;This is the last location in the class before returning to the caller script so is the right 
        ;place to re-blank `testLabel`.
        if (pActual == pExpected) 
        {
            this.successTotal++
            this.TestLabel := ""
            return true
        } 
        else 
        {
            this._logTestFail(pActual, pExpected, psNote)
            this.TestLabel := ""
            return false
        }
	}

    _logTestFail(pActual, pExpected, psNote:="") 
    {   
		this.failTotal++

        if (this.GroupLabelActive = true)
        {
            sIndents := "    "
            if (this.icount = 1)
            {
                sFailMessage .= this.GroupLabel "`n"
                this.iCount++
            }
        }
        else
        {
            sIndents := ""
            sFailMessage := ""
        }

        if (this.TestLabel = "")
            sFailMessage .= sIndents "Test label: n/d `n"
        else
            sFailMessage .= sIndents "Test label: " this.TestLabel "`n"

		sFailMessage .= sIndents "Test type : " this.TestType "`n"
		sFailMessage .= sIndents "Expected: " pExpected "`n"
		sFailMessage .= sIndents "Actual: " pActual "`n"
        
        if (psNote != "")
            sFailMessage .= sIndents "Note: " psNote "`n"
        
		this._stdOut(sFailMessage "`n") ;unsure why, but `n needed to put blank between tests logged to DebugConsole.
		this.log.push(sFailMessage)

        return
	}

    _stdOut(output:="") 
    {   ;Writes 'rolling' as-you-go test-fail messages to the Debug Console.

        try
            FileAppend(output, "*") ;'asterisk' writes to stdout.
        catch error
			return false

		return true
	}

    _finalWriteToStdOut() 
    {   ;Called by ShortReport(), FullReport() and WriteResultsToFile() if this.finalTrigger is false
        ;to write the 1-line test summary report to stdOut.

        this._stdOut(this._build1LineSummaryOfTests())
		this.finalTrigger := true

		return true
	}

    _build1LineSummaryOfTests() 
    {   ;Generates a 1-line summary of all tests to date, ie something like 
        ;   "2 tests completed with 0% success (2 failures)"

		this.percentsuccess := floor( ( this.successTotal / this.testTotal ) * 100 )
		sReturnText := this.testTotal " tests completed with " this.percentsuccess "% success (" this.failTotal " failures)`n"

		if (this.failTotal = 1)
			sReturnText := strReplace(sReturnText, "failures", "failure")

		if (this.testTotal = 1)
			sReturnText := strReplace(sReturnText, "tests", "test")

        ;Add underlining to the summary line.
		sReturnText .= "=================================`n"

		return sReturnText
	}

    _ConvObj2String(pValue) 
    {   ;It seems this converts an object into a string called <output>. 
        ;If the param is not an object, the unchanged param is returned.
        ;I renamed this method as _ConvObj2String from _print()to better reflect its purpose.

		if (isObject(pValue)) 
        {
			for key, value in pValue 
            {
				if IsNumber(key)
					output .= "`"" . key . "`":"
                else
					output .= key . ":"

				if IsObject(value)
					output .= "[" . this._ConvObj2String(value) . "]"
                else if(IsObject(value))
					output .= "`"" . value . "`""
				else
					output .= value

				output .= ", "
			}

			return subStr(output, 2)
		}

		return pValue
	}
}