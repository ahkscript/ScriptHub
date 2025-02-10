; Source: https://www.autohotkey.com/boards/viewtopic.php?f=83&t=135206
; Author: rockitdontstopit

class ImageActions {
    
    ; Click operations =========================================================================================================================================
    
    static Click(text) {
        return this.New(text).Wait('wait1', -1).Click()    ; waits indefinitely for image to appear then clicks it
    }

    static ClickNoWait(text) {
        return this.New(text).Wait(0, 0).Click()
    }

    static ClickRegion(text, x1, y1, x2, y2) {
        return this.New(text).Wait('wait1', -1).Region(x1, y1, x2, y2).Click()
    }
    
    static ClickRegionOffset(text, x1, y1, x2, y2, xOff, yOff) {
        return this.New(text).Wait('wait1', -1).Region(x1, y1, x2, y2).Offset(xOff, yOff).Click()
    }

    static ClickOffset(text, xOff, yOff) {
        return this.New(text).Wait('wait1', -1).Offset(xOff, yOff).Click()
    }

    static ClickVar(text) {
        return this.New(text).Variation().Click()
    }
    
    static ClickTimeout(text, seconds) {
        return this.New(text).Timeout(seconds).Click()
    }

    static ClickSleep(text, preSleep, postSleep) {
        return this.New(text).Sleep(preSleep, postSleep).Click()
    }

    static ClickInstance(text, instanceNumber) {
        return this.New(text).Wait('wait1', -1).ClickInstance(instanceNumber)
        
    }

    static ClickInstanceLoop(text, instanceNumber) {
        return this.New(text).Wait('wait1', -1).ClickInstanceLoop(instanceNumber)
        
    }

    static ClickInstanceTimeout(text, seconds, instanceNumber) {
        return this.New(text).Timeout(seconds).ClickInstance(instanceNumber)
        
    }

    static ClickInstanceVar(text, instanceNumber) {
        return this.New(text).Variation().ClickInstance(instanceNumber)
    }

    static ClickAllInstances(text) {
        return this.New(text).ClickAllInstances()
    }
    
    static ClickMulti(text, timesToClick) {
        return this.New(text).ClickMulti(timesToClick)
    }

    static ClickWebsite(text) {
        return this.New(text).Wait('wait1', -1).Variation().Sleep(400, 300).Click()
    }

    static ClickRegionTimeout(text, x1, y1, x2, y2, seconds) {
        return this.New(text).Region(x1, y1, x2, y2).Timeout(seconds).Click()
    }

    static ClickRegionWait(text, x1, y1, x2, y2) {
        return this.New(text).Wait("wait1", -1).Region(x1, y1, x2, y2).Click()
    }
    
    static ClickVarTimeout(text, seconds) {
        return this.New(text).Variation().Timeout(seconds).Click()
    }

    static ClickVarSleep(text, preSleep, postSleep) {
        return this.New(text).Variation().Sleep(preSleep, postSleep).Click()
    }

    static ClickInstanceRegion(text, instanceNumber, x1, y1, x2, y2) {
        return this.New(text).Region(x1, y1, x2, y2).ClickInstance(instanceNumber)
    }

    static ClickBottomToTop(text) {
        return this.New(text).Wait("wait1", -1).BottomToTop().Click()
    }

    static DoubleClick(text) {
        return this.New(text).Wait('wait1', -1).DoubleClick()
    }

    static DoubleClickOffset(text, xOff, yOff) {
        return this.New(text).Wait('wait1', -1).Offset(xOff, yOff).DoubleClick()
    }

    static DoubleClickRegionOffset(text, x1, y1, x2, y2, xOff, yOff) {
        return this.New(text).Wait('wait1', -1).Region(x1, y1, x2, y2).Offset(xOff, yOff).DoubleClick()
    }

    static DoubleClickOffsetVar(text, xOff, yOff) {
        return this.New(text).Offset(xOff, yOff).Variation().DoubleClick()
    }

    static RightClick(text) {
        return this.New(text).Wait('wait1', -1).RightClick()
    }

    static RightClickRegion(text, x1, y1, x2, y2) {
        return this.New(text).Wait('wait1', -1).Region(x1, y1, x2, y2).RightClick()
    }

    ; Find operations =========================================================================================================================================
    
    static FindAllCoordinates(text) {
        return this.New(text).GetAllCoordinates()
    }

    static Found(text, &X:="", &Y:="") {
        return this.New(text).Find(&X, &Y)
    }
    
    static FoundRegion(text,x1, y1, x2, y2) {
        return this.New(text).Region(x1, y1, x2, y2).Find()
    }

    static FoundTimeout(text, seconds) {
        return this.New(text).Timeout(seconds).Find()
    }

    static FoundVar(text, &X:="", &Y:="") {
        return this.New(text).Wait("wait", .2).Variation().Find()
    }

    static NotFound(text) {
        return this.New(text).Wait("wait0", 0).Find()
    }
    
    static WaitTilFound(text, &X:="", &Y:="") {
        return this.New(text).Wait("wait1", -1).Find(&X, &Y)
    }

    static WaitTilFoundRegion(text, x1, y1, x2, y2) {
        return this.New(text).Wait("wait1", -1).Region(x1, y1, x2, y2).Find()
    }

    static WaitTilFoundVar(text) {
        return this.New(text).Wait("wait1", -1).Variation().Find()
    }

    static WaitTilNotFound(text) {
        return this.New(text).Wait("wait0", -1).Find()
    }

    static WaitTilNotFoundRegion(text, x1, y1, x2, y2) {
        return this.New(text).Wait("wait0", -1).Region(x1, y1, x2, y2).Find()
    }

    static FindClickRight(firstImage, secondImage, verticalRange) {
        return this.New(firstImage).FindClickRight(secondImage, verticalRange)
    }

    ; Move operations =========================================================================================================================================

    static Move(text) {
        return this.New(text).Wait("wait1", -1).Move()
    }

    ;**********************************************************************************************************************************************************************************************************

    class ImageAction {
        __New(text) {
            this.waitType := 0
            this.waitTime := 0
            this.x1 := 0
            this.y1 := 0
            this.x2 := A_ScreenWidth
            this.y2 := A_ScreenHeight
            this.var := 0
            this.text := text
            this.findAll := 0
            this.direction := 1
            this.xOff := 0
            this.yOff := 0
            this.preSleep := 0
            this.postSleep := 0
            this.clickCount := 1
        }

        ; Chainable Configuration Methods ---------------------------------------------------------
   
        Wait(type, time) {
            this.waitType := type
            this.waitTime := time
            return this
        }

        Timeout(seconds) {
            this.waitType := "wait"
            this.waitTime := seconds
            return this
        }
 
        Region(x1, y1, x2, y2) {
            this.x1 := x1
            this.y1 := y1
            this.x2 := x2
            this.y2 := y2
            return this
        }

        Variation() {
            this.var := .1
            return this
        } 

        BottomToTop() {
            this.direction := 6
            return this
        }
    
        Offset(xOff, yOff) {
            this.xOff := xOff
            this.yOff := yOff
            return this
        }

        Sleep(preSleep, postSleep) {
            this.preSleep := preSleep
            this.postSleep := postSleep
            return this
        }

        ; Core Action Methods ---------------------------------------------------------

        Click() {
            if FindText(&X := this.waitType, &Y := this.waitTime, this.x1, this.y1, this.x2, this.y2, this.var, this.var, this.text,, this.findAll,,,, this.direction,,) {
                Sleep(this.preSleep)
                FindText().Click(X + this.xOff, Y + this.yOff, "L", this.clickCount)
                Sleep(this.postSleep)
                return true
            }
            return false
        }
        
        RightClick() {
            if FindText(&X := this.waitType, &Y := this.waitTime, this.x1, this.y1, this.x2, this.y2, this.var, this.var, this.text,, this.findAll,,,, this.direction,,) {
                FindText().Click(X + this.xOff, Y + this.yOff, "R")
                return true
            }
            return false
        }

        DoubleClick() {
            this.clickCount := 2
            return this.Click()
        }
    
        ClickInstance(instanceNumber) {
                instances := FindText(&X := this.waitType, &Y := this.waitTime, this.x1, this.y1, this.x2, this.y2, this.var, this.var, this.text,,,,,, this.direction,,)
                if (instances AND instances.Length >= instanceNumber) {
                    Instance := instances[instanceNumber]
                    FindText().Click(Instance.x, Instance.y, "L")
                    return true
                }
        }

        ClickInstanceLoop(instanceNumber) {
            loop {
                instances := FindText(&X := this.waitType, &Y := this.waitTime, this.x1, this.y1, this.x2, this.y2, this.var, this.var, this.text,,,,,, this.direction,,)
                if (instances AND instances.Length >= instanceNumber) {
                    Instance := instances[instanceNumber]
                    FindText().Click(Instance.x, Instance.y, "L")
                    return true
                }
            }
        }
        
        ClickAllInstances(minMatches := 0) {
            instances := FindText(&X := this.waitType, &Y := this.waitTime, this.x1, this.y1, this.x2, this.y2, this.var, this.var, this.text,,,,,, this.direction,,)
            if (instances AND instances.Length >= minMatches) {
                for index, result in instances {
                    x := result.x
                    y := result.y
                    FindText().Click(x, y, "L")
                }
                return true
            }
            return false
        }
        
        ClickMulti(timesToClick) {
            this.clickCount := timesToClick
            return this.Click()
        }

        GetAllCoordinates() {
            coordinates := []
            instances := FindText(&X := 'wait1', &Y := -1, this.x1, this.y1, this.x2, this.y2, this.var, this.var, this.text,,,,,, this.direction,,)
            
            if (instances) {
                for index, result in instances {
                    coordinates.Push({ x: result.x, y: result.y })
                }
            }
            
            return coordinates
        }

        Find(&X := "", &Y := "") {
            return FindText(&X := this.waitType, &Y := this.waitTime, this.x1, this.y1, this.x2, this.y2, this.var, this.var, this.text,, this.findAll,,,, this.direction,,)
        }

        FindClickRight(secondImage, verticalRange) {
            if (ok := FindText(&X := "wait1", &Y := -1, this.x1, this.y1, this.x2, this.y2, .1, .1, this.text)) {
                firstX := ok[1].x
                firstY := ok[1].y
                MouseMove(firstX, firstY)
                if (ok2 := FindText(&X := "wait1", &Y := -1, firstX, firstY - verticalRange, A_ScreenWidth, firstY + verticalRange, .1, .1, secondImage)) {
                    Sleep(this.preSleep)
                    FindText().Click(ok2[1].x, ok2[1].y, "L", this.clickCount)
                    Sleep(this.postSleep)
                    return true
                }
            }
            return false
        }
            
        Move() {
            if this.Find(&X, &Y) {
                MouseMove(X, Y)
                return true
            }
            return false
        }
    }

    static New(text) {
        return ImageActions.ImageAction(text)
    }
}