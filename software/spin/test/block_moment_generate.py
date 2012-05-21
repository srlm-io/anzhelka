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

MAX_OMEGA_B = 12.56636

MAX_K_PH = 1.0
MIN_K_PH = 1.0

MAX_K_DH = 1.0
MIN_K_DH = 1.0

MAX_K_P_z = 1.0
MIN_K_P_z = 1.0

MAX_K_D_z = 1.0
MIN_K_D_z = 1.0

##Input Variables
omega_b_x = 0.0
omega_b_y = 0.0
omega_b_z = 0.0

q = (0.0, 0.0, 0.0, 0.0)
q_d = (0.0, 0.0, 0.0, 0.0)

##Input Constants
K_PH = 1.0
K_DH = 1.0
K_P_z = 1.0
K_D_z = 1.0

##Output Variables:
M_x = 0.0
M_y = 0.0
M_z = 0.0


def block_moment(omega_b_x, omega_b_y, omega_b_z, q, q_d, K_PH, K_DH, K_P_z, K_D_z):
	w,x,y,z = quat_multiply(q, q_d)
	return (w,x,z)
#	return (M_x, M_y, M_z)


def quat_multiply(q1, q2):
	
#Let Q1 and Q2 be two quaternions, which are defined, respectively, as (w1, x1, y1, z1) and (w2, x2, y2, z2).
#(Q1 * Q2).w = (w1w2 - x1x2 - y1y2 - z1z2)
#(Q1 * Q2).x = (w1x2 + x1w2 + y1z2 - z1y2)
#(Q1 * Q2).y = (w1y2 - x1z2 + y1w2 + z1x2)
#(Q1 * Q2).z = (w1z2 + x1y2 - y1x2 + z1w2
	w1, x1, y1, z1 = q1
	w2, x2, y2, z2 = q2
	

	w = (w1*w2 - x1*x2 - y1*y2 - z1*z2)
	x = (w1*x2 + x1*w2 + y1*z2 - z1*y2)
	y = (w1*y2 - x1*z2 + y1*w2 + z1*x2)
	z = (w1*z2 + x1*y2 - y1*x2 + z1*w2)

	return (w, x, y, z)


def vect_norm(a, b, c):
	norm = math.sqrt(a*a + b*b + c*c)
	return (a/norm, b/norm, c/norm)

def vect_dot(v1, v2):
	a1, b1, c1 = v1
	a2, b2, c2 = v2
	return (a1*a2, b1*b2, c1*c2)
	
def quat_create(fAngle, x, y, z):
#Create a quaternion from a vector and angle
#It will normalize the vector as well.


#//axis is a unit vector
#local_rotation.w  = cosf( fAngle/2)
#local_rotation.x = axis.x * sinf( fAngle/2 )
#local_rotation.y = axis.y * sinf( fAngle/2 )
#local_rotation.z = axis.z * sinf( fAngle/2 )

	x, y, z = vect_norm(x, y, z)

	w  = math.cos( fAngle/2)
	x = x * math.sin( fAngle/2 )
	y = y * math.sin( fAngle/2 )
	z = z * math.sin( fAngle/2 )

	w = round(w, NUM_DECIMAL_PLACES)
	x = round(x, NUM_DECIMAL_PLACES)
	y = round(y, NUM_DECIMAL_PLACES)
	z = round(z, NUM_DECIMAL_PLACES)

	return (w, x, y, z)

def quat_start():
	return (1, 0, 0, 0)

def quat_star(q1):
	w1, x1, y1, z1 = q1
	return (w1, -x1, -y1, -z1)
	

#def	block_altitude(q, R_e_z, desired_R_e_z, m, g, K_P_z, K_I_z, K_D_z, F_z):
#	
#	a, v1, v2, v3 = quat_multiply(quat_multiply(q, (0,0,0,-1)), quat_star(q))
#	
#	t1, t2, K_tilt = vect_dot((0,0,1), (v1, v2, v3) )
#	
#	
#	return K_tilt





def main():


	print "CON"
	counter = 0
	print "\tomega_b_x = " + str(counter)
	counter += 1
	print "\tomega_b_y = " + str(counter)
	counter += 1
	print "\tomega_b_z = " + str(counter)
	counter += 1
	print "\tq_1 = " + str(counter)
	counter += 1
	print "\tq_2 = " + str(counter)
	counter += 1
	print "\tq_3 = " + str(counter)
	counter += 1
	print "\tq_4 = " + str(counter)
	counter += 1
	print "\tq_d_1 = " + str(counter)
	counter += 1
	print "\tq_d_2 =  " + str(counter)
	counter += 1
	print "\tq_d_3 = " + str(counter)
	counter += 1
	print "\tq_d_4 = " + str(counter)
	counter += 1
	print "\tK_PH = " + str(counter)
	counter += 1
	print "\tK_DH = " + str(counter)
	counter += 1
	print "\tK_P_z = " + str(counter)
	counter += 1
	print "\tK_D_z = " + str(counter)
	counter += 1
	print "\tM_x = " + str(counter)
	counter += 1
	print "\tM_y = " + str(counter)
	counter += 1
	print "\tM_z = " + str(counter)
	counter += 1



	print "\n\tCOLUMNS = " + str(counter)

	print "\n\tNUM_TEST_CASES = " + str(NUM_TESTS)

	print "\n\n"


	mystr =  ("'test#").ljust(12) #+ str(a) + ",\t" + str(b) + ",\t" + str(c) 
	mystr += ("om_b_x").rjust(8)
	mystr += ("om_b_y").rjust(8)
	mystr += ("om_b_z").rjust(8)
	mystr += ("q_1").rjust(8)
	mystr += ("q_2").rjust(8)
	mystr += ("q_3").rjust(8)
	mystr += ("q_4").rjust(8)
	mystr += ("q_d_1").rjust(8)
	mystr += ("q_d_2").rjust(8)
	mystr += ("q_d_3").rjust(8)
	mystr += ("q_d_4").rjust(8)
	mystr += ("K_PH").rjust(8)
	mystr += ("K_DH").rjust(8)
	mystr += ("K_P_z").rjust(8)
	mystr += ("K_D_z").rjust(8)
	mystr += ("M_x").rjust(12)
	mystr += ("M_y").rjust(12)
	mystr += ("M_z").rjust(12)

	print mystr



	for n in range(NUM_TESTS):
	
#		MAX_OMEGA_B = 12.56636

#		MAX_K_PH = 1.0
#		MIN_K_PH = 1.0

#		MAX_K_DH = 1.0
#		MIN_K_DH = 1.0

#		MAX_K_P_z = 1.0
#		MIN_K_P_z = 1.0

#		MAX_K_D_z = 1.0
#		MIN_K_D_z = 1.0

#		##Input Variables
#		omega_b_x = 0.0
#		omega_b_y = 0.0
#		omega_b_z = 0.0

#		q = (0.0, 0.0, 0.0, 0.0)
#		q_d = (0.0, 0.0, 0.0, 0.0)

#		##Input Constants
#		K_PH = 1.0
#		K_DH = 1.0
#		K_P_z = 1.0
#		K_D_z = 1.0

#		##Output Variables:
#		M_x = 0.0
#		M_y = 0.0
#		M_z = 0.0
	

		#Input Variables
		omega_b_x = round(random.uniform(-MAX_OMEGA_B, MAX_OMEGA_B), NUM_DECIMAL_PLACES)
		omega_b_y = round(random.uniform(-MAX_OMEGA_B, MAX_OMEGA_B), NUM_DECIMAL_PLACES)
		omega_b_z = round(random.uniform(-MAX_OMEGA_B, MAX_OMEGA_B), NUM_DECIMAL_PLACES)
		
		angle = round(random.uniform(0, 2.0 * math.pi), NUM_DECIMAL_PLACES)
		x = round(random.uniform(-1.0, 1.0), NUM_DECIMAL_PLACES)
		y = round(random.uniform(-1.0, 1.0), NUM_DECIMAL_PLACES)
		z = round(random.uniform(-1.0, 1.0), NUM_DECIMAL_PLACES)
		q = quat_create(angle, x, y, z)
		
		angle = round(random.uniform(0, 2.0 * math.pi), NUM_DECIMAL_PLACES)
		x = round(random.uniform(-1.0, 1.0), NUM_DECIMAL_PLACES)
		y = round(random.uniform(-1.0, 1.0), NUM_DECIMAL_PLACES)
		z = round(random.uniform(-1.0, 1.0), NUM_DECIMAL_PLACES)
		q_d = quat_create(angle, x, y, z)
		
		K_PH = 1.0
		K_DH = 1.0
		K_P_z = 1.0
		K_D_z = 1.0
		
		
#		mystr =  "test" + str(n) + " \tlong\t" #+ str(a) + ",\t" + str(b) + ",\t" + str(c) 
#		mystr += str(omega_b_x) + ",\t"
#		mystr += str(omega_b_y) + ",\t"
#		mystr += str(omega_b_z) + ",\t"
#		mystr += str(q[0]) + ",\t "
#		mystr += str(q[1]) + ",\t "
#		mystr += str(q[2]) + ",\t "
#		mystr += str(q[3]) + ",\t "
#		mystr += str(q_d[0]) + ",\t "
#		mystr += str(q_d[1]) + ",\t "
#		mystr += str(q_d[2]) + ",\t "
#		mystr += str(q_d[3]) + ",\t "
#		mystr += str(K_PH) + ",\t"
#		mystr += str(K_DH) + ",\t"
#		mystr += str(K_P_z) + ",\t"
#		mystr += str(K_D_z) + ",\t"

#		M_x, M_y, M_z = block_moment(omega_b_x, omega_b_y, omega_b_z, q, q_d, K_PH, K_DH, K_P_z, K_D_z)
#		mystr += str(M_x) + ",\t"
#		mystr += str(M_y) + ",\t"
#		mystr += str(M_z)# + ",\t"
#		
#		



		mystr =  ("test" + str(n)).ljust(7) + " long " #+ str(a) + ",\t" + str(b) + ",\t" + str(c) 
		mystr += (str(omega_b_x) + ",").rjust(8)
		mystr += (str(omega_b_y) + ",").rjust(8)
		mystr += (str(omega_b_z) + ",").rjust(8)
		mystr += (str(q[0]) + ",").rjust(8)
		mystr += (str(q[1]) + ",").rjust(8)
		mystr += (str(q[2]) + ",").rjust(8)
		mystr += (str(q[3]) + ",").rjust(8)
		mystr += (str(q_d[0]) + ",").rjust(8)
		mystr += (str(q_d[1]) + ",").rjust(8)
		mystr += (str(q_d[2]) + ",").rjust(8)
		mystr += (str(q_d[3]) + ",").rjust(8)
		mystr += (str(K_PH) + ",").rjust(8)
		mystr += (str(K_DH) + ",").rjust(8)
		mystr += (str(K_P_z) + ",").rjust(8)
		mystr += (str(K_D_z) + ",").rjust(8)

		M_x, M_y, M_z = block_moment(omega_b_x, omega_b_y, omega_b_z, q, q_d, K_PH, K_DH, K_P_z, K_D_z)
		mystr += (str(M_x) + ",").rjust(12)
		mystr += (str(M_y) + ",").rjust(12)
		mystr += (str(M_z)).rjust(12)

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



