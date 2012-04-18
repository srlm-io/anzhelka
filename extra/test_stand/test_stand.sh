#!/bin/bash

#(c)2012 Anzhelka Project

#This script will compile, download, and open a terminal
#If any errors are encountered then it will stop at the appropriate point.

#Meant to be run from the /spin directory
#  $> tool/bst_mpu6050.sh




echo
echo

../../software/spin/tool/bstc.linux -f -p0 -L ../../software/spin/lib  test_stand.spin > output.txt
cat output.txt

grep -q "Error" output.txt
if [ $? -eq 0 ]; then
   echo Found Error!
else
   echo ----------------------------------------------------------
   echo No compiler errors...
   
   grep -q "No Propeller detected on" output.txt
   if [ $? -eq 0 ]; then
      echo Could not find Propeller chip...
   else
   
      echo
      echo
      echo To exit picocom, type C-A the C-X
      echo
   
      picocom -b 115200 /dev/ttyUSB0
   fi
fi




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
