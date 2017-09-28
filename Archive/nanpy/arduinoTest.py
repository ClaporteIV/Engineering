from nanpy import (ArduinoApi, SerialManager)
from time import sleep

ledPin = 13

try:
    connection = SerialManager()
    ard = ArduinoApi(connection = connection)
except:
    print("FAILED TO CONNECT")

ard.pinMode(ledPin, ard.OUTPUT)

try:
    while True:
        ard.digitalWrite(ledPin, ard.LOW)
        sleep(1)
        ard.digitalWrite(ledPin, ard.HIGH)
        sleep(1)
except:
    ard.digitalWrite(ledPin, ard.LOW)
    print("FAILED TO TURN ON LED")
