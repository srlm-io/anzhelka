#!/bin/bash

#(c)2012 Anzhelka Project

#This script will compile, download, and open a terminal
#If any errors are encountered then it will stop at the appropriate point.

#Meant to be run from the /spin directory
#  $> tool/compile src/[filename].spin





if [ $# -eq 0 ] ; then
	echo "Usage: $0 [Top Level Spin File Path][--list [block number | objectname]]"
	exit 1
fi

#Extract the filename without extension:
filename=$(basename $1)
extension=${filename##*.}
filename=${filename%.*}

echo
echo

./tool/bstc.linux -f -p0 -l -L lib  $1 > bstoutput.txt
cat bstoutput.txt

grep -q "Error" bstoutput.txt
if [ $? -eq 0 ]; then
	echo Found Error!
else
	echo ----------------------------------------------------------
	echo No compiler errors...

	grep -q "No Propeller detected on" bstoutput.txt
	if [ $? -eq 0 ]; then
		echo Could not find Propeller chip...
	else
   
   		
		echo
		echo
		echo To exit picocom, type C-A then C-X
		echo
		rm bstoutput.txt
		
		if [ $2 == "--list" ] ; then
			if [ $# -gt 2 ]; then
			gnome-terminal --geometry=142x60 -x ./tool/listgrep.py $filename.list $3
			else
				gnome-terminal --geometry=142x60 -x ./tool/listgrep.py $filename.list
			fi
		else
			echo "Currently, the argument in position 2 must be --list."
		fi
			
		
		port=$(ls /dev/*USB*)
		#echo $port
		picocom -b 115200 $port
	fi
fi

rm bstoutput.txt



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

