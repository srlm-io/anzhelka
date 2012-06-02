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

TODO:

- BUG: see http://code.google.com/p/anzhelka/issues/detail?id=4

}}

#define BLOCK_PID


CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

'IO Pins
	DEBUG_TX_PIN  = 30
	DEBUG_RX_PIN  = 31
	
	

	
#ifdef BLOCK_MOMENT
	RESULT_LENGTH = 3
	ACCEPTABLE_ERROR_MARGIN = 0.001
#elseifdef BLOCK_ALTITUDE
	RESULT_LENGTH = 1
	ACCEPTABLE_ERROR_MARGIN = 0.00001
#elseifdef BLOCK_MOTOR
	RESULT_LENGTH = 4
	ACCEPTABLE_ERROR_MARGIN = 0.00001
#elseifdef BLOCK_PID
	RESULT_LENGTH = 1
	ACCEPTABLE_ERROR_MARGIN = 0.001
#endif
	

VAR
	long min_time, max_time, average_time_running, time_count_running
	long failed_tests 'Number of test cases that did not pass
	long failed_tests_parts[RESULT_LENGTH] 'Number of subparts of a test that did not pass.
	
	long test_case 'The current test case

VAR

#ifdef BLOCK_MOMENT
'Moment Block
	long	omega_b[3]
	long	q[4]
	long	q_d[4]
	
	long	K_PH, K_DH, K_P_z, K_D_z
	
	long	result_spin[3]
	long	result_comp[3]
#elseifdef BLOCK_ALTITUDE
	long	placeholder

#elseifdef BLOCK_MOTOR
'Motor Block
	'Input Variables
	long	force_z
	long	moment[3]
	long	n[4]
	
	'Input Constants
	long	diameter
	long	offset
	long	density
	long	k_t
	long	k_q
	long	k_p_i
	long	k_i_i
	
	'Output Variable
	long	result_spin[4]
	long	result_comp[4]
	
#elseifdef BLOCK_PID
	'A PID Object Variables (12 longs total):
'	long Input_addr, Output_addr, Setpoint_addr
'	long ITerm, lastInput
'	long kp, ki, kd
'	long outMin, outMax
'	long inAuto
'	long controllerDirection
	
'Local Copies of values
	long Input, Setpoint
	
	long result_spin
	long result_comp
#endif	

OBJ
	debug      : "FastFullDuplexSerialPlusBuffer.spin"	
'	fp         : "Float32.spin"
	fp         : "F32_CMD.spin"
	
#ifdef BLOCK_MOMENT
'	block      : "block_moment.spin"
	block      : "block_moment_output.spin"
	test_cases : "block_moment_test_cases.spin"
#elseifdef BLOCK_ALTITUDE
	block      : "block_altitude.spin"
#elseifdef BLOCK_MOTOR
'	block      : "block_motor.spin"
	block      : "block_motor_output.spin"
	test_cases : "block_motor_test_cases.spin"
#elseifdef BLOCK_PID
	block      : "block_PID.spin"
	test_cases : "block_PID_test_cases.spin"	
	PID_data : "PID_data.spin"
#endif

PUB Main | correct_addr, debug_temp_0, debug_temp_1, i
	StartDebug
	
#ifdef BLOCK_MOMENT
	block.Start(@omega_b, @q, @q_d, @K_PH, @K_DH, @K_P_z, @K_D_z, @result_spin)
#elseifdef BLOCK_ALTITUDE
	block.Start(
#elseifdef BLOCK_MOTOR
	block.Start(@force_z, @moment, @n, @diameter, @offset, @density, @k_t, @k_q, @k_p_i, @k_i_i, @result_spin)
#elseifdef BLOCK_PID
'	Input_addr := @Input
'	Output_addr := @result_spin
'	Setpoint_addr := @Setpoint

	PID_data.setInput_addr(@Input)
	PID_data.setOutput_addr(@result_spin)
	PID_data.setSetpoint_addr(@Setpoint)
	
	PID_data.init
'	block.Start(@Input_addr, @result_spin)
	block.Start(PID_data.getBase)
#endif

	repeat test_case from 0 to test_cases.get_num_test_cases -1
		SetTestCases
		TimeCalculate
'#ifdef BLOCK_PID
'		FPrint(Input)
'		debug.tx(",")
'		debug.tx(" ")
'		FPrint(Setpoint)
'		
'		repeat i from 0 to 8
'			debug.tx(",")
'			debug.tx(" ")
'			FPrint(long[PID_data.getBase][3+i])
'		
'		debug.tx(",")
'		debug.tx(" ")
'		FPrint(result_spin)
'		
'		
'		debug.tx(10)
'		debug.tx(13)
'#endif
		CheckResult(@result_comp, @result_spin, RESULT_LENGTH)
	PrintStats
	
	FPrint(fp.FDiv(float(100), float(99)))

PRI StartDebug
'Sets up and starts debug related things...

	'Initialize the time values
	min_time := float(999999) 'Some high value
	max_time := float(0)      'Some low value
	average_time_running := float(0)
	time_count_running := float(0)
	failed_tests := 0

	fp.start
	debug.start(DEBUG_RX_PIN, DEBUG_TX_PIN, 0, 115200)
	waitcnt(clkfreq + cnt)
	debug.str(string("Starting", 10, 13))




PRI SetTestCases
#ifdef BLOCK_MOMENT
	test_cases.set_test_values(@omega_b, @q, @q_d, @K_PH, @K_DH, @K_P_z, @K_D_z, @result_comp)
#elseifdef BLOCK_ALTITUDE
	test_cases.set_test_values(
#elseifdef BLOCK_MOTOR
	test_cases.set_test_values(@force_z, @moment, @n, @diameter, @offset, @density, @k_t, @k_q, @k_p_i, @k_i_i, @result_comp)
#elseifdef BLOCK_PID
	test_cases.set_test_values(@Input, @Setpoint, PID_data.getBase + (4 * PID_data#ITERM), PID_data.getBase + (4 * PID_data#LASTINPUT), PID_data.getBase + (4 * PID_data#KP), PID_data.getBase + (4 * PID_data#KI), PID_data.getBase + (4 * PID_data#KD), PID_data.getBase + (4 * PID_data#OUTMIN), PID_data.getBase + (4 * PID_data#OUTMAX), PID_data.getBase + (4 * PID_data#INAUTO), PID_data.getBase + (4 * PID_data#CONTROLLERDIRECTION), @result_comp)
'	test_cases.set_test_values(@Input, @Setpoint, @ITerm, @lastInput, @kp, @ki, @kd, @outMin, @outMax, @inAuto, @controllerDirection, @result_comp)
#endif
		
PRI CheckResult(correct_addr, test_addr, length) | correct_val, test_val, i, high_correct_val, low_correct_val, failed, num_parts_failed
	
	num_parts_failed := 0
	failed := 0
	
	repeat i from 0 to length -1
		correct_val := long[@result_comp][i]
		test_val    := long[@result_spin][i]

'		debug.str(string(10, 13, "i == "))
'		debug.dec(i)
'		FPrint(Input)
'		debug.str(string("(Input)", 10, 13))

		
		high_correct_val := fp.FAdd(correct_val, ACCEPTABLE_ERROR_MARGIN)
		low_correct_val := fp.FSub(correct_val, ACCEPTABLE_ERROR_MARGIN)
		if fp.FCmp(high_correct_val, test_val) < 0 OR fp.FCmp(low_correct_val, test_val) > 0		
			debug.str(string("Error: incorrect result, "))
			FPrint(test_val)
			debug.str(string(" ($"))
			debug.hex(test_val, 8)
			debug.str(string(") <> "))
			FPrint(correct_val)
			debug.str(string(" ($"))
			debug.hex(correct_val, 8)
			debug.str(string(") (test value <> correct value), test case "))
			debug.dec(test_case)
			debug.str(string(", result index "))
			debug.dec(i)
			debug.tx(10)
			debug.tx(13)
			
			failed := 1
			
			num_parts_failed++
		
	if failed == 1
		failed_tests ++
		
		failed_tests_parts[num_parts_failed-1] ++
	
		
		
PRI FPrint(fnumA) | temp
	debug.str(fp.FloatToString(fnumA))
PRI PrintStats | average_time, i
	debug.str(string(10, 13, "-------------------------------------------------------"))

	debug.str(string(10, 13, "Maximum Time: "))
	FPrint(max_time)
	debug.str(string("ms", 10, 13, "Minimum Time: "))
	FPrint(min_time)
	average_time := fp.FDiv(average_time_running, fp.FFloat(time_count_running))
	debug.str(string("ms", 10, 13, "Average Time: "))
	FPrint(average_time)
	debug.str(string("ms", 10, 13, 10, 13))

	if failed_tests == 0
		debug.str(string("Success: no failed tests.", 10, 13))
	else
		debug.str(string("Failure: "))
		debug.dec(failed_tests)
		debug.str(string(" tests failed.", 10, 13))
		
		repeat i from 0 to RESULT_LENGTH-1
			debug.tx(9)
			debug.dec(failed_tests_parts[i])
			debug.str(string(9, "tests had "))
			debug.dec(i+1)
			debug.str(string(" total incorrect results", 10, 13))
		
	debug.str(string("-------------------------------------------------------", 10, 13))
	
	
PRI TimeCalculate | start_cnt, finish_cnt, time, start_cnt_min, finish_cnt_min, t1, t2
	'This function runs through the Calculate function and times how long it takes to execute
	'368 cycles is the cnt timing overhead
	
	block.SetInput 'Should not be in the timed section since it includes variables not moved in real operation
	start_cnt := cnt
	block.Calculate
	block.SetOutput
	finish_cnt := cnt
	

'code here that checks if finish_cnt < start_cnt (ie, rollover)
	if finish_cnt < start_cnt
		'Redo Calculations:
		debug.str(string(10,13, "Warning: CNT Rollover in TimeCalculate! Retrying Calculations (w/o rollover test)", 10, 13))
		start_cnt := cnt
		block.Calculate
		finish_cnt := cnt

	t1 := fp.FMul(fp.FFloat(finish_cnt - start_cnt), float(1000))
	time := fp.FDiv(t1, fp.FFloat(clkfreq))
	
	if fp.FCmp(time, min_time) == -1
		min_time := time
		
	if fp.FCmp(time, max_time) == 1
		max_time := time
		
	average_time_running := fp.FAdd(average_time_running, time)
	time_count_running ++
	

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














