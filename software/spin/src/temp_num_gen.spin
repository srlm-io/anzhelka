{{
--------------------------------------------------------------------------------
Anzhelka Project
(c) 2012

For the latest code and support, please visit:
http://code.anzhelka.com
--------------------------------------------------------------------------------

Title:
Author:
Date:
Notes:



}}
CON
	_clkmode = xtal1 + pll16x
	_xinfreq = 5_000_000

CON
'IO Pins
	DEBUG_TX_PIN  = 30
	DEBUG_RX_PIN  = 31
'Settings
	NUM_MOT = 4

VAR
'	long pid[NUM_MOT*3] 'P, I, D values
	long motorkp[NUM_MOT]
	long motorki[NUM_MOT]
	long motorkd[NUM_MOT]
	long rps[NUM_MOT]
	long motorvolt[NUM_MOT]
	long motoramp[NUM_MOT]
	long motorpwm[NUM_MOT]
	long motorthrust[NUM_MOT]
	long motortorque[NUM_MOT]
	long motordesiredrps[NUM_MOT]


OBJ
'	debug : "FullDuplexSerialPlus.spin"
	debug : "FullDuplexSerial4portPlus_0v3"

PUB Main | i, j, counter

'	debug.start(DEBUG_RX_PIN, DEBUG_TX_PIN, 0, 230400)
	init_uarts
	
	counter := 0
	
	repeat

'		j := cnt
'		i := cnt
		rps[0]++
		if rps[0] > 100
			rps[0] := 0
		
		motordesiredrps[0] := rps[0] + 27
			
		random(@motoramp, 4)
		random(@motorvolt, 8)
		random(@motorpwm, 12)
		random(@motorkp, 14)
		random(@motorki, 17)
		random(@motorkd, 22)
		random(@motorthrust, 24)
		random(@motortorque, 26)
		
'		i := cnt - i
'		debug.str(0, string("Calculate clock cycles: "))
'		debug.dec(0, i)
'		debug.str(0, string(10,13))
		i := cnt
		
		printMotorList(string("$ADRPS "), @rps)
'		printMotorList(string("$ADMIA "), @motoramp)
'		printMotorList(string("$ADMVV "), @motorvolt)
'		printMotorList(string("$ADPWM "), @motorpwm)
'		printMotorList(string("$ADMKP "), @motorkp)
'		printMotorList(string("$ADMKI "), @motorki)
'		printMotorList(string("$ADMKD "), @motorkd)
'		printMotorList(string("$ADMTH "), @motorthrust)
'		printMotorList(string("$ADMTQ "), @motortorque)
'		printMotorList(string("$ADDRP "), @motordesiredrps)
'		
'		repeat 327
'			debug.tx_test0(0, "*")
'		repeat 2
'			debug.tx_test0(0, 10)
'			debug.tx_test0(0, 13)
		
'		debug.tx_test0(0, "*")

'		repeat 100
'			debug.dec(0, 123)



'		i := cnt - i
'		debug.str(0, string(10,13,10,13))
'		debug.str(0, string("Transmit clock cycles: "))
'		debug.dec_full(0, i)
'		debug.str(0, string(10,13,10,13))
'		
		
		
		
'		j := cnt - j
'		debug.str(0, string(10,13,10,13))
'		debug.str(0, string("Complete Loop clock cycles: "))
'		debug.dec(0, j)
'		debug.str(0, string(10,13,"Counter: "))
'		debug.dec(0, counter++)


'		debug.str(0, string(10,13,"timer_count: "))
'		debug.dec(0, debug.get_timer_count)
'		debug.clear_timer_count
		
		
'		debug.str(0, string(10,13,10,13))
		
		
		waitcnt(clkfreq/100 +cnt)
			
			
PUB random(variable_addr, offset)
	long[variable_addr][0] += (cnt & (%1111 << offset)) >> offset
	if long[variable_addr][0] > 1000
		long[variable_addr][0] := 200
		
PUB printMotorList(name_str_addr, variable_addr) | i
'' This function is a generic function to print $AD strings where each data element is a motor value, eg
'' $ADRPS rps[0], rps[1], rps[2], ..., rps[7]   <--- For an octorotor

	debug.str(0, name_str_addr)
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
