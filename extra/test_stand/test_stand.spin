{{
--------------------------------------------------------------------------------
Anzhelka Project
(c) 2012

For the latest code and support, please visit:
http://code.anzhelka.com
--------------------------------------------------------------------------------

Title: Test Stand
Author: Cody Lewis (SRLM)
Date: 3-24-2012
Notes: This software automatically runs the test stand.



}}
CON
	_clkmode = xtal1 + pll16x
	_xinfreq = 5_000_000

CON
'IO Pins
	DEBUG_TX_PIN  = 30
	DEBUG_RX_PIN  = 31
	
	ADC_D_PIN = 11
	ADC_S_PIN = 10
	ADC_C_PIN = 12
	
	KEYPAD_LOW_PIN  = 0
	KEYPAD_HIGH_PIN = 7
	
	ESC_PIN = 13 'turns on at ~1600 us
	
	RPM_PIN = 8 'Note: currently not used in code (a pin mask is used instead)
	
'Settings

VAR


OBJ
	debug : "FullDuplexSerialPlus.spin"
	adc : "MCP3208_fast.spin"
	pwm : "PWM_32_v4.spin"
	rpm : "Eagle_Tree_Brushless_RPM.spin"
	keypad : "Matrix_Membrane_Keypad.spin"

PUB Main | i, pwmoutput

	debug.start(DEBUG_RX_PIN, DEBUG_TX_PIN, 0, 115200)
	adc.start(ADC_D_PIN, ADC_C_PIN, ADC_S_PIN, 0)
	pwm.start
	rpm.setpins(%0001_0000_0000) 'RPM_PIN
	rpm.start
	keypad.init(KEYPAD_LOW_PIN, KEYPAD_HIGH_PIN)
	
	
	waitcnt(clkfreq + cnt)
	
	
	
	debug.str(string("Starting..."))
	DebugNewline

	pwm.servo(ESC_PIN, 1000)
	repeat i from 10 to 0
		debug.str(string("t minus "))
		debug.dec(i)
		DebugNewline
		waitcnt(clkfreq + cnt)
	'repeat
	
'	dira[14] := 1
'	outa[14] := 1
	
'	repeat
	
'	debug.str(string("Type in PWM values (in uS) to send to ESC"))
'	DebugNewline
'	debug.str(string("Press * to submit number"))
'	DebugNewline
'	debug.str(string("Press # to clear number"))
'	DebugNewline



'	repeat
''		CheckMotor
'		i := keypad.GetNumber
'		DebugNewline
'		if i == -1
'			debug.str(string("No number"))
'		else
'			debug.str(string("Sending to ESC: "))
'			debug.dec( i )
'			debug.str(string("uS"))
'			DebugNewLine
'			pwm.servo(ESC_PIN, i)
'		
'		debug.str(string("Calculated RPM:"))
'		debug.dec(rpm.getrpm(0))
'		DebugNewline
'		DebugNewline
'			
'	
	
'	
'	repeat
'		debug.str(string("Speed LOW"))
'		DebugNewline
'		pwm.servo(ESC_PIN, 1650)
'		waitcnt(clkfreq*3 + cnt)
'		
'		debug.str(string("Speed HIGH"))
'		DebugNewline
'		pwm.servo(ESC_PIN, 1900)
'		waitcnt(clkfreq*3 + cnt)
'		
	
	repeat
		repeat i from 0 to 1000 step 10
			pwmoutput := i + 1000
			debug.str(string("PWM= "))
			debug.dec(pwmoutput)
			pwm.servo(ESC_PIN, pwmoutput)

			waitcnt(clkfreq + cnt)
			

			debug.str(string(9,9,"RPM= "))
			debug.dec(rpm.getrpm(0))
			DebugNewline
			
			
			
		repeat i from 1000 to 0 step 10
			pwmoutput := i + 1000
			debug.str(string("PWM= "))
			debug.dec(pwmoutput)
			pwm.servo(ESC_PIN, pwmoutput)
			
			waitcnt(clkfreq + cnt)
			
			debug.str(string(9,9,"RPM= "))
			debug.dec(rpm.getrpm(0))
			DebugNewline
			
'			waitcnt(clkfreq/4 + cnt)
			
			
'	
'	repeat
'		debug.str(string("Keypad: "))
'		debug.dec(ReadKeyPad)
'		DebugNewline
'		debug.str(string("ADC(0): "))
'		debug.dec(adc.in(0))
'		debugNewline
'		debug.str(string("ADC(1): "))
'		debug.dec(adc.in(1))
'		DebugNewline

'		waitcnt(clkfreq + cnt)
'		
'		
PUB CheckMotor
	if rpm.getpins(0) == 0
		pwm.servo(ESC_PIN, 1500)
	
PUB DebugNewline
	debug.tx(10)
	debug.tx(13)
	

	
{{
--------------------------------------------------------------------------------  
Copyright (c) 2012 Cody Lewis and Luke De Ruyter

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions: 

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software. 

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--------------------------------------------------------------------------------
}}
