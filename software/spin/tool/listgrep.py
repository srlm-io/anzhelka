#!/usr/bin/python

#--------------------------------------------------------------------------------
#Anzhelka Project
#(c) 2012

#For the latest code and support, please visit:
#http://code.anzhelka.com
#--------------------------------------------------------------------------------

#Title: listgrep.py
#Author: Cody Lewis
#Date: May 1, 2012
#Notes: This program will automatically parse the BSTC *.list files for the assembly code.


# gnome-terminal (and others?) command to set the tab stops:
# tabs 5,9,13,17,21,25,29,33,37,41,45,49,53,57,61,65,69,73,77,81,85,89,93




import re
import sys

divider = """

|***************************************************************************|
|***************************************************************************|

"""

MAX_OBJECT_NAME_LENGTH = 100
TAB_SIZE = 4 # Four spaces per tab
BSTC_TAB_SIZE = 8 # The listing output tab size

if(len(sys.argv) == 1):
	print "Usage: ", sys.argv[0], " filename [block number | objectname] "
	sys.exit(1)
	

data=open(sys.argv[1]).read()

#The below says match anything that says "Object" followed by up to 100 chars, then Object base, then up to 5000 chars, then "Object DAT Blocks", then the assembly
result=re.compile("""(Object.{0,100}?Object Base.{0,5000}?Object DAT Blocks\n.*?)\n\|==========""",re.M|re.DOTALL).findall(data)

if(len(sys.argv) == 2): #Display all the objects
	for item in result:
		print divider
		print item
		raw_input("Press Enter to continue...")
else: #Display the object(s) specified as parameter
	#Determine if the argument is a object number or name
	try:
		print result[int(sys.argv[2])]
	except ValueError:
		#May be multiple matches.
		for item in result:
			if item.find(sys.argv[2], 0, MAX_OBJECT_NAME_LENGTH) != -1 :
				print divider
				
#				#Original two lines:
#				print item
#				raw_input("Press Enter to continue...")

				#Added special support for tab space correction
				#Must count number of contiguous spaces, assumes anything more than 1 is a tab
				lines = item.split("\n")
				for line in lines:
					white_count = 0
					output = ""
					for char in list(line)[:25]:
						output += char #Ignore the first 25 characters
					output += '   ' #Makes the header fit into the tab stops
					for char in list(line)[25:]:
						if char == ' ':
							white_count += 1
						else:
							if white_count > 1:
								numtabs = int(white_count) / BSTC_TAB_SIZE
								if white_count - (numtabs * BSTC_TAB_SIZE) != 0: #Should be the same as mod (%), but you never know...
									numtabs += 1
								for temp in range(numtabs):
									output += "\t"
#									for space in range(TAB_SIZE):
#										output += ' '
							elif white_count == 1:
								output += ' '
									
							white_count = 0
							output += char
							
					
					print output
				raw_input("Press Enter to continue...")
					



print "Number of assembly objects in compiled program:", len(result)
print ""
raw_input("Press Enter to exit...")


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



