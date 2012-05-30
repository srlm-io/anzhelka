#!/usr/bin/python

#--------------------------------------------------------------------------------
#Anzhelka Project
#(c) 2012

#For the latest code and support, please visit:
#http://code.anzhelka.com
#--------------------------------------------------------------------------------

#Title: math_processor.py
#Author: Cody Lewis
#Date: May 22, 2012
#Notes: This program will process the specified input file for math statements and generate the psuedo-asembly statements
#
#	TODO:
#		--- Bug: When a 0 is on the LHS, the compiler outputs @0
#
#
# --- Note: for unary operators, the second operator should be zero.
# --- ---- This is especially important for TruncRound, where the second operand (fnumB) controls the return type. We want it to be zero (integer, truncate)
#


import sys
import string
import re

con = [] #Used for staring indexes

#TODO: BUG: For the keywords list, arcXXX has to before XXX, otherwise it gets substituted wrong...
keywords = {"*":"Mul", "/":"Div", "+":"Add", "-":"Sub", "sqrt":"Sqr", "#>":"LimitMin", "arc_t2":"ATan2", "arc_c":"ACos", "arc_s":"ASin", "sin":"Sin", "cos":"Cos", "tan":"Tan", "~":"PID", "||":"TruncRound"}
variables = {}
constants = {}
sequence = []
section_name = []
output = []
all_vars = {} #A list of all variables used and created, useful for generating the variable block
index = -1

section_break = """\n'=========================================\n"""


def findOp(string):
	for key in keywords:
		if string.find(key) != -1:
			return key
	return ""

def multipleReplace(text, wordDictA): #Found here, but modified: http://stackoverflow.com/questions/2400504/easiest-way-to-replace-a-string-using-a-dictionary-of-replacements
	for keyA in wordDictA:
		text = text.replace(keyA, wordDictA[keyA])        
	return text



#In part from Here: http://stackoverflow.com/questions/4284991/parsing-nested-parentheses-in-python-grab-content-by-level
def parenthetic_contents(lhs, string):
#    """Generate parenthesized contents in string as pairs (level, contents)."""
	stack = []

	azm_temp_count = 0
	
	subsets = {} #Contains entries in the form    (var_name : expression (w/ parenthesis))
	
#	keyword_re = re.compile("|".join(map(re.escape, keywords)))
	
	global section_name

	for i, c in enumerate(string):
		if c == '(':
			stack.append(i)
		elif c == ')' and stack:
			start = stack.pop()
#			yield (len(stack), string[start + 1: i])
			
			
			rhs = string[start + 1: i]
			
#			print "rhs =", rhs
			

			while 1:
				old_rhs = rhs
				rhs = multipleReplace(rhs, subsets)
				
				if rhs == old_rhs:
					break #aka, no more changes madep

			operation = findOp(rhs)
	
			if operation == "":
				subsets["(" + rhs + ")"] = rhs #For expressions such as "(var)"
				continue #aka, no operands on this side... 
			
			var1, var2 = rhs.split(operation)
			
			
			#Figure out if the number is a constant, and if it is then replace it with a "constant" variable
			try:
				num_value = int(var1)
				var1 = "const_" + str(num_value)
				variables[var1] = var1
				const_line = var1 + " := float(" + str(num_value) + ")"
				constants[const_line] = const_line
				
				
			except ValueError:
				pass
			
			try:
				num_value = int(var2)
				var2 = "const_" + str(num_value)
				variables[var2] = var2
				const_line = var2 + " := float(" + str(num_value) + ")"
				constants[const_line] = const_line
				
				
			except ValueError:
				pass
				
			#Figure out if the number is pi, then replace as appropriate
			if var1.find("pi") != -1:
				var1 = "const_pi"
				variables["const_pi"] = "const_pi"
				const_line = "const_pi := pi"
				constants[const_line] = const_line
				
			if var2.find("pi") != -1:
				var2 = "const_pi"
				variables["const_pi"] = "const_pi"
				const_line = "const_pi := pi"
				constants[const_line] = const_line
			
			
			line_components = {}
			line_components["section_name"] = section_name[-1]
			
			#These two if statements allow for putting in function calls instead of variable addresses. Note that the function calls should return addresses
			if var1.find(".") == -1: #Not found
				var1 = "@" + var1
			if var2.find(".") == -1: #Not found
				var2 = "@" + var2
			
			line_components["var1"] = var1
			line_components["var2"] = var2
#			line_components["result"] = "azm_temp_" + str(azm_temp_count)
			line_components["operation"] = keywords[operation]
			
			all_vars[var1] = var1
			all_vars[var2] = var2
			
			#Print parsing result:				
			if len(stack) != 0:
				line_components["result"] = "azm_temp_" + str(azm_temp_count)
				variables["azm_temp_" + str(azm_temp_count)] = "azm_temp_" + str(azm_temp_count)
				
				all_vars["azm_temp_" + str(azm_temp_count)] = "azm_temp_" + str(azm_temp_count)
				
				sequence.append( "\t'azm_temp_" + str(azm_temp_count) + " = " + var1 + " " + operation + " " + var2)
			else:
				line_components["result"] = lhs
				sequence.append("\t'" + lhs + " = " + var1 + " " + operation + " " + var2)			
				all_vars[lhs] = lhs
			
			
			sequence.append("\n\tfp.AddInstruction({section_name}_INDEX, fp#FP{operation}, {var1}, {var2}, @{result})\n".format(**line_components))
			global line_count
			line_count += 1
			

		
			subsets["(" + rhs + ")"] = "azm_temp_" + str(azm_temp_count)	
			subsets["(" + "azm_temp_" + str(azm_temp_count) + ")"] = "azm_temp_" + str(azm_temp_count)
			

				
			azm_temp_count += 1
			
	

def main():
	if len(sys.argv) != 3:
		print "Usage: math_processor.py <input_filename> <output_filename>"
		return -1

	f = open(sys.argv[1])
	lines = f.readlines()

	found_azm_math = False
	found_azm_func = False

	global section_name

	for line in lines:
		#Test for begining of block
#		if found_azm_math == False:
#			if line[:10] != "{{AZM_MATH":
#				output.append(line)
#				continue
#			else:
#				section_name = (line[11:]).strip()
#				found_azm_math = True
#				output.append(section_break)
#				output.append("\n\nPUB CreateInstructionSequence")
#				continue

#		#Test for end of block			
#		else: #if found_azm_math == True:
#			if string.strip(line) == "}}":
#				found_azm_math = False
#				output.append("\n\tSetConstants 'Call the function")
#				output.append(section_break)
#				continue
#		
		
		if line[:10] == "{{AZM_MATH":
			found_azm_math = True
			section_name.append((line[11:]).strip())
			global index
			index += 1
			global line_count
			line_count = 0
			con.append(section_name[-1] + "_INDEX = " + str(index))
			continue
			
		elif line[:10] == "{{AZM_FUNC":
			found_azm_funct = True
			#TO_DO: Do stuff (like print the functions!
			
			continue
		elif string.strip(line) == "}}" and (found_azm_func == True or found_azm_math == True):
			if found_azm_math == True:
				section_var = section_name[-1] + "_INSTRUCTIONS[(4 * " + str(line_count) + ") + 1]"
				variables[section_var] = section_var
			found_azm_math = False
			found_azm_func = False
			continue
			
		if found_azm_math == False:
			output.append(line)
			continue
			
		if len(line.strip()) == 0: #Is it whitespace?
			continue				 #Ignore empty lines
			
		if line.strip()[0] == "'": #Allow for line to be commented out
			sequence.append(line)  #Save comment for future review,
			continue			   #But don't do anything with it...
		
			
		#Else, at this point line is from the azm math section
		sequence.append("\n'------------\n") #Output a visual break line
		sequence.append("'' " + line)      #Output the line as a comment
	

		#TODO: put this in a try block. If it fails, multiple = signs
		lhs, rhs = line.split("=")
	
		lhs = string.strip(lhs)
		rhs = "(" + string.strip(rhs).replace(" ", "") + ")"
		parenthetic_contents(lhs, rhs)
	
	
	
	
	
	
	output.append(section_break)
	
	#Output the con block (indexes)
	output.append("\n\nCON")
	for item in con:
		output.append("\n\t" + item)
	
	#Output the variables
	output.append("\n\nVAR")
	for item in sorted(variables.values()):
		output.append("\n\tlong " + item)

	#Output the constant populating code
	output.append("\n\nPUB Init_Instructions\n")
	
	for item in section_name:
		output.append("\n\tfp.AddSequence(" + item + "_INDEX, @" + item + "_Instructions)\n")
	for item in sorted(constants.values()):
		output.append("\n\t" + item)
		
	for item in sequence:
		output.append(item)
	
	#Output all the vars:
	output.append("'All variables that are used or created:")
	for item in sorted(all_vars.values()):
		output.append("\n'\tlong " + item)
		
	output.append(section_break)
	
	
	f.close() #Stop reading
	f = open(sys.argv[2], 'w')
	for t in output:
		f.write(t)
#		print t.rstrip("\n")
	f.close()
	
	
	
if __name__ == "__main__":
	main()
		
	
	
	
	
	
	
	
	
