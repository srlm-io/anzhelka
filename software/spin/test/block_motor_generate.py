#!/usr/bin/python

#--------------------------------------------------------------------------------
#Anzhelka Project
#(c) 2012

#For the latest code and support, please visit:
#http://code.anzhelka.com
#--------------------------------------------------------------------------------

#Title: block_motor_generate.py
#Author: Cody Lewis
#Date: May 14, 2012
#Notes: This program will automatically generate test cases for the block_motor.spin file

import math
import random

print "Hello World!"

NUM_DECIMAL_PLACES = 3

MAX_FORCE_Z = 32.0
MAX_MOMENT_XY = 0.333
MAX_MOMENT_Z = 0.01
MAX_ROTATION_SPEED = 50.0 #Hz
ROTOR_DIAMETER = 0.254
ROTOR_OFFSET = 0.333
DENSITY = 1.151

MIN_K_T = 0.67504 - 0.1
MAX_K_T = 0.67504 + 0.1

MIN_K_Q = 2.65764 - 0.5
MAX_K_Q = 2.65764 + 0.5

MIN_K_P = 1.0
MAX_K_P = 1.0

MIN_K_I = 1.0
MAX_K_I = 1.0

##Input Variables
#force_z = 0.0
#moment_x = 0.0
#moment_y = 0.0
#moment_z = 0.0
#n_1 = 0.0
#n_2 = 0.0
#n_3 = 0.0
#n_4 = 0.0

##Input Constants
#diameter = ROTOR_DIAMETER
#offset = ROTOR_OFFSET
#density = DENSITY


#k_t = 1.0
#k_q = 0.0
#k_p = 0.0
#k_i = 0.0

##Output Variables:
#u_i = 0

def	block_motor(force_z, moment_x, moment_y, moment_z, n_1, n_2, n_3, n_4, diameter, offset, density, k_t, k_q, k_p, k_i):
	#Do the block_motor calculations:
	c = k_q * diameter / k_t
	t_1 = moment_z / (4 * c)
	t_2 = moment_y / (2 * offset)
	t_3 = moment_x / (2 * offset)
	t_4 = force_z / 4
	F_1 = t_1 - t_2 + t_4
	F_2 = -t_1 -t_3 + t_4
	F_3 = t_1 + t_2 + t_4
	F_4 = -t_1 +t_3 + t_4
	
	t_1 = 2 * math.pi / (diameter * diameter)
	t_2 = density * k_t
	
	
	if F_1 < 0:
		print "'Warning: F_1 < 0! (F_1 = " + str(F_1) + ")"
		F_1 = 0
		
	if F_2 < 0:
		print "'Warning: F_2 < 0! (F_2 = " + str(F_2) + ")"
		F_2 = 0
	if F_3 < 0:
		print "'Warning: F_3 < 0! (F_3 = " + str(F_3) + ")"
		F_3 = 0
	if F_4 < 0:
		print "'Warning: F_4 < 0! (F_4 = " + str(F_4) + ")"
		F_4 = 0
	
	omega_d_1 = t_1 * math.sqrt(F_1 / t_2)
	omega_d_2 = t_1 * math.sqrt(F_2 / t_2)
	omega_d_3 = t_1 * math.sqrt(F_3 / t_2)
	omega_d_4 = t_1 * math.sqrt(F_4 / t_2)

#	return (omega_d_1, omega_d_2, omega_d_3, omega_d_4)

	n_d_1 = omega_d_1 / (2 * math.pi)
	n_d_2 = omega_d_2 / (2 * math.pi)
	n_d_3 = omega_d_3 / (2 * math.pi)
	n_d_4 = omega_d_4 / (2 * math.pi)

	return (n_d_1, n_d_2, n_d_3, n_d_4)

def main():





	print "CON"
	counter = 0
	print "\tf_z = " + str(counter)
	counter += 1
	print "\tm_x = " + str(counter)
	counter += 1
	print "\tm_y = " + str(counter)
	counter += 1
	print "\tm_z = " + str(counter)
	counter += 1
	print "\tn_1 = " + str(counter)
	counter += 1
	print "\tn_2 = " + str(counter)
	counter += 1
	print "\tn_3 = " + str(counter)
	counter += 1
	print "\tn_4 = " + str(counter)
	counter += 1
	print "\tdia = " + str(counter)
	counter += 1
	print "\toff = " + str(counter)
	counter += 1
	print "\trho = " + str(counter)
	counter += 1
	print "\tk_t = " + str(counter)
	counter += 1
	print "\tk_q = " + str(counter)
	counter += 1
	print "\tk_p = " + str(counter)
	counter += 1
	print "\tk_i = " + str(counter)
	counter += 1
	print "\tn_d_1 = " + str(counter)
	counter += 1
	print "\tn_d_2 = " + str(counter)
	counter += 1
	print "\tn_d_3 = " + str(counter)
	counter += 1
	print "\tn_d_4 = " + str(counter)
	counter += 1







	mystr =  "'test# \tlong\t" #+ str(a) + ",\t" + str(b) + ",\t" + str(c) 
	mystr += "f_z " + ",\t"
	mystr += "m_x " + ",\t"
	mystr += "m_y " + ",\t"
	mystr += "m_z " + ",\t"
	mystr += "n_1" + ",\t"
	mystr += "n_2" + ",\t"
	mystr += "n_3" + ",\t"
	mystr += "n_4" + ",\t"
	mystr += "dia" + ",\t"
	mystr += "off" + ",\t"
	mystr += "rho" + ",\t"
	mystr += "k_t" + ",\t"
	mystr += "k_q" + ",\t"
	mystr += "k_p" + ",\t"
	mystr += "k_i" + ",\t"
	mystr += "n_d_1        " + ",\t"
	mystr += "n_d_2        " + ",\t"
	mystr += "n_d_3        " + ",\t"
	mystr += "n_d_4        " + ",\t"

	print mystr



	for n in range(100):

		#Input Variables
		force_z = round(random.uniform(0, MAX_FORCE_Z), NUM_DECIMAL_PLACES)
		moment_x = round(random.uniform(-MAX_MOMENT_XY, MAX_MOMENT_XY), NUM_DECIMAL_PLACES)
		moment_y = round(random.uniform(-MAX_MOMENT_XY, MAX_MOMENT_XY), NUM_DECIMAL_PLACES)
		moment_z = round(random.uniform(-MAX_MOMENT_Z, MAX_MOMENT_Z), NUM_DECIMAL_PLACES)
		n_1 = round(random.uniform(0, MAX_ROTATION_SPEED), NUM_DECIMAL_PLACES) #.normalvariate(mean, sdev) for a gausian distribution
		n_2 = round(random.uniform(0, MAX_ROTATION_SPEED), NUM_DECIMAL_PLACES)
		n_3 = round(random.uniform(0, MAX_ROTATION_SPEED), NUM_DECIMAL_PLACES)
		n_4 = round(random.uniform(0, MAX_ROTATION_SPEED), NUM_DECIMAL_PLACES)

		#Input Constants
		diameter = ROTOR_DIAMETER
		offset = ROTOR_OFFSET
		density = DENSITY


		k_t = round(random.uniform(MIN_K_T, MAX_K_T), NUM_DECIMAL_PLACES)
		k_q = round(random.uniform(MIN_K_Q, MAX_K_Q), NUM_DECIMAL_PLACES)
		k_p = round(random.uniform(MIN_K_P, MAX_K_P), NUM_DECIMAL_PLACES)
		k_i = round(random.uniform(MIN_K_I, MAX_K_I), NUM_DECIMAL_PLACES)




		mystr =  "test" + str(n) + " \tlong\t" #+ str(a) + ",\t" + str(b) + ",\t" + str(c) 
		mystr += str(force_z) + ",\t"
		mystr += str(moment_x) + ",\t"
		mystr += str(moment_y) + ",\t"
		mystr += str(moment_z) + ",\t"
		mystr += str(n_1) + ",\t"
		mystr += str(n_2) + ",\t"
		mystr += str(n_3) + ",\t"
		mystr += str(n_4) + ",\t"
		mystr += str(diameter) + ",\t"
		mystr += str(offset) + ",\t"
		mystr += str(density) + ",\t"
		mystr += str(k_t) + ",\t"
		mystr += str(k_q) + ",\t"
		mystr += str(k_p) + ",\t"
		mystr += str(k_i) + ",\t"

		n_d_1, n_d_2, n_d_3, n_d_4 = block_motor(force_z, moment_x, moment_y, moment_z, n_1, n_2, n_3, n_4, diameter, offset, density, k_t, k_q, k_p, k_i)
		mystr += str(n_d_1) + ",\t"
		mystr += str(n_d_2) + ",\t"
		mystr += str(n_d_3) + ",\t"
		mystr += str(n_d_4)# + ",\t"

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



