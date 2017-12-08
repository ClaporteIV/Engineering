from nanpy import (ArduinoApi, SerialManager, Servo)
from time import sleep

ledPin = 13
servoPin = 6

try:
	connection = SerialManager()
	a = ArduinoApi(connection = connection)
except:
	print("Failed to connect to Arduino")


a.pinMode(ledPin, a.OUTPUT)
servo = Servo(servoPin)
try:
	while True:
		servo.write(50)
		print("OPEN")
		sleep(1)
		servo.write(103)
		print("CLOSED")
		sleep(1)
	#	servo.write(100)
	#	sleep(1)
	#	print("SERVO 100")
except:
	a.digitalWrite(ledPin, a.LOW)
