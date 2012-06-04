{{
--------------------------------------------------------------------------------
Anzhelka Project
(c) 2012

For the latest code and support, please visit:
http://code.anzhelka.com
--------------------------------------------------------------------------------

Title: PID_data.spin
Author: Cody Lewis
Date: 28 May 2012
Notes: This file is a data structure for the PID operations found in F32_CMD.spin.
}}


CON
	INPUT_ADDR          = 0
	OUTPUT_ADDR         = 1
	SETPOINT_ADDR       = 2
	ITERM               = 3
	LASTINPUT           = 4
	KP                  = 5
	KI                  = 6
	KD                  = 7
	OUTMIN              = 8
	OUTMAX              = 9
	INAUTO              = 10
	CONTROLLERDIRECTION = 11
	SAMPLETIME          = 12

VAR
'A PID Object Variables (12 longs total):
'The 'v' prefix denotes variable (as opposed to constant)
	long vInput_addr, vOutput_addr, vSetpoint_addr
	long vITerm, vlastInput
	long vkp, vki, vkd
	long voutMin, voutMax
	long vinAuto
	long vcontrollerDirection
	long vSampleTime
	
PUB getBase
	return @vInput_addr
PUB getITerm
	return vITerm
PUB getLastInput
	return vlastInput

PUB getKpAddr
	return @vkp
PUB getKiAddr
	return @vki
PUB getKdAddr
	return @vkd
	
PUB getKp
	return vkp
PUB getKi
	return vki
PUB getKd
	return vkd
	
PUB getSampleTime
	return vSampleTime

'PUB setInput_addr(address)
'	vInput_addr := address
'PUB setOutput_addr(address)
'	vOutput_addr := address
'PUB setSetpoint_addr(address)
'	vSetpoint_addr := address
'PUB setOutmin(value)
'	'Value is a floating point number
'	vOutmin := value
'PUB setOutmax(value)
'	'Value is a floating point number
'	vOutmax := value
	
	



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
