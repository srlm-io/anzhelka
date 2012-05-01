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







import re
import sys

divider = """

|***************************************************************************|
|***************************************************************************|

"""

MAX_OBJECT_NAME_LENGTH = 100


if(len(sys.argv) == 1):
	print "Usage: ", sys.argv[0], " filename [block number | objectname] "
	sys.exit(1)
	

data=open(sys.argv[1]).read()

#The below says match anything that says "Object" followed by up to 800 chars, then "Object DAT Blocks", then the assembly
result=re.compile("""(Object.{0,800}?Object DAT Blocks\n.*?)\n\|==========""",re.M|re.DOTALL).findall(data)

if(len(sys.argv) == 2):
	for item in result:
		print divider
		print item
		raw_input("Press Enter to continue...")
else:
	#Determine if the argument is a object number or name
	try:
		print result[int(sys.argv[2])]
	except ValueError:
		#May be multiple matches.
		for item in result:
			if item.find(sys.argv[2], 0, MAX_OBJECT_NAME_LENGTH) != -1 :
				print divider
				print item
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



