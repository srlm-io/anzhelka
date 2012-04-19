#!/usr/bin/python




from threading import Thread
from threading import Lock
import time
import serial


rx_buffer_lock = Lock()
rx_buffer = []
#last_received = ''



class RxParser(object):
	def match(self, line, code):
		# Line is the received line from the rx_buffer
		# code is the string type that you want to match against, eg "$ADRPS" or "$ADMIA"
		original_line = line
		if line.find(code) != -1: #String matches
			line = line[len(code)+2:] #Get rid of found string. +2 to account for space and to get to next char
			nums = line.split(",")
			try:
				for i in range(len(nums)):
					nums[i] = float(nums[i])
			except ValueError:
				print "RxParser: Could not parse ", code, " String. RX Line: ", original_line
				return []
			
			return nums
		else:
			return []

#	def ADRPS(self, line):
#		#Returns a list with the motor speeds, or an empty list
#		if line.find("$ADRPS ") != -1: #String matches
#			line = line[8:] #Get rid of found string
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
#	def ADMIA(self, line):
#		#Returns a list with the motor currents, or an empty list
#		if line.find("$ADMIA ") != -1: #String matches
#			line = line[8:] #Get rid of found string
#			nums = line.split(",")
#			try:
#				for i in range(len(nums)):
#					nums[i] = float(nums[i])
#			except ValueError:
#				print "Could not parse $ADMIA String"
#				return []
#			
#			return nums
#		else:
#			return []


def receiving(ser):
	global rx_buffer
	global threadkillall
#	global threadkillall
	
	buffer = ''
#	while not threadkillall:
	while True:
		buffer = buffer + ser.read(ser.inWaiting())
		if '\n' in buffer:
			lines = buffer.split('\n') # Guaranteed to have at least 2 entries
#			print "len(lines) == ", len(lines)
			if not rx_buffer_lock.acquire(False):
#				print "Could not get lock..."
				pass
			else:
#				print "Got lock..."
				try:
					for i in range(len(lines)-1):
						rx_buffer.append(lines[i])
#					last_received = lines[-2]
				finally:
					rx_buffer_lock.release()
			#If the Arduino sends lots of empty lines, you'll lose the
			#last filled line, so you could make the above statement conditional
			#like so: if lines[-2]: last_received = lines[-2]
			buffer = lines[-1]
		else:
			time.sleep(.01)
	print "closing..."
	ser.close()


class DataGen(object):
	def __init__(self, init=50):
		try:
			self.ser = ser = serial.Serial(
				port='/dev/ttyUSB0',
				baudrate=115200,
				bytesize=serial.EIGHTBITS,
				parity=serial.PARITY_NONE,
				stopbits=serial.STOPBITS_ONE,
				timeout=0.1,
				xonxoff=0,
				rtscts=0,
#				interCharTimeout=None
			)
		except serial.serialutil.SerialException:
			#no serial connection
			self.ser = None
		else:
			Thread(target=receiving, args=(self.ser,)).start()
		
#	def next(self):
#		if not self.ser:
#			return 100 #return anything so we can test when Propeller isn't connected
#		#return a float value or try a few times until we get one
#		return 50
#		
#		for i in range(40):
#			raw_line = last_received
#			try:
#				return float(raw_line.strip())
#			except ValueError:
#				print 'bogus data',raw_line
#				time.sleep(.5)
#		return 0.
	def __del__(self):
		if self.ser:
			self.ser.close()









if __name__=='__main__':
	print "Please note this is not intended to be run standalone. Please run ./anzhelka_terminal_gui.py instead."
	s = DataGen()
	while True:
		time.sleep(.015)
		print s.next()
