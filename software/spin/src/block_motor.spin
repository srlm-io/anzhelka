{{

--------------------------------------------------------------------------------
Anzhelka Project
(c) 2012

For the latest code and support, please visit:
http://code.anzhelka.com
--------------------------------------------------------------------------------

Title: Anzhelka Motor Control Block
Author: Cody Lewis
Date: May 13, 2012

Notes: 
--- Implements the motor control block (#3) from the quadrotor mathematics document.
TODO:
--- On the SetXXX methods, convert the array access to LONGMOVE type instructions.

}}


OBJ
'	fp	: "Float32.spin"
'    fp  : "Float.spin"
	fp : "F32.spin"
VAR
''Input Variables
	long	force_z_addr
	long	moment_addr		' (3 longs)
	long	n_addr			'rotation frequency of rotors (4 longs)

''Input Constants
	long	diameter_addr
	long	offset_addr		'Rotor offset from the center of mass
	long	density_addr	'Air density
	long	k_t_addr		'thrust coefficient
	long	k_q_addr		'torque coefficient
	long	k_p_i_addr		'motor proportional PID gain (4 longs)
	long	k_i_i_addr		'motor integral PID gain (4 longs)


	long	mypi			'TODO: define pi in floating point


''Output Variables
	long	n_d_i_addr		'Motor command (4 longs)



VAR

	long	K_Q, K_T
	long	diameter, offset 'D, d in the documentation, respectively
	long	c
	long	F_z
	long	M_x, M_y, M_z
	long	t_1, t_2, t_3, t_4
	long	F_1, F_2, F_3, F_4
	long	rho				'Air density
	long	omega_d_1, omega_d_2, omega_d_3, omega_d_4

	long	n_1, n_2, n_3, n_4
	long	n_d_1, n_d_2, n_d_3, n_d_4








PUB Start({
Input Variables:
	} force_z_addr_,{	
	} moment_addr_,{	(3 longs)
	} n_addr_,{			rotation frequency of rotors (4 longs)
	
Input Constants:
	} diameter_addr_,{	
	} offset_addr_,{	rotor offset from the center of mass
	} density_addr_,{	air density
	} k_t_addr_,{		thrust coefficient
	} k_q_addr_,{		torque coefficient
	} k_p_i_addr_,{		motor proportional PID gain (4 longs)
	} k_i_i_addr_,{		motor integral PID gain (4 longs)
	
Output Variables:
	} n_d_i_addr_{		motor desired hz (4 longs)
	
	
}) : okay

	'Copy the addresses:
	force_z_addr 	:= force_z_addr_
	moment_addr 	:= moment_addr_
	n_addr 			:= n_addr_
	diameter_addr 	:= diameter_addr_
	offset_addr 	:= offset_addr_
	density_addr 	:= density_addr_
	k_t_addr 		:= k_t_addr_
	k_q_addr 		:= k_q_addr_
	k_p_i_addr 		:= k_p_i_addr_
	k_i_i_addr 		:= k_i_i_addr_
	n_d_i_addr 		:= n_d_i_addr_


	fp.start
	

PUB GetResultAddr
	return @n_d_1
	
PUB SetInput
'Retrieves the input values and makes a local copy
'	test_cases.set_test_values(force_z_addr, moment_addr, n_addr, diameter_addr, offset_addr, density_addr, k_t_addr, k_q_addr, k_p_i_addr, k_i_i_addr, n_d_i_addr)
	
	F_z := long[force_z_addr]
	M_x := long[moment_addr][0]
	M_y := long[moment_addr][1]
	M_z := long[moment_addr][2]
	n_1 := long[n_addr][0]
	n_2 := long[n_addr][1]
	n_3 := long[n_addr][2]
	n_4 := long[n_addr][3]
	diameter := long[diameter_addr]
	offset := long[offset_addr]
	rho := long[density_addr]
	K_T := long[k_t_addr]
	K_Q := long[k_q_addr]	

PUB SetOutput
'Stores the most recently calculated output value

	long[n_d_i_addr][0] := n_d_1
	long[n_d_i_addr][1] := n_d_2
	long[n_d_i_addr][2] := n_d_3
	long[n_d_i_addr][3] := n_d_4


PUB Calculate
'One iteration of the calculations
'Should be called from a repeat loop...
'Writes object local variables, does not write to address

	c := fp.FDiv( fp.FMul(K_Q, diameter), K_T)
	
	t_1 := fp.FDiv( M_z, fp.FMul(float(4), c))
	
	t_2 := fp.FDiv( M_y, fp.FMul(float(2), offset))
	
	t_3 := fp.FDiv( M_x, fp.FMul(float(2), offset))
	
	t_4 := fp.FDiv( F_z, float(4))
	
	F_1 := fp.FAdd(t_1, fp.FAdd(fp.FNeg(t_2), t_4))
	if fp.FCmp(F_1, float(0)) < 0 'Force is negative
		F_1 := float(0) 
	
	F_2 := fp.FAdd(fp.FNeg(t_1), fp.FAdd(fp.FNeg(t_3), t_4))
	if fp.FCmp(F_2, float(0)) < 0 'Force is negative
		F_2 := float(0)
		
	F_3 := fp.FAdd(t_1, fp.FAdd(t_2, t_4))
	if fp.FCmp(F_3, float(0)) < 0 'Force is negative
		F_3 := float(0)
	
	F_4 := fp.FAdd(fp.FNeg(t_1), fp.FAdd(t_3, t_4))
	if fp.FCmp(F_4, float(0)) < 0 'Force is negative
		F_4 := float(0)
	
	t_1 := fp.FDiv(fp.FMul(float(2), pi), fp.FMul(diameter, diameter))
	
	t_2 := fp.FMul(rho, K_T)
	
	omega_d_1 := fp.FMul(t_1, fp.FSqr( fp.FDiv(F_1, t_2) ) )
	
	omega_d_2 := fp.FMul(t_1, fp.FSqr( fp.FDiv(F_2, t_2) ) )
	
	omega_d_3 := fp.FMul(t_1, fp.FSqr( fp.FDiv(F_3, t_2) ) )
	
	omega_d_4 := fp.FMul(t_1, fp.FSqr( fp.FDiv(F_4, t_2) ) )
	
	n_d_1 := fp.FDiv(omega_d_1, fp.FMul(float(2), pi))
	n_d_2 := fp.FDiv(omega_d_2, fp.FMul(float(2), pi))
	n_d_3 := fp.FDiv(omega_d_3, fp.FMul(float(2), pi))
	n_d_4 := fp.FDiv(omega_d_4, fp.FMul(float(2), pi))


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

