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

'IO Pins
	DEBUG_TX_PIN  = 30
	DEBUG_RX_PIN  = 31
	
	CLOCK_PIN = 23 'Unconnected to anything else
	
	
	ADC_D_PIN = 11
	ADC_S_PIN = 10
	ADC_C_PIN = 12
	
	KEYPAD_LOW_PIN  = 0
	KEYPAD_HIGH_PIN = 7
	
	ESC_PIN = 15 'turns on at ~1600 us
	
	RPM_PIN = 8 'Note: currently not used in code (a pin mask is used instead)
	
'Settings
	NUM_MOT = 4
	
	SERIAL_BAUD = 115200
	
	'Port names for Full Duplex Serial 4 port Plus
'	PDEBUG = 0 'Debug port
	
	FREQ_VALUE = $0001_0000
	FREQ_COUNTS = 65536 '2^n, where n is the number of freq1's needed before overflow
	
	
	'Motor PID loop types of errors:
	CURRENT = 0
	ACCUMULATOR = 1
	PREVIOUS = 2
	DELTA = 3
	
	
'ADC Channel Names
	ADC_THRUST = 1
	ADC_TORQUE = 0
	

VAR
	long motorrps[NUM_MOT]
	long motorvolt[NUM_MOT]
	long motoramp[NUM_MOT]
	long motorpwm[NUM_MOT]
	long motorthrust[NUM_MOT]
	long motortorque[NUM_MOT]
	long motordesiredrps[NUM_MOT]

	long pid_output

OBJ
'	debug : "FullDuplexSerialPlus.spin"
	serial	:   "FastFullDuplexSerialPlusBuffer.spin"
	adc 	:	"MCP3208_fast.spin"
	pwm 	:	"PWM_32_v4.spin"
	rpm 	:	"Eagle_Tree_Brushless_RPM.spin"
	keypad 	:	"Matrix_Membrane_Keypad.spin"
	
	fp		:	"F32_CMD.spin"
	pid_data:	"PID_data.spin"

PUB Main | i, pwmoutput


	InitClock
	InitUart
	fp.start
	
	motordesiredrps[0] := float(0)
	motorrps[0] := fp.FFloat(rpm.getrps(0))
	pid_data.setInput_addr(@motorrps) 'Warning: it's @motorrpm[0]
	pid_data.setOutput_addr(@pid_output)
	pid_data.setSetpoint_addr(@motordesiredrps) 'Warning: it's @motordesiredrps[0]
	pid_data.setOutmin(float(10))
	pid_data.setOutmax(float(1000))
	pid_data.setKpid(float(5), float(0), float(0))
	pid_data.init
	
	adc.start(ADC_D_PIN, ADC_C_PIN, ADC_S_PIN, 0)
	pwm.start
	rpm.setpins(%0001_0000_0000) 'RPM_PIN
	rpm.start
	keypad.init(KEYPAD_LOW_PIN, KEYPAD_HIGH_PIN)
	
	
	
		
	waitcnt(clkfreq + cnt)
	
	pwm.servo(ESC_PIN, 1000)


'	i := fp.FFloat(-910)
'	serial.str(fp.FloatToString(i))
'	serial.tx(" ")
'	serial.tx("$")
'	serial.hex(i, 8)
'	serial.str(string(10,13))
'	
'	i := float(0)
'	serial.str(fp.FloatToString(i))
'	serial.tx(" ")
'	serial.tx("$")
'	serial.hex(i, 8)
'	serial.str(string(10,13))

'	i := float(345)
'	serial.str(fp.FloatToString(i))
'	serial.tx(" ")
'	serial.tx("$")
'	serial.hex(i, 8)
'	serial.str(string(10,13))


	repeat i from 3 to 0
		serial.str(string("$ADSTR "))
		serial.dec(phsb)
		serial.str(string(",'t minus "))
		serial.dec(i)
		serial.tx("'")
		serial.tx(10)
		serial.tx(13)
		waitcnt(clkfreq + cnt)
	
	
'	repeat
'		repeat i from 0 to 1000
'			pwm.servo(ESC_PIN, 1000 + i)
'			waitcnt(clkfreq/100 + cnt)
'			serial.dec(1000 + i)
'			serial.tx(",")
'			serial.dec(rpm.getrps(0))
'			serial.tx(10)
'			serial.tx(13)
'		repeat i from 1000 to 0
'			pwm.servo(ESC_PIN, 1000 + i)
'			waitcnt(clkfreq/100 + cnt)
'			serial.dec(1000 + i)
'			serial.tx(",")
'			serial.dec(rpm.getrps(0))
'			serial.tx(10)
'			serial.tx(13)
	
	
	pwm.servo(ESC_PIN, 1200)
	waitcnt(clkfreq * 1 + cnt)
		
	
	i := 90
	repeat
		serial.str(string(10, 13, "->ITerm: "))
		FPrint(pid_data.getITerm)
		serial.str(string(" $"))
		serial.hex(pid_data.getITerm, 8)
		serial.str(string(10, 13, "->LastInput: "))
		FPrint(pid_data.getLastInput)
		serial.str(string(10, 13))
		loop(i)
	
	'Note: i is in rps!!!
	repeat
		repeat i from 20 to 45 step 1
			loop(i)
			
'---------------------

'	repeat
'		repeat i from 0 to 1000 step 1
'			loop(i)
'			
'		repeat 500'Delay at top
'			loop(1000)
'			
'		repeat i from 1000 to 0 step 1
'			loop(i)
'		
'		repeat 5	
'			repeat i from 0 to 1000 step 10
'				loop(i)
'			
'			repeat 20'Delay at top
'				loop(1000)
'			
'			repeat i from 1000 to 0 step 10
'				loop(i)
'				
'		repeat 5	
'			repeat i from 0 to 1000 step 30
'				loop(i)
'			
'			repeat 20'Delay at top
'				loop(1000)
'			
'			repeat i from 1000 to 0 step 30
'				loop(i)
'			
'			repeat 10
'				loop(0)
'		
		
		

PUB loop(i)
	motordesiredrps[0] := fp.FFloat(i)
	
	repeat 1 'Number of seconds
		repeat 1
'			readForce


			motorrps[0] := fp.FFloat( 0 #> rpm.getrps(0) <# 250) 'Min < rps < Max
			fp.FPID(PID_data.getBase)
			'pid_output is 0 to 1000
'			scale it in range of 0 to 1600
			pid_output := float(1000)

			pid_output := fp.FMul(pid_output, fp.FDiv(float(600), float(1000)))
			motorpwm[0] := fp.FTrunc(pid_output) + 1000
			PrintArray(string("PWM"), @motorpwm, 4, TYPE_INT)
'			waitcnt(clkfreq/20 + cnt)
			PrintArray(string("RPS"), @motorrps, 4, TYPE_FLOAT)
'			waitcnt(clkfreq/20 + cnt)
			pwm.servo(ESC_PIN, motorpwm[0])
			
'			waitcnt(clkfreq/5 + cnt)
'			PrintArray(string("$ADMTH"), @motorthrust, 4, TYPE_INT)
'			PrintArray(string("$ADMTQ"), @motortorque, 4, TYPE_INT)

PUB readForce | thrust, torque
	torque := ADC.average(ADC_TORQUE, 4)
	thrust := ADC.average(ADC_THRUST, 4)
	
	motorthrust[0] := thrust
	motortorque[0] := torque

	



	
'-------------------------------------------------------------------
'-------------------------------------------------------------------
'----------------- $ATXXX Output Functions -------------------------
'-------------------------------------------------------------------
'-------------------------------------------------------------------

	
CON
	TYPE_INT = 0
	TYPE_FLOAT = 1
PUB PrintArray(type_string_addr, array_addr, length, type) | i
'' Parameters:
''  - type_string_addr: a string that has the three capital letters that 
''      denote which type of data this packet is, eg PWM or MKP
''  - array_addr: the values to send. A long array only.
''  - length: the length of the array.


	serial.str(string("$AD"))
	serial.str(type_string_addr)
	serial.tx(" ")
	serial.dec(phsb)

	repeat i from 0 to length - 1
		serial.tx(",")
		if type == TYPE_INT
			serial.dec(long[array_addr][i])
		elseif type == TYPE_FLOAT
			FPrint(long[array_addr][i])
		else
			serial.tx("?") 'Warning!
		
	serial.tx(10)
	serial.tx(13)
		
		
PUB PrintSTR(addr)
	serial.str(string("$ADSTR "))
	serial.dec(phsb)
	serial.tx(",")
	serial.tx("'")
	serial.str(addr)
	serial.str(string("'", 10, 13))

'-------------------------------------------------------------------
'-------------------------------------------------------------------
'----------------- Support Functions -------------------------------
'-------------------------------------------------------------------
'-------------------------------------------------------------------
PRI FPrint(fnumA)
''Will print a floating point number up to 3 decimal places (without rounding)
'	if fnumA == $7FFF_FFFF
'		serial.str(string("QNaN"))
'		return
''	if fp.FCmp(fnumA, float(0)) == -1 'less than 0...
'	if fnumA & $8000_0000 'If sign bit is set
'		serial.tx("-")
'	serial.dec(fp.FAbs(fp.FTrunc(fnumA)))
'	serial.tx(".")
'	serial.dec(fp.FTrunc(fp.FMul(fp.Frac(fnumA), float(1000) )))

	serial.str(fp.FloatToString(fnumA))

'-------------------------------------------------------------------
'-------------------------------------------------------------------
'----------------- Init Functions ----------------------------------
'-------------------------------------------------------------------
'-------------------------------------------------------------------
	
PUB InitUart | extra
	serial.start(DEBUG_RX_PIN, DEBUG_TX_PIN, 0, SERIAL_BAUD)	
	waitcnt(clkfreq + cnt)
	PrintStr(string("Starting..."))
	
PUB InitClock
' sets pin as output
	DIRA[CLOCK_PIN]~~
	CTRa := %00100<<26 + CLOCK_PIN           ' set oscillation mode on pin
	FRQa := FREQ_VALUE                    ' set FRequency of first counter                   

	CTRB := %01010<<26 + CLOCK_PIN           ' at every zero crossing add 1 to phsb
	FRQB := 1

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
