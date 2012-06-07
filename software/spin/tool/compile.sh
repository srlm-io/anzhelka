#!/bin/bash

#--------------------------------------------------------------------------------
#Anzhelka Project
#(c) 2012

#For the latest code and support, please visit:
#http://code.anzhelka.com
#--------------------------------------------------------------------------------

#Title: compile.sh
#Author: Cody Lewis
#Date: May 23, 2012
#Notes:



#This script will compile, download, and open a terminal
#If any errors are encountered then it will stop at the appropriate point.

#Meant to be run from the /spin directory
#  $> tool/compile src/[filename].spin

# For the main.spin file, it should be run as follows:
# ./tool/math_processor.py src/main.spin src/main_output.spin; cat src/anzhelka_support_functions.spin >> src/main_output.spin; ./tool/compile.sh src/main_output.spin


baud="115200"
#baud="230400"

if [ $# -eq 0 ] ; then
#	echo "Usage: $0 [Top Level Spin File Path][--list [block number | objectname]]"
	echo "Usage: $0 filename [--functions|--mathfunctions]"
	exit 1
fi

compilefile=$1

#Extract the filename without extension:
filename=$(basename $1)
extension=${filename##*.}
filename=${filename%.*}

#Extract the path
path=$(dirname $1)


#Set the tab stops, useful for when displaying the listing
tabs 5,9,13,17,21,25,29,33,37,41,45,49,53,57,61,65,69,73,77,81,85,89,93,97,101,105,109,113,117,121,125,129,133,137,141,145,149,153,157,161,165,169,173


#Set the compile_time
date > $path/compile_time.dat

echo "Compile Time:"
cat $path/compile_time.dat
echo



if [ "$2" = "--functions" ] ; then
	if [ "$path" != "" ] ; then
		cat $1 > "$path"/"$filename"_output."$extension"
		cat src/anzhelka_support_functions.spin >> "$path"/"$filename"_output."$extension"
		cat src/anzhelka_variables.spin >> "$path"/"$filename"_output."$extension"
		compilefile="$path"/"$filename"_output."$extension"
	else
		cat $1 > "$filename"_output."$extension"
		cat src/anzhelka_support_functions.spin >> "$filename"_output."$extension"
		cat src/anzhelka_variables.spin >> "$filename"_output."$extension"
		compilefile="$filename"_output."$extension"
	fi
elif [ "$2" = "--mathfunctions" ] ; then
	if [ "$path" != "" ] ; then
#		cat $1 > "$path"/"$filename"_output."$extension"
		echo "Compiling with non-local file --mathfunctions"
		rm "$path"/"$filename"_output."$extension"
		./tool/math_processor.py $1 "$path"/"$filename"_output."$extension"
		cat src/anzhelka_support_functions.spin >> "$path"/"$filename"_output."$extension"
		cat src/anzhelka_variables.spin >> "$path"/"$filename"_output."$extension"
		compilefile="$path"/"$filename"_output."$extension"
	else
#		cat $1 > "$filename"_output."$extension"
		./tool/math_processor.py $1 "$filename"_output."$extension"
		cat src/anzhelka_support_functions.spin >> "$filename"_output."$extension"
		cat src/anzhelka_variables.spin >> "$filename"_output."$extension"
		compilefile="$filename"_output."$extension"
	fi
fi

#Compile based on port selection
# - USB
# - Wixel
port=$(ls /dev/*USB* 2> /dev/null)
if [ "$port" != "" ] ; then
	#Download with USB port...
	#Changes: uses the -f (fast download) option
	./tool/bstc.linux -f -p0 -d $port -Ox -l -w1 -L src -L test -L lib -L lib/bma $compilefile > bstoutput.txt
else
	port=$(ls /dev/ttyACM* 2> /dev/null)
	if [ "$port" = "" ] ; then
		echo
		echo "Could not find Propeller on /dev/*USB* or /dev/ttyACM*"
		echo
		exit 1
	else
		#Download with Wixel port
		#Downloads to EEPROM and runs
		#If it doesn't download to EEPROM then the wixel will reset the Propeller
		./tool/bstc.linux -p2 -d $port -Ox -l -w1 -L src -L test -L lib -L lib/bma $compilefile > bstoutput.txt	
	fi
fi


#Open Terminal if successful compilation

#cat bstoutput.txt

grep -q "Error" bstoutput.txt
if [ $? -eq 0 ]; then
	cat bstoutput.txt
else
	

	grep -q "No Propeller detected on" bstoutput.txt
	if [ $? -eq 0 ]; then
		echo "Could not find Propeller chip..."
		cat bstoutput.txt
	else   		
#		echo
#		echo
#		echo To exit picocom, type C-A then C-X
#		echo
#		rm bstoutput.txt
		
#		if [ "$2" = "--list" ] ; then #Quotes around the $2 to make a binary operator (http://linuxcommand.org/wss0100.php)
#			if [ $# -gt 2 ]; then
#			gnome-terminal --geometry=142x60 -x ./tool/listgrep.py $filename.list $3
#			else
#				gnome-terminal --geometry=142x60 -x ./tool/listgrep.py $filename.list
#			fi
#		else
#			echo ""
#			#echo "Currently, the argument in position 2 must be --list."
#		fi
			
		
		
		#echo $port
#		picocom --send-cmd "cat" -b $baud $port
		picocom --send-cmd "ascii-xfr -s -c 0" -b $baud $port
	fi
fi

rm bstoutput.txt
rm $path/compile_time.dat



#Code that may be useful later...


#           OPTIONS="Hello Quit"
#           select opt in $OPTIONS; do
#               if [ "$opt" = "Quit" ]; then
#                echo done
#                exit
#               elif [ "$opt" = "Hello" ]; then
#                echo Hello World
#               else
#                clear
#                echo bad option
#               fi
#           done

#echo "Before getopt"
#for i
#do
#  echo $i
#done
#args=`getopt abc:d $*`
#set -- $args
#echo "After getopt"
#for i
#do
#  echo "-->$i"
#done

#while getopts  "abc:" flag
#do
#  echo "$flag" $OPTIND $OPTARG
#done






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


