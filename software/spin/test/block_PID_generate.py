#!/usr/bin/python

#--------------------------------------------------------------------------------
#Anzhelka Project
#(c) 2012

#For the latest code and support, please visit:
#http://code.anzhelka.com
#--------------------------------------------------------------------------------

#Title: block_altitude_generate.py
#Author: Cody Lewis
#Date: May 14, 2012
#Notes: This program will automatically generate test cases for the block_altitude.spin file

import math
import random

print "Hello World!"

NUM_TESTS = 100
NUM_DECIMAL_PLACES = 3




MAX_INPUT = 1000.0
MIN_INPUT = 0.0

MAX_SETPOINT = 1000.0
MIN_SETPOINT = 0.0

MAX_ITERM = 1000.0
MIN_ITERM = -1000.0

MAX_KP = 10.0
MIN_KP = 0.01

MAX_KI = 10.0
MIN_KI = 0.01

MAX_KD = 10.0
MIN_KD = 0.01

MAX_OUTMIN = 100.0
MIN_OUTMIN = 0.0

MAX_OUTMAX = 1200.0
MIN_OUTMAX = 800.0

#inAuto = 0 | 1
#controllerDirection = 0 | 1

def block_pid( Input, Setpoint, ITerm, lastInput, kp, ki, kd, outMin, outMax, inAuto, controllerDirection):
	error = Setpoint - Input
	ITerm += (ki * error)
	if (ITerm > outMax):
		ITerm = outMax
	if (ITerm < outMin):
		ITerm = outMin
	dInput = Input - lastInput
	
	Output = kp * error + ITerm - kd * dInput
	if (Output > outMax):
		Output = outMax
	if (Output < outMin):
		Output = outMin
	
	lastInput = Input

	return Output
	
def main():

	print "CON"
	counter = 0
	print "\tInput = " + str(counter)
	counter += 1
	print "\tSetpoint = " + str(counter)
	counter += 1
	print "\tITerm = " + str(counter)
	counter += 1
	print "\tlastInput = " + str(counter)
	counter += 1
	print "\tkp = " + str(counter)
	counter += 1
	print "\tki = " + str(counter)
	counter += 1
	print "\tkd = " + str(counter)
	counter += 1
	print "\toutMin = " + str(counter)
	counter += 1
	print "\toutMax = " + str(counter)
	counter += 1
	print "\tinAuto = " + str(counter)
	counter += 1
	print "\tcontrollerDirection = " + str(counter)
	counter += 1
	print "\tOutput = " + str(counter)
	counter += 1
	


	print "\n\tCOLUMNS = " + str(counter)

	print "\n\tNUM_TEST_CASES = " + str(NUM_TESTS)

	print "\n\n"

	mystr =  ("'test#").ljust(12) #+ str(a) + ",\t" + str(b) + ",\t" + str(c) 
	mystr += ("Input").rjust(10)
	mystr += ("Setpnt").rjust(10)
	mystr += ("ITerm").rjust(10)
	mystr += ("lastIn").rjust(10)
	mystr += ("kp").rjust(10)
	mystr += ("ki").rjust(10)
	mystr += ("kd").rjust(10)
	mystr += ("outMin").rjust(10)
	mystr += ("outMax").rjust(10)
	mystr += ("inAuto").rjust(10)
	mystr += ("contDir").rjust(10)
	mystr += ("output").rjust(12)

	print mystr

	for n in range(NUM_TESTS):

		#Input Variables
		Input = round(random.uniform(MIN_INPUT, MAX_INPUT), NUM_DECIMAL_PLACES)
		Setpoint = round(random.uniform(MIN_SETPOINT, MAX_SETPOINT), NUM_DECIMAL_PLACES)
		ITerm = round(random.uniform(MIN_ITERM, MAX_ITERM), NUM_DECIMAL_PLACES)
		lastInput = round(random.uniform(MIN_INPUT, MAX_INPUT), NUM_DECIMAL_PLACES)
		kp = round(random.uniform(MIN_KP, MAX_KP), NUM_DECIMAL_PLACES)
		ki = round(random.uniform(MIN_KI, MAX_KI), NUM_DECIMAL_PLACES)
		kd = round(random.uniform(MIN_KD, MAX_KD), NUM_DECIMAL_PLACES)
		outMin = round(random.uniform(MIN_OUTMIN, MAX_OUTMIN), NUM_DECIMAL_PLACES)
		outMax= round(random.uniform(MIN_OUTMAX, MAX_OUTMAX), NUM_DECIMAL_PLACES)
		inAuto = 1
		controllerDirection = 1
		

		mystr =  ("test" + str(n)).ljust(7) + " long " #+ str(a) + ",\t" + str(b) + ",\t" + str(c) 
		mystr += (str(Input) + ",").rjust(10)
		mystr += (str(Setpoint) + ",").rjust(10)
		mystr += (str(ITerm) + ",").rjust(10)
		mystr += (str(lastInput) + ",").rjust(10)
		mystr += (str(kp) + ",").rjust(10)
		mystr += (str(ki) + ",").rjust(10)
		mystr += (str(kd) + ",").rjust(10)
		mystr += (str(outMin) + ",").rjust(10)
		mystr += (str(outMax) + ",").rjust(10)
		mystr += (str(inAuto) + ",").rjust(10)
		mystr += (str(controllerDirection) + ",").rjust(10)
		
		
		
		Output = block_pid( Input, Setpoint, ITerm, lastInput, kp, ki, kd, outMin, outMax, inAuto, controllerDirection)
		mystr += (str(Output)).rjust(12)
		
		print mystr

if __name__ == "__main__":

	main()
	
#--------------------------------------------------------------------------------  
#Copyright (c) 2012 Cody Lewis and Luke De Ruyter

#Permission is hereby granted, free of charge, to any person obtaining a copy of
#this software and associated documentation files (the "Software"), to deal in
#the Software without restriction, including without limitation the rights to
#use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
#the Software, and to permit persons to whom the Software is furnished to do so,
#subject to the following conditions: 

#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software. 

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
#FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
#COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
#IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
#CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#--------------------------------------------------------------------------------



