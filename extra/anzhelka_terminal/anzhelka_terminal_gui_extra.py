#!/usr/bin/python

#To profile code use the following command:
# python -m cProfile -s calls ./tool/anzhelka_terminal_gui.py



#A bug to deal with later:
#Traceback (most recent call last):
#  File "/home/clewis/class/ee175/anzhelka/software/spin/tool/anzhelka_terminal_gui_extra.py", line 313, in on_redraw_timer
#    self.draw_plot()
#  File "/home/clewis/class/ee175/anzhelka/software/spin/tool/anzhelka_terminal_gui_extra.py", line 202, in draw_plot
#    ymin = round(min(self.data), 0) - 1
#ValueError: min() arg is an empty sequence




import wx
import matplotlib
matplotlib.use('WXAgg')
from matplotlib.figure import Figure
from matplotlib.backends.backend_wxagg import \
	FigureCanvasWxAgg as FigCanvas, \
	NavigationToolbar2WxAgg as NavigationToolbar
import pylab
import numpy as np
from anzhelka_terminal_serial import *

REFRESH_INTERVAL_MS = 50
paused = False

motor_num = 4
motor_settings = ["Motor", "RPS", "DRPM", "Volts", "Amps", "ESC(uS)", "Thrust", "Torque", "KP", "KI", "KD"]


class BoundControlBox(wx.Panel):
	""" A static box with a couple of radio buttons and a text
		box. Allows to switch between an automatic mode and a 
		manual mode with an associated value.
	"""
	def __init__(self, parent, ID, label, initval):
		wx.Panel.__init__(self, parent, ID)
		
		self.value = initval
		

		
		box = wx.StaticBox(self, -1, label)
		sizer = wx.StaticBoxSizer(box, wx.VERTICAL)
		
		self.radio_auto = wx.RadioButton(self, -1, 
			label="Auto", style=wx.RB_GROUP)
		self.radio_manual = wx.RadioButton(self, -1,
			label="Manual")
		self.manual_text = wx.TextCtrl(self, -1, 
			size=(35,-1),
			value=str(initval),
			style=wx.TE_PROCESS_ENTER)
		
		self.Bind(wx.EVT_UPDATE_UI, self.on_update_manual_text, self.manual_text)
		self.Bind(wx.EVT_TEXT_ENTER, self.on_text_enter, self.manual_text)
		
		manual_box = wx.BoxSizer(wx.HORIZONTAL)
		manual_box.Add(self.radio_manual, flag=wx.ALIGN_CENTER_VERTICAL)
		manual_box.Add(self.manual_text, flag=wx.ALIGN_CENTER_VERTICAL)
		
		sizer.Add(self.radio_auto, 0, wx.ALL, 10)
		sizer.Add(manual_box, 0, wx.ALL, 10)
		
		self.SetSizer(sizer)
		sizer.Fit(self)
	
	def on_update_manual_text(self, event):
		self.manual_text.Enable(self.radio_manual.GetValue())
	
	def on_text_enter(self, event):
		self.value = self.manual_text.GetValue()
	
	def is_auto(self):
		return self.radio_auto.GetValue()
		
	def manual_value(self):
		return self.value


class RPMGraph(wx.Panel):
#	""" The main frame of the application
#	"""
#	title = 'Demo: dynamic matplotlib graph'
	
	def __init__(self, arg1, arg2, datagen):
		wx.Panel.__init__(self, arg1, -1)

		self.rx_last_read = 0
#		self.datagen = DataGen()
		self.datagen = datagen
#		self.data = [self.datagen.next()]
		self.data = []
		paused = False
		
		
#		self.create_menu()
#		self.create_status_bar()
#		self.create_main_panel()

		self.redraw_timer = wx.Timer(self)
		self.Bind(wx.EVT_TIMER, self.on_redraw_timer, self.redraw_timer)		
		self.redraw_timer.Start(REFRESH_INTERVAL_MS)

#	def create_menu(self):
#		self.menubar = wx.MenuBar()
#		
#		menu_file = wx.Menu()
#		m_expt = menu_file.Append(-1, "&Save plot\tCtrl-S", "Save plot to file")
#		self.Bind(wx.EVT_MENU, self.on_save_plot, m_expt)
#		menu_file.AppendSeparator()
#		m_exit = menu_file.Append(-1, "E&xit\tCtrl-X", "Exit")
#		self.Bind(wx.EVT_MENU, self.on_exit, m_exit)
#				
#		self.menubar.Append(menu_file, "&File")
#		self.SetMenuBar(self.menubar)

#	def create_main_panel(selfi):
#		self.panel = wx.Panel(self)

		self.init_plot()
		self.canvas = FigCanvas(self, -1, self.fig)

		self.xmin_control = BoundControlBox(self, -1, "X min", 0)
		self.xmax_control = BoundControlBox(self, -1, "X max", 50)
		self.ymin_control = BoundControlBox(self, -1, "Y min", 0)
		self.ymax_control = BoundControlBox(self, -1, "Y max", 100)


		self.pause_button = wx.Button(self, -1, "Pause")
		self.Bind(wx.EVT_BUTTON, self.on_pause_button, self.pause_button)
		self.Bind(wx.EVT_UPDATE_UI, self.on_update_pause_button, self.pause_button)

		self.cb_grid = wx.CheckBox(self, -1, 
			"Show Grid",
			style=wx.ALIGN_RIGHT)
		self.Bind(wx.EVT_CHECKBOX, self.on_cb_grid, self.cb_grid)
		self.cb_grid.SetValue(True)
		
		self.cb_xlab = wx.CheckBox(self, -1, 
			"Show X labels",
			style=wx.ALIGN_RIGHT)
		self.Bind(wx.EVT_CHECKBOX, self.on_cb_xlab, self.cb_xlab)		
		self.cb_xlab.SetValue(True)
		

		self.hbox1 = wx.BoxSizer(wx.HORIZONTAL)
		self.hbox1.Add(self.pause_button, border=5, flag=wx.ALL | wx.ALIGN_CENTER_VERTICAL)
		self.hbox1.AddSpacer(20)
		self.hbox1.Add(self.cb_grid, border=5, flag=wx.ALL | wx.ALIGN_CENTER_VERTICAL)
		self.hbox1.AddSpacer(10)
		self.hbox1.Add(self.cb_xlab, border=5, flag=wx.ALL | wx.ALIGN_CENTER_VERTICAL)
		
		self.hbox2 = wx.BoxSizer(wx.HORIZONTAL)
		self.hbox2.Add(self.xmin_control, border=5, flag=wx.ALL)
		self.hbox2.Add(self.xmax_control, border=5, flag=wx.ALL)
		self.hbox2.AddSpacer(24)
		self.hbox2.Add(self.ymin_control, border=5, flag=wx.ALL)
		self.hbox2.Add(self.ymax_control, border=5, flag=wx.ALL)

		self.vbox = wx.BoxSizer(wx.VERTICAL)
		self.vbox.Add(self.canvas, 1, flag=wx.LEFT | wx.TOP | wx.GROW)		
		self.vbox.Add(self.hbox1, 0, flag=wx.ALIGN_LEFT | wx.TOP)
		self.vbox.Add(self.hbox2, 0, flag=wx.ALIGN_LEFT | wx.TOP)
		
		self.SetSizer(self.vbox)
		self.vbox.Fit(self)
	
#	def create_status_bar(self):
#		self.statusbar = self.CreateStatusBar()

	def init_plot(self):
		self.dpi = 100
		self.fig = Figure((3.0, 3.0), dpi=self.dpi)

		self.axes = self.fig.add_subplot(111)
		self.axes.set_axis_bgcolor('black')
		self.axes.set_title('RPM Serial Data', size=12)
		
		pylab.setp(self.axes.get_xticklabels(), fontsize=8)
		pylab.setp(self.axes.get_yticklabels(), fontsize=8)

		# plot the data as a line series, and save the reference 
		# to the plotted line series
		#
		self.plot_data = self.axes.plot(
			self.data, 
			linewidth=1,
			color=(1, 1, 0),
			)[0]

	def draw_plot(self):
		""" Redraws the plot
		"""
		# when xmin is on auto, it "follows" xmax to produce a 
		# sliding window effect. therefore, xmin is assigned after
		# xmax.
		#
		if self.xmax_control.is_auto():
			xmax = len(self.data) if len(self.data) > 50 else 50
		else:
			xmax = int(self.xmax_control.manual_value())
			
		if self.xmin_control.is_auto():			
			xmin = xmax - 1000
		else:
			xmin = int(self.xmin_control.manual_value())

		# for ymin and ymax, find the minimal and maximal values
		# in the data set and add a mininal margin.
		# 
		# note that it's easy to change this scheme to the 
		# minimal/maximal value in the current display, and not
		# the whole data set.
		# 
		if self.ymin_control.is_auto():
			ymin = round(min(self.data), 0) - 1
		else:
			ymin = int(self.ymin_control.manual_value())
		
		if self.ymax_control.is_auto():
			ymax = round(max(self.data), 0) + 1
		else:
			ymax = int(self.ymax_control.manual_value())

		self.axes.set_xbound(lower=xmin, upper=xmax)
		self.axes.set_ybound(lower=ymin, upper=ymax)
		
		# anecdote: axes.grid assumes b=True if any other flag is
		# given even if b is set to False.
		# so just passing the flag into the first statement won't
		# work.
		#
		if self.cb_grid.IsChecked():
			self.axes.grid(True, color='gray')
		else:
			self.axes.grid(False)

		# Using setp here is convenient, because get_xticklabels
		# returns a list over which one needs to explicitly 
		# iterate, and setp already handles this.
		#  
		pylab.setp(self.axes.get_xticklabels(), 
			visible=self.cb_xlab.IsChecked())
		
#		temp = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
		
		self.plot_data.set_xdata(np.arange(len(self.data)))
		self.plot_data.set_ydata(np.array(self.data))
#		self.plot_data.set_xdata(np.arange(len(temp)))
#		self.plot_data.set_ydata(np.array(temp))
		
		
		self.canvas.draw()
	
	def on_pause_button(self, event):
		global paused
		paused = not paused
	
	def on_update_pause_button(self, event):
		label = "Resume" if paused else "Pause"
		self.pause_button.SetLabel(label)
	
	def on_cb_grid(self, event):
		self.draw_plot()
	
	def on_cb_xlab(self, event):
		self.draw_plot()
	
	def on_save_plot(self, event):
		file_choices = "PNG (*.png)|*.png"
		
		dlg = wx.FileDialog(
			self, 
			message="Save plot as...",
			defaultDir=os.getcwd(),
			defaultFile="plot.png",
			wildcard=file_choices,
			style=wx.SAVE)
		
		if dlg.ShowModal() == wx.ID_OK:
			path = dlg.GetPath()
			self.canvas.print_figure(path, dpi=self.dpi)
			self.flash_status_message("Saved to %s" % path)
	
	
	
	
	
	
#	def serial_parse_ADRPS(self, line):
#		#Returns a list with the four motor speeds, or an empty list
#		if line.find("$ADRPS ") != -1: #String matches
#			line = line[8:] #Get rid of "$ADRPS "
#			nums = line.split(",")
#			try:
#				for i in range(len(nums)):
#					nums[i] = float(nums[i])
#			except ValueError:
#				print "Could not parse $ADRPS String"
#				return []
#				
#			return nums
#		else:
#			return []
		
	
	def on_redraw_timer(self, event):
		# if paused do not add data, but still redraw the plot
		# (to respond to scale modifications, grid change, etc.)
		#
		global rx_buffer_lock
		global rx_buffer
		global serial_parse_ADRPS
		
		rxparser = RxParser()
		
		if not paused:
			if not rx_buffer_lock.acquire(False):
				pass
			else:
				try:
					i = 0
					#Go through all the received strings and add whatever is relevant.
					
					while self.rx_last_read < len(rx_buffer):
#						print "self.rx_last_read == ", self.rx_last_read
#						print "len(rx_buffer) == ", len(rx_buffer)		
#						print "Reading last i == ", i
#						i += 1
						motor_rps = rxparser.match(rx_buffer[self.rx_last_read], "$ADRPS")
						self.rx_last_read += 1
						if len(motor_rps) != 0:
							self.data.append(float(motor_rps[0])) #Get first motor RPS...

				finally:
					rx_buffer_lock.release()

		
		self.draw_plot()
	
	
	
	
	
	
	
	
	
	def on_exit(self, event):
		self.Destroy()
		
	
	def flash_status_message(self, msg, flash_len_ms=1500):
		self.statusbar.SetStatusText(msg)
		self.timeroff = wx.Timer(self)
		self.Bind(
			wx.EVT_TIMER, 
			self.on_flash_status_off, 
			self.timeroff)
		self.timeroff.Start(flash_len_ms, oneShot=True)
	
	def on_flash_status_off(self, event):
		self.statusbar.SetStatusText('')


class AdjustmentTableSizer(wx.Panel):
	def __init__(self, parent, id):
		wx.Panel.__init__(self, parent, -1)

		topSizer = wx.BoxSizer(wx.VERTICAL)
		
		sizer = wx.GridBagSizer(hgap=16, vgap=7)
		
		self.box0 = AdjustmentTable(self, -1)
		self.box1 = AdjustmentTable(self, -1)
		self.box2 = AdjustmentTable(self, -1)
		self.box3 = AdjustmentTable(self, -1)
		self.button1 = wx.Button(self, 1, 'Update')
		self.button2 = wx.Button(self, 2, 'Box2Slider')

		self.box0.setOutputString('$ACSDR MKP,2,3,4,5')
		self.box1.setOutputString('$ACSDR MKP,5,4,3,2')
		self.box2.setOutputString('$ACSDR MKP,140,3,4,10')
		self.box3.setOutputString('$ACSDR MKP,80,75,80,3')
		
		sizer.Add(self.box0, pos=(0,0), span=(5,4), flag=wx.EXPAND | wx.ALIGN_CENTRE, border=5)
		sizer.Add(self.box1, pos=(0,4), span=(5,4), flag=wx.EXPAND | wx.ALIGN_CENTRE, border=5)
		sizer.Add(self.box2, pos=(0,8), span=(5,4), flag=wx.EXPAND | wx.ALIGN_CENTRE, border=5)
		sizer.Add(self.box3, pos=(0,12), span=(5,4), flag=wx.EXPAND | wx.ALIGN_CENTRE, border=5)
		sizer.Add(self.button1, pos=(5,6), span=(1,2), flag=wx.EXPAND | wx.ALIGN_CENTRE, border=1)
		sizer.Add(self.button2, pos=(5,8), span=(1,2), flag=wx.EXPAND | wx.ALIGN_CENTRE, border=1)
		
		self.Bind(wx.EVT_BUTTON, self.OnUpdate, id=1)
		self.Bind(wx.EVT_BUTTON, self.OnBox2Slider, id=2)
		
		topSizer.Add(sizer, 0, wx.ALL|wx.EXPAND, 5)

		self.SetSizer(topSizer)

		topSizer.Fit(self)


	def OnUpdate(self, event):
		self.sliderboxval = self.sliderbox.GetValue()
		self.display.SetValue(str(self.sliderboxval))

	def OnBox2Slider(self, event):
		self.sliderboxval = self.display.GetValue()
		self.sliderbox.SetValue(int(self.sliderboxval))



class AdjustmentTable(wx.Panel):
	def __init__(self, parent, id):
		wx.Panel.__init__(self, parent, -1)

		topSizer = wx.BoxSizer(wx.VERTICAL)
		
		sizer = wx.GridBagSizer(hgap=5, vgap=5)

		self.outputstring = ''
		
		self.dropbox = wx.ComboBox(self, -1, choices=["9600", "19200", "38400", "57600", "115200"], style=wx.CB_DROPDOWN|wx.CB_SORT)
		self.display = wx.TextCtrl(self, -1, style=wx.TE_RIGHT)
		self.display1 = wx.TextCtrl(self, -1, style=wx.TE_LEFT)
		self.display2 = wx.TextCtrl(self, -1, style=wx.TE_RIGHT)
		self.sliderbox = wx.Slider(self, -1, 1, 20, 10000, wx.DefaultPosition, (250,-1), wx.SL_AUTOTICKS | wx.SL_HORIZONTAL | wx.SL_TOP)
		self.sliderbox.SetTickFreq(1000, 1)
		self.sliderboxval = self.sliderbox.GetValue()
		self.button1 = wx.Button(self, 1, 'Update')
		self.button2 = wx.Button(self, 2, 'Box2Slider')
		self.display.SetValue(str(self.sliderboxval))
		
		sizer.Add(self.dropbox, pos=(0,0), span=(1,4), flag=wx.EXPAND | wx.ALIGN_CENTRE, border=5)
		sizer.Add(self.display, pos=(1,0), span=(1,4), flag=wx.EXPAND | wx.ALIGN_CENTRE, border=5)
		sizer.Add(self.display1, pos=(2,0), span=(1,1), flag=wx.EXPAND | wx.ALIGN_CENTRE, border=5)
		sizer.Add(self.display2, pos=(2,2), span=(1,1), flag=wx.EXPAND | wx.ALIGN_CENTRE, border=5)
		sizer.Add(self.sliderbox, pos=(3,0), span=(1,4), flag=wx.EXPAND | wx.ALIGN_CENTRE, border=5)
		sizer.Add(self.button1, pos=(4,0), span=(1,1), flag=wx.EXPAND | wx.ALIGN_CENTRE, border=1)
		sizer.Add(self.button2, pos=(4,2), span=(1,1), flag=wx.EXPAND | wx.ALIGN_CENTRE, border=1)
		
		self.Bind(wx.EVT_BUTTON, self.OnUpdate, id=1)
		self.Bind(wx.EVT_BUTTON, self.OnBox2Slider, id=2)
		self.Bind(wx.EVT_TEXT, self.sliderBoxAuto)
		self.Bind(wx.EVT_SLIDER, self.sliderUpdate)
		
		topSizer.Add(sizer, 0, wx.ALL|wx.EXPAND, 5)

		self.SetSizer(topSizer)

		topSizer.Fit(self)

	def setOutputString(self, value):
                self.outputstring = value

	def OnUpdate(self, event):
                #COMMENTED OUT FOR CODY'S TESTS
		#self.sliderboxval = self.sliderbox.GetValue()
		#self.display.SetValue(str(self.sliderboxval))
                self.outputstring = self.display.GetValue()
		sending(ser, self.outputstring)

	def OnBox2Slider(self, event):
		self.sliderboxval = self.display.GetValue()
		self.sliderbox.SetValue(int(self.sliderboxval))

	def sliderUpdate(self, event):
		self.pos = self.sliderbox.GetValue()
		#COMMENTED OUT FOR CODY'S TESTS
		#self.display.SetValue(str(self.pos))

	def sliderBoxAuto(self, event):
		self.sliderboxval = self.display.GetValue()
		#COMMENTED OUT FOR CODY'S TESTS
		#self.sliderbox.SetValue(int(self.sliderboxval))

	def comboSelection(self, event):
		self.maxpos = 20 #Get Value from TABLE
		self.minpos = 10000 #Get Value from TABLE
		self.sliderbox.SetRange(self.minpos, self.maxpos)
		self.display1.SetValue(str(self.minpos))
		self.display2.SetValue(str(self.maxpos))

	def updateMotor(motor, value):
		self.maxpos = 20 #Get Value from TABLE
                


def reverseenum(string, l):
	#returns the index value based on the string passed in
	for i in range(len(l)):
		if string == l[i]:
			return i
	return -1 #no match


class MotorTable(wx.Panel):
	def __init__(self, parent, id):
		wx.Panel.__init__(self, parent, -1)

		self.rx_last_read = 0

		self.rxparser = RxParser()
		
		self.motor_table = []


		self.motor_table.append([])
		for i in motor_settings:
			self.motor_table[0].append(wx.StaticText(self, -1, i))
	
		for i in range(motor_num):
			print "Motor Table init i value: ", i
			self.motor_table.append([])
			for j in range(len(motor_settings)):
				if j == reverseenum("Motor", motor_settings): # Motor number
					self.motor_table[i+1].append(wx.TextCtrl(self, -1, str(i)))
				elif j == reverseenum("RPS", motor_settings): # Motor number
					self.motor_table[i+1].append(wx.TextCtrl(self, -1, "---"))
				elif j == reverseenum("Volts", motor_settings): # Motor number
					self.motor_table[i+1].append(wx.TextCtrl(self, -1, "---"))
				elif j == reverseenum("Amps", motor_settings): # Motor number
					self.motor_table[i+1].append(wx.TextCtrl(self, -1, "---"))
				elif j == reverseenum("ESC(uS)", motor_settings): # Motor number
					self.motor_table[i+1].append(wx.TextCtrl(self, -1, "---"))
				elif j == reverseenum("Thrust", motor_settings): # Motor number
					self.motor_table[i+1].append(wx.TextCtrl(self, -1, "---"))
				elif j == reverseenum("Torque", motor_settings): # Motor number
					self.motor_table[i+1].append(wx.TextCtrl(self, -1, "---"))
				else:
					self.motor_table[i+1].append(wx.TextCtrl(self, -1, "generic"))

		grid_sizer = wx.FlexGridSizer(motor_num+1, len(motor_settings), 10, 10)		
		for i in self.motor_table:
			for j in i:
				grid_sizer.Add(j)

		self.SetSizer(grid_sizer)
		
		self.redraw_timer = wx.Timer(self)
		self.Bind(wx.EVT_TIMER, self.on_redraw_timer, self.redraw_timer)		
		self.redraw_timer.Start(REFRESH_INTERVAL_MS)

	
		
	def update_field(self, code, enum_field):
		matchlist = self.rxparser.match(rx_buffer[self.rx_last_read], code)
		for i in range(len(matchlist)): # != 0:
			self.motor_table[i+1][reverseenum(enum_field, motor_settings)].SetValue(str(matchlist[i]))
			
	def on_redraw_timer(self, event):
		# if paused do not add data, but still redraw the plot
		# (to respond to scale modifications, grid change, etc.)
		#
		global rx_buffer_lock
		global rx_buffer
#		rxparser = RxParser()
		
		if not paused:
			if not rx_buffer_lock.acquire(False):
				pass
			else:
				try:
					#Go through all the received strings and add whatever is relevant.
					while self.rx_last_read < len(rx_buffer):
						
						self.update_field("$ADRPS", "RPS")
						self.update_field("$ADMIA", "Amps")
						self.update_field("$ADMVV", "Volts")
						self.update_field("$ADPWM", "ESC(uS)")
						self.update_field("$ADMTH", "Thrust")
						self.update_field("$ADMTQ", "Torque")
						self.update_field("$ADDRP", "DRPM")
						self.update_field("$ADMKP", "KP")
						self.update_field("$ADMKI", "KI")
						self.update_field("$ADMKD", "KD")
						
						
						
#						motor_amp = self.rxparser.match(rx_buffer[self.rx_last_read], "$ADMIA")
#						for i in range(len(motor_amp)): # != 0:
#							self.motor_table[i+1][reverseenum("Amps", motor_settings)].SetValue(str(motor_amp[i]))

						self.rx_last_read += 1

				finally:
					rx_buffer_lock.release()



if __name__=='__main__':
	print "Please note this is not intended to be run standalone. Please run ./anzhelka_terminal_gui.py instead."

