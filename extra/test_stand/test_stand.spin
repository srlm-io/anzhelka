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
	
	ESC_PIN = 20 'turns on at ~1600 us
	
	RPM_PIN = 8 'Note: currently not used in code (a pin mask is used instead)
	
'Settings
	NUM_MOT = 4
	
	'Port names for Full Duplex Serial 4 port Plus
	PDEBUG = 0 'Debug port
	
	'Motor PID loop types of errors:
	CURRENT = 0
	ACCUMULATOR = 1
	PREVIOUS = 2
	DELTA = 3
	
	
'ADC Channel Names
	ADC_THRUST = 1
	ADC_TORQUE = 0
	

VAR
	long motorkp[NUM_MOT]
	long motorki[NUM_MOT]
	long motorkd[NUM_MOT]
	long motorrps[NUM_MOT]
	long motorvolt[NUM_MOT]
	long motoramp[NUM_MOT]
	long motorpwm[NUM_MOT]
	long motorthrust[NUM_MOT]
	long motortorque[NUM_MOT]
	long motordesiredrps[NUM_MOT]
	long motorerror[NUM_MOT * 4] 


OBJ
'	debug : "FullDuplexSerialPlus.spin"
	debug 	:	"FullDuplexSerial4portPlus_0v3.spin"
	adc 	:	"MCP3208_fast.spin"
	pwm 	:	"PWM_32_v4.spin"
	rpm 	:	"Eagle_Tree_Brushless_RPM.spin"
	keypad 	:	"Matrix_Membrane_Keypad.spin"
	

PUB Main | i, pwmoutput


	init_uarts
	adc.start(ADC_D_PIN, ADC_C_PIN, ADC_S_PIN, 0)
	pwm.start
	rpm.setpins(%0001_0000_0000) 'RPM_PIN
	rpm.start
	keypad.init(KEYPAD_LOW_PIN, KEYPAD_HIGH_PIN)
		
	waitcnt(clkfreq + cnt)
	
	pwm.servo(ESC_PIN, 1000)
	debug.str(PDEBUG, string("$ADSTR 'Starting...'"))
	DebugNewline


	repeat i from 10 to 0
		debug.str(PDEBUG, string("$ADSTR 't minus "))
		debug.dec(PDEBUG, i)
		debug.tx(PDEBUG, "'")
		DebugNewline
		waitcnt(clkfreq + cnt)

	'RPM
	'PWM
	'Volts
	'Current
	'Force
	'
	
	

	repeat
		repeat i from 0 to 1000 step 1
			loop(i)
			
		repeat 'Delay at top
			loop(1000)
			
		repeat i from 1000 to 0 step 1
			loop(i)

PUB loop(i)
	motorpwm[0] := i + 1000
	printMotorList(string("$ADPWM"), @motorpwm)

	

	pwm.servo(ESC_PIN, motorpwm[0])
	repeat 1 'Number of seconds
		repeat 2 'Number of rps readings per second
			motorrps[0] := rpm.getrps(0)
			readForce

			printMotorList(string("$ADRPS"), @motorrps)
			printMotorList(string("$ADMTH"), @motorthrust)
			printMotorList(string("$ADMTQ"), @motortorque)

PUB readForce | thrust, torque
	torque := ADC.average(ADC_TORQUE, 4)
	thrust := ADC.average(ADC_THRUST, 4)
	
	motorthrust[0] := thrust
	motortorque[0] := torque

	
PUB motorPID(motor) | rps, drps, p, i, d, drive
'Returns the PWM value to send to the motor
'Motor is in the range of 0 - (NUM_MOT -1), and is used to index the following hub variables:
'	long motorkp[NUM_MOT]
'	long motorki[NUM_MOT]
'	long motorkd[NUM_MOT]
'	long motorrps[NUM_MOT]
'	long motorvolt[NUM_MOT]
'	long motoramp[NUM_MOT]
'	long motorpwm[NUM_MOT]
'	long motorthrust[NUM_MOT]
'	long motortorque[NUM_MOT]
'	long motordesiredrps[NUM_MOT]
'	long motorerror[NUM_MOT][4]

' Based in large part on this thread:
'	http://forums.parallax.com/showthread.php?77656-PID-Control-Intro-with-the-BASIC-Stamp

	rps := motorrps[motor]
	drps:= motordesiredrps[motor]
 
	motorerror[motor * CURRENT] := drps - rps
	p := motorkp[motor] * motorerror[motor * CURRENT]
	
	'The 2000 is arbitrary for now...
	motorerror[motor * ACCUMULATOR] := -2000 #> (motorerror[motor * ACCUMULATOR]  + motorerror[motor * CURRENT]) #> 2000
	i := motorki[motor] * motorerror[motor * ACCUMULATOR] 
	
	motorerror[motor * DELTA] := motorerror[motor * current] - motorerror[motor * PREVIOUS] 
	d := motorkd[motor] * motorerror[motor * DELTA]
	motorerror[motor * PREVIOUS] := motorerror[motor * CURRENT]
	
	drive := p + i + d + 1000 'PID + base
	drive := 1000 <# drive #> 2000 'Limit to valid PWM range
	return drive
	


	
PUB printMotorList(name_str_addr, variable_addr) | i
'' This function is a generic function to print $AD strings where each data element is a motor value, eg
'' $ADRPS rps[0], rps[1], rps[2], ..., rps[7]   <--- For an octorotor

	debug.str(0, name_str_addr)
	debug.tx(0, " ")
	if NUM_MOT > 0
		debug.dec(0, long[variable_addr][0])
	if NUM_MOT > 1
		repeat i from 1 to (NUM_MOT - 1)
			debug.tx(0, ",")
			debug.dec(0, long[variable_addr][i])
	debug.tx(0, 10)
	debug.tx(0, 13)	
	

PUB init_uarts | extra
	extra := debug.init
	
	debug.AddPort(0, 31, 30, -1, -1, 0, 0, 115200)
	
	debug.Start
	
	waitcnt(clkfreq + cnt)
	
	debug.str(0, string("Starting..."))
	debug.tx(0, 10)
	debug.tx(0, 13)
	
PUB DebugNewline
	debug.tx(0, 10)
	debug.tx(0, 13)
	



''Extra code that was useful at one time or another:
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
