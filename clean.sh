#!/bin/bash

#(c)2012 Anzhelka Project

#This script will clean up the directory of any temporary files. Useful to
#run before a git add command as it reduces the amount of noise. Ensures that
#useless files are not added to the repo.

#Meant to be run from the anzhelka/ directory
#  $> ./clean.sh


tilde="find . -type f | grep '~'$ | xargs rm -v 2> /dev/null"
aux="find . -type f | grep '.aux'$ | xargs rm -v 2> /dev/null"
log="find . -type f | grep '.log'$ | xargs rm -v 2> /dev/null"
out="find . -type f | grep '.out'$ | xargs rm -v 2> /dev/null"
synctex="find . -type f | grep '.synctex.gz'$ | xargs rm -v 2> /dev/null"
toc="find . -type f | grep '.toc'$ | xargs rm -v 2> /dev/null"

#echo $tilde
eval $tilde
if [ $? -ne 0 ]; then
   echo "No *~ deletes."
fi



#echo $aux
eval $aux
if [ $? -ne 0 ]; then
   echo "No *.aux deletes."
fi


#echo $log
eval $log
if [ $? -ne 0 ]; then
   echo "No *.log deletes."
fi


#echo $out
eval $out
if [ $? -ne 0 ]; then
   echo "No *.out deletes."
fi


#echo $synctex
eval $synctex
if [ $? -ne 0 ]; then
   echo "No *.synctex.gz deletes."
fi


#echo $toc
eval $toc
if [ $? -ne 0 ]; then
   echo "No *.toc deletes."
fi





# Left over from the BST compile script, may be useful later...
##if [ $# -eq 0 ] ; then
#	echo "Usage: $0 [Top Level Spin File Path]"
#	exit 1
#fi

#echo
#echo

#./tool/bstc.linux -f -p0 -l -L lib  $1 > bstoutput.txt
#cat bstoutput.txt

#grep -q "Error" bstoutput.txt
#if [ $? -eq 0 ]; then
#   echo Found Error!
#else
#   echo ----------------------------------------------------------
#   echo No compiler errors...
#   
#   grep -q "No Propeller detected on" bstoutput.txt
#   if [ $? -eq 0 ]; then
#      echo Could not find Propeller chip...
#   else
#   
#      echo
#      echo
#      echo To exit picocom, type C-A then C-X
#      echo
#      rm bstoutput.txt
#      
#      port=$(ls /dev/*USB*)
#      #echo $port
#      picocom -b 115200 $port
#   fi
#fi

#rm bstoutput.txt



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

