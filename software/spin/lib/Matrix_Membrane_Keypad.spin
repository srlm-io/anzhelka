{{
--------------------------------------------------------------------------------
Anzhelka Project
(c) 2012

For the latest code and support, please visit:
http://code.anzhelka.com
--------------------------------------------------------------------------------

Title: 4x4 Matrix Membrane Keypad
Author: Cody Lewis
Date: 3-25-2012
Notes: Based on the "4x4 Keypad Reader.spin" object by Beau Schwabe


Operation:

This object uses a capacitive PIN approach to reading the keypad.
To do so, ALL pins are made LOW and an OUTPUT to "discharge" the
I/O pins.  Then, ALL pins are set to an INPUT state.  At this point,
only one pin is made HIGH and an OUTPUT at a time.  If the "switch"
is closed, then a HIGH will be read on the input, otherwise a LOW
will be returned.

The keypad decoding routine only requires two subroutines and returns
the entire 4x4 keypad matrix into a single WORD variable indicating
which buttons are pressed.  Multiple button presses are allowed with
the understanding that“BOX entries can be confused. An example of a
BOX entry... 1,2,4,5 or 1,4,3,6 or 4,6,*,#  etc. where any 3 of the 4
buttons pressed will evaluate the non pressed button as being pressed,
even when they are not.  There is no danger of any physical or
electrical damage, that s just the way this sensing method happens to
work.

Schematic:
No resistors, No capacitors.  The connections are directly from the
keypad to the I/O's.  I literally plugged mine right into the demo
board RevC.

Product Page:
http://www.parallax.com/tabid/768/ProductID/739/Default.aspx

***********************
Key Encoding Table
***********************
|Key|Return Value
|0	|0	|
|1	|1	|
...
|9	|9	|
|A	|10	|
|B	|11	|
|C	|12	|
|D	|13	|
|#	|14	|
|*__|15_|	



}}

VAR
	long KEYPAD_LOW_PIN
	long KEYPAD_HIGH_PIN

PUB init(KEYPAD_LOW_PIN_t, KEYPAD_HIGH_PIN_t)
''Must set the pins before calling any other function
	KEYPAD_LOW_PIN := KEYPAD_LOW_PIN_t
	KEYPAD_HIGH_PIN := KEYPAD_HIGH_PIN_t

PUB GetNumber | keypad, total	
''Returns the value of a multidigit decimal number
''Will block while waiting for input
''i.e., returns 128 if the user presses 1->2->8->*
''Note: user presses * to submit number
''Note: user presses # to cancel entire number (returns -1)

	'debug.str(string("Insert Number: "))
	total := 0
	repeat
		keypad := -1
		repeat until keypad <> -1
			keypad := ReadKeyPad
		repeat 2							'Debounce
			waitcnt(clkfreq /10 + cnt)		
			repeat until ReadKeyPad == -1
		if keypad == 15
			return total
		elseif keypad == 14
			return -1
		else
			total := total * 10 + keypad
			'debug.dec(keypad) 'Used to display each number as the user presses it
			

PUB ReadKeyPad | keypad
''Returns the numerical value of the digit pressed.
'' i.e., returns 3 for the 3 key, and 11 for the B key (B in hex is 11)
'' See chart at top of file

	keypad := 0					'Clear 4x4 'keypad' value
	keypad += ReadRow(3)		'Call routine to read entire ROW 0
	keypad <<= 4                'Shift 'keypad' value left by 4
	keypad += ReadRow(2)		'Call routine to read entire ROW 1
	keypad <<= 4				'Shift 'keypad' value left by 4
	keypad += ReadRow(1)		'Call routine to read entire ROW 2
	keypad <<= 4				'Shift 'keypad' value left by 4
	keypad += ReadRow(0)		'Call routine to read entire ROW 3
	if keypad == 0
		'debug.str(string("keypad == 0"))
		Result := -1
	else
		Result := lookup( >| keypad : 10,3,2,1,11,6,5,4,12,9,8,7,13,14,0,15)
'		Result := keypad

PUB ReadRow(n) | keypad
''Returns a single long with each bit representing a different key, pressed or not.

	outa[KEYPAD_LOW_PIN..KEYPAD_HIGH_PIN]~	'preset P0 to P7 as LOWs
	dira[KEYPAD_LOW_PIN..KEYPAD_HIGH_PIN]~~	'make P0 to P7 OUTPUTs ... discharge pins or "capacitors" to VSS
	dira[KEYPAD_LOW_PIN..KEYPAD_HIGH_PIN]~	'make P0 to P7 INPUTSs ... now the pins act like tiny capacitors
	outa[KEYPAD_LOW_PIN + n]~~				'preset Pin 'n' HIGH         
	dira[KEYPAD_LOW_PIN + n]~~				'make Pin 'n' an OUTPUT... Make only one pin HIGH ; will charge
											'                          "capacitor" if switch is closed. 
	Result := ina[(KEYPAD_LOW_PIN + 4)..KEYPAD_HIGH_PIN]	'read ROW value        ... If a switch is open, the pin or "capacitor"
	dira[KEYPAD_LOW_PIN + n]~								'make Pn an INPUT          will remain discharged

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
