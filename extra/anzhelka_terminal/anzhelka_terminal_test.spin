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
Notes: This software is used to test the functionality of the Anzhelka Terminal program.

This software is meant to be run on the quickstart. It uses:

- LEDS
- Touchpads (maybe...).

Some notes:

-- This will have some jitter on the output. This is intentional! You can take it out by commenting out that secion
-- This outputs three string types:
	- $ADSTR
	- $ADTHR
	- $ADRPS

}}
CON
	_clkmode = xtal1 + pll16x
	_xinfreq = 5_000_000

CON
'IO Pins
	DEBUG_TX_PIN  = 30
	DEBUG_RX_PIN  = 31
	
	CLOCK_PIN = 23 'Unconnected to anything else (well, LED in this case, but we'll pretend that didn't happen...)
	

	
	
	JITTER_LED = 22
	SATURATE_LED = 21
	PAUSE_LED = 20
	
VAR
	long spinstack0[100]
	long spinstack1[100]
	long spinstack2[100]
	long spinstack3[100]
	
	
	long motorrps[4]
	long motorthrust[4]
	
	long pause

OBJ
'	serial 	:	"FastFullDuplexSerialPlusBuffer.spin"
'	fp		:	"F32_CMD.spin"

PUB Main | i, random

	random := 1024 'seed value
	InitFunctions

	cognew(rpsloop, @spinstack0)
	cognew(mthloop, @spinstack1)

	dira[22..16]~~
	
	pause := False 'Delays the loop cogs

	repeat
		'Repeat with jitter	
		outa[JITTER_LED]~~
		PrintStr(string("Beginning jitter phase..."))	
		repeat 500
			PrintArray(string("RPS"), @motorrps, 4, TYPE_INT)
			PrintArray(string("THR"), @motorthrust, 4, TYPE_INT)
			waitcnt((clkfreq / ((?random & $FFF) + 1)) + cnt) 'Add some jitter between strings
		outa[JITTER_LED]~

		'Repeat and try to saturate channel (send strings as fast as possible)
		outa[SATURATE_LED]~~
		PrintStr(string("Beginning saturate phase..."))
		repeat 500
			PrintArray(string("RPS"), @motorrps, 4, TYPE_INT)
			PrintArray(string("THR"), @motorthrust, 4, TYPE_INT)
		outa[SATURATE_LED]~
		
		'Test the pause functionality
		pause := True
		waitcnt(clkfreq/100 + cnt)
		PrintArray(string("RPS"), @motorrps, 4, TYPE_INT)
		PrintArray(string("THR"), @motorthrust, 4, TYPE_INT)
		outa[PAUSE_LED]~~
		PrintSTR(string("Beginning pause phase..."))
		waitcnt(clkfreq * 5 + cnt) 'Wait for 5 seconds
		outa[PAUSE_LED]~
		pause := False
		
	

PUB mthloop | i, j, k, l
	repeat
		repeat i from 0 to 5000 step 42
			motorthrust[0] := i
			repeat j from 0 to 5000 step 317
				motorthrust[1] := j
				repeat k from 0 to 5000 step 57
					motorthrust[2] := k
					repeat l from 0 to 5000 step 64
						motorthrust[3] := l
						repeat
						while pause == True


PUB rpsloop | i, j, k, l
	repeat
		repeat i from 0 to 50 step 7
			motorrps[0] := i
			repeat j from 0 to 50 step 5
				motorrps[1] := j
				repeat k from 0 to 50 step 3
					motorrps[2] := k
					repeat l from 0 to 50
						motorrps[3] := l
						repeat
						while pause == True






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
