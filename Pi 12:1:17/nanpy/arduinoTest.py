from nanpy import (ArduinoApi, SerialManager)
from time import sleep

ledPin = [2,3,4,5,6,7]

try:
    connection = SerialManager()
    ard = ArduinoApi(connection = connection)
except:
    print("FAILED TO CONNECT")

for i in ledPin:
    ard.pinMode(i, ard.OUTPUT)

while True:
    try:
        for i in range(255):
            for z in range(20):
                ard.analogWrite(2, i)
                print(i)
        
        
    except:
        print("not working arduino")

for i in ledPin:
    try:
        ard.analogWrite(i, 0)

    except:
        print("not working arduino")
