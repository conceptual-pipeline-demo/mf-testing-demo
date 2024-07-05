
#
# Sample 3270 screen scraping using py3270 library
#
import time, sys
from py3270 import Emulator

delayt = 1    # In sec, slowing down to be able to see the screen update
mylogin = 'HERC04'
mypass = 'PASS4U'
myhost = '127.0.0.1:53270'
screenrows = []

# use x3270 so you can see what is going on
# my3270 = Emulator(visible=True)

# or not (uses s3270)
my3270 = Emulator()

try:
	# TSO login
	my3270.connect(myhost)
	my3270.wait_for_field()
	#my3270.send_clear()
	my3270.exec_command(b"Clear")
	my3270.wait_for_field()
	time.sleep(delayt)
	print("CONNECTION ESTABLISHED")
	if not my3270.string_found(23, 1, 'Logon ===>'):
		sys.exit('Error: print(my3270.string_get(23,1,20))')
	my3270.send_string(mylogin)
	my3270.send_enter()
	my3270.wait_for_field()
	time.sleep(delayt)
	if not my3270.string_found(1, 2, 'ENTER CURRENT'):
		sys.exit('Error: print(my3270.string_get(1, 2,20))')
	my3270.send_string(mypass)
	my3270.send_enter()
	my3270.wait_for_field()
	time.sleep(delayt)
	print("LOGIN SUCCESS")
	#if not my3270.string_found(13, 2, '***'):
	#    sys.exit('Error: print(my3270.string_get(13,2,10))')
	my3270.send_enter()
	my3270.wait_for_field()
	time.sleep(delayt)
	#if not my3270.string_found(12, 2, '***'):
	#    sys.exit('Error: print(my3270.string_get(12,2,10))')
	my3270.send_enter()
	my3270.wait_for_field()
	time.sleep(delayt)

	# 3-Utilities
	my3270.send_string("3")
	my3270.send_enter()
	my3270.wait_for_field()
	print("UTILITIES")

	# 4-DSLIST
	my3270.send_string("4")
	my3270.send_enter()
	my3270.wait_for_field()
	time.sleep(delayt)
	print("DSLIST")

	# DSNAME - HERC03/4
	my3270.send_string("SYS2")
	# Send backspace commands to delete characters
	for _ in range(2):
		my3270.exec_command(b"BackTab")
		time.sleep(0.1)  # Small delay to see the effect
	my3270.send_enter()
	my3270.wait_for_field()
	time.sleep(delayt)
	print("DSNAME")

	# Choose SYS2.JCLLIB
	# if not my3270.string_found(18, 4, 'SYS2.JCLLIB'):
	# 	sys.exit('Error: print(my3270.string_get(1, 2,20))')
	my3270.fill_field(18, 2, 'V', 1)
	my3270.wait_for_field()
	time.sleep(delayt)
	my3270.send_enter()
	my3270.wait_for_field()
	time.sleep(delayt)
	print("Choose SYS2.JCLLIB")

	i = 4
	j = 1
	found = False
	while j < 10:
		while i < 44:
			if my3270.string_found(i,4, "TESTCOB"):
				found = True
				break
			i += 1
			print(f"next item i={i}")
		if found:
			break
		my3270.move_to(2, 15)
		my3270.wait_for_field()
		my3270.send_pf8()
		my3270.wait_for_field()
		time.sleep(delayt)
		j += 1
		i = 4
		print(f"page down j={j}")

	# choose TESTCOB
	if not my3270.string_found(i, 4, 'TESTCOB'):
		sys.exit('Error: print(my3270.string_get(1, 2,20))')
	my3270.fill_field(i, 2, 'V', 1)
	my3270.wait_for_field()
	time.sleep(delayt)
	my3270.send_enter()
	my3270.wait_for_field()
	time.sleep(delayt)

	# submit
	my3270.send_string("SUBMIT")
	my3270.send_enter()
	my3270.wait_for_field()
	time.sleep(delayt)

except:
	print("There was a problem running the script in line: ", sys.exc_traceback.tb_lineno)
	print("Error: ", sys.exc_info())

finally:
	my3270.send_pf3()
	my3270.wait_for_field()
	time.sleep(delayt)
	my3270.send_pf3()
	my3270.wait_for_field()
	time.sleep(delayt)
	my3270.send_pf3()
	my3270.wait_for_field()
	time.sleep(delayt)
	my3270.send_pf3()
	my3270.wait_for_field()
	time.sleep(delayt)
	my3270.send_pf3()
	my3270.wait_for_field()
	time.sleep(delayt)
	#
	my3270.send_pf3()
	my3270.wait_for_field()
	time.sleep(delayt)
	#if not my3270.string_found(5, 2, 'READY'):
	#    sys.exit('Error: print(my3270.string_get(5,2,10))')
	#
	my3270.send_pf3()
	my3270.wait_for_field()
	time.sleep(delayt)
	#if not my3270.string_found(5, 2, 'READY'):
	#    sys.exit('Error: print(my3270.string_get(5,2,10))')
	#
	my3270.send_string("exec (hello)")
	my3270.send_enter()
	my3270.wait_for_field()
	time.sleep(delayt)
	#
	my3270.send_string('LOGOFF')
	my3270.send_enter()
	my3270.wait_for_field()
	time.sleep(delayt)
	# Terminate the emulator session
	my3270.terminate()
	print("TERMINATING")


