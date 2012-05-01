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
	'Port names for Full Duplex Serial 4 port Plus
	PDEBUG = 0 'Debug port

VAR
 

OBJ
	debug 	:	"FullDuplexSerial4portPlus_0v3.spin"

PUB Main
	init_uarts
'	debug.start(DEBUG_RX_PIN, DEBUG_TX_PIN, 0, 115200)
	repeat

	
PUB init_uarts | extra
	extra := debug.init
	
	debug.AddPort(0, DEBUG_RX_PIN, DEBUG_TX_PIN, -1, -1, 0, 0, 115200)
	
	debug.Start
	
	waitcnt(clkfreq + cnt)
	
	debug.str(PDEBUG, string("$ADSTR 'Starting...'"))
	DebugNewLine
	
PUB DebugNewline
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
