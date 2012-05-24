#!/usr/bin/python

#--------------------------------------------------------------------------------
#Anzhelka Project
#(c) 2012

#For the latest code and support, please visit:
#http://code.anzhelka.com
#--------------------------------------------------------------------------------

#Title: quat_replace.py
#Author: Cody Lewis
#Date: May 22, 2012
#Notes:

import sys
import string
import re


quatMul = """
w0 = ((w1*w2) - (x1*x2)) - ((y1*y2) - (z1*z2))
x0 = ((w1*x2) + (x1*w2)) + ((y1*z2) - (z1*y2))
y0 = ((w1*y2) - (x1*z2)) + ((y1*w2) + (z1*x2))
z0 = ((w1*z2) + (x1*y2)) - ((y1*x2) + (z1*w2))
"""

wordDict = {}

def addquat(index, w,x,y,z):
	wordDict["w"+ str(index)] = w
	wordDict["x"+ str(index)] = x
	wordDict["y"+ str(index)] = y
	wordDict["z"+ str(index)] = z

def multipleReplace(text, wordDictA): #Found here, but modified: http://stackoverflow.com/questions/2400504/easiest-way-to-replace-a-string-using-a-dictionary-of-replacements
	for keyA in wordDictA:
		text = text.replace(keyA, wordDictA[keyA])        
	return text



def main():

	
	global wordDict
	
	
 	print "'Moment Block, first Quat Mul"
	addquat(0,	"q_tilde_0", "q_tilde_1","q_tilde_2","q_tilde_3")
	addquat(1,	"q_d_0", "q_d_1",	"q_d_2", 	"q_d_3")
	addquat(2,	"q_0", "q_1",		"q_2",		"q_3")
	print multipleReplace(quatMul, wordDict)
	wordDict = {}
	
	
	print "'Moment Block, r_b first (lhs) quat mult:"
	addquat(0,	"q_temp_0", "q_temp_1",	"q_temp_2",	"q_temp_3")
	addquat(1,	"q_0", "q_1",		"q_2",		"q_3")
	addquat(2,	"0",	"r_e_1", 	"r_e_2",	"r_e_3")
	print multipleReplace(quatMul, wordDict)
	wordDict = {}
	
	print "'Moment Block, r_b second (rhs) quat mult:"
	addquat(1,	"q_temp_0", "q_temp_1",	"q_temp_2",	"q_temp_3")
	addquat(2,	"q_0", "q_1",		"q_2",		"q_3")
	addquat(0,	"0",	"r_b_1", 	"r_b_2",	"r_b_3")
	print multipleReplace(quatMul, wordDict)
	wordDict = {}
	

if __name__ == "__main__":
	main()
