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

- BUG: In the time calculate function, when I add the 

}}

#define BLOCK_MOTOR


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
#endif	

OBJ
	debug      : "FullDuplexSerialPlus.spin"	

	fp         : "Float32.spin"
	
'	fp_pid	   : "F32_PID.spin"

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
#endif



PUB Main | correct_addr, debug_temp_0, debug_temp_1

	StartDebug
	
	
#ifdef BLOCK_MOMENT
	block.Start(@omega_b, @q, @q_d, @K_PH, @K_DH, @K_P_z, @K_D_z, @result_spin)
#elseifdef BLOCK_ALTITUDE
	block.Start(
#elseifdef BLOCK_MOTOR
	block.Start(@force_z, @moment, @n, @diameter, @offset, @density, @k_t, @k_q, @k_p_i, @k_i_i, @result_spin)
#endif


	repeat test_case from 0 to test_cases.get_num_test_cases -1
		SetTestCases
		TimeCalculate
		CheckResult(@result_comp, @result_spin, RESULT_LENGTH)
	PrintStats
	
'	fp_pid.start
'	debug.str(string(10, 13, "Number to put through test: "))
'	FPrint(result_spin[0])
'	debug.str(string(" ($"))
'	debug.hex(result_spin[0], 8)
'	
'	debug.str(string(")", 10, 13, "Float32: "))
'	debug_temp_0 := fp.ACos(result_spin[0])
'	FPrint(debug_temp_0)
'	debug.str(string(" ($"))
'	debug.hex(debug_temp_0, 8)
'	
'	debug.str(string(")", 10, 13, "F32_PID: "))
'	debug_temp_0 := fp_pid.ACos(result_spin[0])
'	FPrint(debug_temp_0)
'	debug.str(string(" ($"))
'	debug.hex(debug_temp_0, 8)
'	debug.tx(")")

PRI StartDebug
'Sets up and starts debug related things...

	'Initialize the time values
	min_time := float(999999) 'Some high value
	max_time := float(0)      'Some low value
	average_time_running := float(0)
	time_count_running := float(0)
	failed_tests := 0

	fp.start
	debug.start(DEBUG_RX_PIN, DEBUG_TX_PIN, 0, 230400)
	waitcnt(clkfreq + cnt)
	debug.str(string("Starting", 10, 13))




PRI SetTestCases
#ifdef BLOCK_MOMENT
	test_cases.set_test_values(@omega_b, @q, @q_d, @K_PH, @K_DH, @K_P_z, @K_D_z, @result_comp)
#elseifdef BLOCK_ALTITUDE
	test_cases.set_test_values(
#elseifdef BLOCK_MOTOR
	test_cases.set_test_values(@force_z, @moment, @n, @diameter, @offset, @density, @k_t, @k_q, @k_p_i, @k_i_i, @result_comp)
#endif
		
PRI CheckResult(correct_addr, test_addr, length) | correct_val, test_val, i, high_correct_val, low_correct_val, failed, num_parts_failed
	
	num_parts_failed := 0
	failed := 0
	
	repeat i from 0 to length -1
		correct_val := long[@result_comp][i]
		test_val    := long[@result_spin][i]
		
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
'Will print a floating point number up to 3 decimal places (without rounding)
	temp := float(1000)
	
	if fp.FCmp(fnumA, float(0)) == -1 'less than 0...
		debug.tx("-")
	debug.dec(fp.FAbs(fp.FTrunc(fnumA)))
	debug.tx(".")
	debug.dec(fp.FTrunc(fp.FMul(fp.Frac(fnumA), temp )))
	

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














