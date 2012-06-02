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
	
'	KEYPAD_LOW_PIN  = 0
'	KEYPAD_HIGH_PIN = 7
	
	ESC_PIN = 15 'turns on at ~1600 us
	
	RPM_PIN = 8 'Note: currently not used in code (a pin mask is used instead)
	
'Settings
	NUM_MOT = 4
	

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

	adc 	:	"MCP3208_fast.spin"
	pwm 	:	"PWM_32_v4.spin"
	rpm 	:	"Eagle_Tree_Brushless_RPM.spin"
'	keypad 	:	"Matrix_Membrane_Keypad.spin"
	

PUB Main | i, pwmoutput


	InitFunctions

	
	
	motordesiredrps[0] := float(0)
	motorrps[0] := float(0)'fp.FFloat(rpm.getrps(0))
	PID_n_1.setInput_addr(@n_1) 'Warning: it's @motorrpm[0]
	PID_n_1.setOutput_addr(@pid_output)
	PID_n_1.setSetpoint_addr(@n_d_1) 'Warning: it's @motordesiredrps[0]
	PID_n_1.setOutmin(fp.FSub(float(0), float(300)))
	PID_n_1.setOutmax(float(300))
	PID_n_1.setKpid(fp.FDiv(float(1), float(10)), float(0), float(0))
	PID_n_1.init
	
	adc.start(ADC_D_PIN, ADC_C_PIN, ADC_S_PIN, 0)
	pwm.start
	rpm.setpins(%0001_0000_0000) 'RPM_PIN
	rpm.start
	
	pwm.servo(ESC_PIN, 1000)

	repeat i from 0 to 0
		waitcnt(clkfreq + cnt)
		serial.str(string("$ADSTR "))
		serial.dec(phsb)
		serial.str(string(",'t minus "))
		serial.dec(i)
		serial.tx("'")
		serial.tx(10)
		serial.tx(13)
		

	
	pwm.servo(ESC_PIN, 1200)
	waitcnt(clkfreq * 1 + cnt)
		
	
	i := 90
	u_1 := float(1200)
	n_d_1 := fp.FFloat(i)
	repeat
		serial.str(string(10, 13, "pid_output: "))
		FPrint(pid_output)
		repeat 100
	'		serial.str(string(10, 13, "->ITerm: "))
	'		FPrint(PID_n_1.getITerm)
	'		serial.str(string(" $"))
	'		serial.hex(PID_n_1.getITerm, 8)
	'		serial.str(string(10, 13, "->LastInput: "))
	'		FPrint(PID_n_1.getLastInput)
	'		serial.str(string(10, 13))
			loop(i)
			ParseSerial
			waitcnt(clkfreq/50 + cnt)


PUB loop(i)
	
	

	n_1 := fp.FFloat( 0 #> rpm.getrps(0) <# 250) 'Min < rps < Max
'	pid_output := fp.FMul(PID_n_1.getKp, fp.FSub(n_d_1, n_1))

	fp.FPID(PID_n_1.getBase)
	u_1 := fp.FAdd(u_1, pid_output)
	u_1 := fp.FLimitMin(u_1, float(1000))
	u_1 := fp.FLimitMax(u_1, float(1600))

	pwm.servo(ESC_PIN, fp.FTrunc(u_1))


PUB readForce | thrust, torque
	torque := ADC.average(ADC_TORQUE, 4)
	thrust := ADC.average(ADC_THRUST, 4)
	
	motorthrust[0] := thrust
	motortorque[0] := torque



	
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
