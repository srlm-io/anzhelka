#define BLOCK_MOMENT


CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

'IO Pins
	DEBUG_TX_PIN  = 30
	DEBUG_RX_PIN  = 31
	
	
	ACCEPTABLE_ERROR_MARGIN = 0.00001
	
#ifdef BLOCK_MOMENT
	RESULT_LENGTH = 3
#elseifdef BLOCK_ALTITUDE
	RESULT_LENGTH = 1
#elseifdef BLOCK_MOTOR
	RESULT_LENGTH = 4
#endif
	

VAR
	long min_time, max_time, average_time_running, time_count_running
	long failed_tests 'Number of test cases that did not pass
	
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
	

#ifdef BLOCK_MOMENT
	block      : "block_moment.spin"
	test_cases : "block_moment_test_cases.spin"
#elseifdef BLOCK_ALTITUDE
	block      : "block_altitude.spin"
#elseifdef BLOCK_MOTOR
	block      : "block_motor.spin"
	test_cases : "block_motor_test_cases.spin"
#endif

	

PUB Main | correct_addr

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
		
PRI CheckResult(correct_addr, test_addr, length) | correct_val, test_val, i, high_correct_val, low_correct_val, failed
	
	failed := 0
	
	repeat i from 0 to length -1
		correct_val := long[@result_comp][i]
		test_val    := long[@result_spin][i]
		
		high_correct_val := fp.FAdd(correct_val, ACCEPTABLE_ERROR_MARGIN)
		low_correct_val := fp.FSub(correct_val, ACCEPTABLE_ERROR_MARGIN)
		if fp.FCmp(high_correct_val, test_val) < 0 OR fp.FCmp(low_correct_val, test_val) > 0		
			debug.str(string("Error: incorrect result, "))
			FPrint(test_val)
			debug.str(string(" <> "))
			FPrint(correct_val)
			debug.str(string(" (test value <> correct value), test case "))
			debug.dec(test_case)
			debug.str(string(", result index "))
			debug.dec(i)
			debug.tx(10)
			debug.tx(13)
			
			failed := 1
		
	if failed == 1
		failed_tests ++
	
		
		
PRI FPrint(fnumA) | temp
'Will print a floating point number up to 3 decimal places (without rounding)
	temp := float(1000)
	debug.dec(fp.FTrunc(fnumA))
	debug.tx(".")
	debug.dec(fp.FTrunc(fp.FMul(fp.Frac(fnumA), temp )))
	

PRI PrintStats | average_time
	debug.str(string(10, 13, "----------------------------------------"))

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
		
	debug.str(string("----------------------------------------", 10, 13))
	
	
PRI TimeCalculate | start_cnt, finish_cnt, time
	'This function runs through the Calculate function and times how long it takes to execute
	

	start_cnt := cnt
	block.SetInput
	block.Calculate
	block.SetOutput
	finish_cnt := cnt
	
'code here that checks if finish_cnt < start_cnt (ie, rollover)
	if finish_cnt < start_cnt
		'Redo Calculations:
		debug.str(string("Rollover!"))
		start_cnt := cnt
		block.Calculate
		finish_cnt := cnt


	
'	debug.dec((finish_cnt-start_cnt)*1000/clkfreq) 'Integer Version
	time := fp.FDiv(fp.FMul(fp.FFloat( (finish_cnt - start_cnt) ), float(1000)), fp.FFloat(clkfreq))
	
	if fp.FCmp(time, min_time) == -1
		min_time := time
	if fp.FCmp(time, max_time) == 1
		max_time := time
		
	average_time_running := fp.FAdd(average_time_running, time)
	time_count_running ++
	
' Display the time to calculate this test case:
'	debug.str(string("Calculate Time: "))	
'	FPrint(time)
'	debug.str(string("ms", 10, 13))
