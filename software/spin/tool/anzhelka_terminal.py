#!/usr/bin/python
#import wx
#from anzhelka_terminal_gui import MyFrame


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
