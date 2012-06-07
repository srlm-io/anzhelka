#!/usr/bin/python

#--------------------------------------------------------------------------------
#Anzhelka Project
#(c) 2012

#For the latest code and support, please visit:
#http://code.anzhelka.com
#--------------------------------------------------------------------------------

#Title: 
#Author: Cody Lewis
#Date: June 6, 2012
#Notes:

import sys
import string
import re
import math




def Quat_to_Euler(q_0, q_1, q_2, q_3):
	print "Input quaternion: ", q_0, q_1, q_2, q_3

#		estimated_states->psi = atan2(2*(q0*q3+q1*q2),q1*q1 + q0*q0 - q3*q3 - q2*q2)*180/3.14159;
	yaw = math.atan2(2.0*(q_0*q_3 + q_1*q_2), \
	                             q_1*q_1 + q_0*q_0 - q_3*q_3 - q_2*q_2)
#		estimated_states->theta = -asin(2*(q1*q3 - q0*q2))*180/3.14159;
	pitch = -math.asin(2.0*(q_1*q_3 - q_0*q_2))                          
#		estimated_states->phi = atan2(2*(q0*q1 + q2*q3),q3*q3 - q2*q2 - q1*q1 + q0*q0)*180/3.14159;                                  
	roll = math.atan2(2.0*(q_0*q_1 + q_2*q_3), \
		                             q_3*q_3 - q_2*q_2 - q_1*q_1 + q_0*q_0)
	
	print "CHR roll,pitch,yaw: ", roll*180.0/math.pi, pitch*180.0/math.pi, yaw*180.0/math.pi
	
	
	#heading = atan2(2*qy*qw-2*qx*qz , 1 - 2*qy2 - 2*qz2)
	yaw = math.atan2(2.0*q_2*q_0- \
		                         2.0*q_1*q_3, \
		                         1.0 - 2.0*q_2*q_2- \
		                         2.0*q_3*q_3)
		

                                     
                                     
#attitude = asin(2*qx*qy + 2*qz*qw) 
	pitch = math.asin(2.0*q_1*q_2+ \
		                         2.0*q_3*q_0)
		


#bank = atan2(2*qx*qw-2*qy*qz , 1 - 2*qx2 - 2*qz2)
	roll = math.atan2(2.0*q_1*q_0- \
		                      2.0*q_2*q_3, \
		                      1.0-2.0*q_1*q_1 - \
		                      2.0*q_3*q_3)
		
	print "Euc roll,pitch,yaw: ", roll*180.0/math.pi, pitch*180.0/math.pi, yaw*180.0/math.pi
		
		

def main():

#    Flat
	q_0 = 0.958437
	q_1 = 0.08258
	q_2 = 0.006915
	q_3 = -0.27299
	print "Flat."
	Quat_to_Euler(q_0,q_1,q_2,q_3)
	print "Should be (from um6)", 8.8989, 3.339835, -31.5417
	
#     45 degress on plug axis
	q_0 = 0.862026
	q_1 = -0.02115
	q_2 = -0.34415
	q_3 = -0.37155     
	print "45 degress on plug axis"
	Quat_to_Euler(q_0,q_1,q_2,q_3)
	

if __name__ == "__main__":
	main()
