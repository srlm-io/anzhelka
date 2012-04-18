#!/usr/bin/python
import wx
#from anzhelka_terminal_gui import MyFrame



import os
import pprint
import random
import sys
import wx



# The recommended way to use wx with mpl is with the WXAgg
# backend. 
#



#Data comes from here
#from Arduino_Monitor import SerialData as DataGen
from anzhelka_terminal_serial import *
from anzhelka_terminal_gui_extra import *






def reverseenum(string, l):
	#returns the index value based on the string passed in
	for i in range(len(l)):
		if string == l[i]:
			return i
	return -1 #no match

def handler_terminal_pause_main(self, event):
	print("I'm handling the event!")
	event.Skip()



if __name__ == "__main__":

	print('Note: this is not (yet?) meant to be run stand alone. Please run the following instead:')
	print('./anzhelka_terminal_gui.py')
	
	

#    app = wx.PySimpleApp(0)
#    wx.InitAllImageHandlers()
#    main_frame = MyFrame(None, -1, "")
#    app.SetTopWindow(main_frame)
#    main_frame.Show()
#    
#    for i in range(30):
#      main_frame.text_ctrl_1.AppendText(str(i))
#      main_frame.text_ctrl_1.AppendText('-Hello World!\n')
#    
#    app.MainLoop()
    
    


#def main():
#    app = wx.PySimpleApp(0)
#    wx.InitAllImageHandlers()
#    
#    global main_frame

#    
#    app.SetTopWindow(main_frame)
#    
##    login_frame = LoginDialog(None, -1, "")
##    login_frame.Center(wx.CENTER_ON_SCREEN)
##    
##    alert_frame = AlertDialog(None, -1, "")
##    alert_frame.Center(wx.CENTER_ON_SCREEN)
##    
##    
##    setup_general(main_frame)
##    #setup_user(main_frame)
##    
##    login_frame.Show()
#    #main_frame.Show()
#    app.MainLoop()
#    
#    
#if __name__ == "__main__":
#    print "in main..."
#    main()
