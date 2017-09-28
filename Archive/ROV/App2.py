# @auth: Chris Laporte
# @date: 9-28-2017
# @version: 2.0

#Imports
from flask import Flask, render_template, Response, request, url_for
#Test camera data for computer
### from camera import Camera

### PI STUFF
### Pi camera
from camera_pi import Camera
from nanpy import (ArduinoApi, SerialManager, Servo)
from time import sleep



###### CONSTANTS ######
NUM_MOTORS = 5
#Pins changed to be fixed
thrustPins = [2,3,4,5,6,7] #Order: Fr L, Fr R, Ba R, Ba L, Vert1, Vert2
dirPins = [22,24,26,28,30,32]

#servoPin = 8 #Claw signal pin I need the correct pin here
CLAW_MIN = 103
CLAW_MAX = 50


#Declare flask app
app = Flask(__name__)

try:
        connection = SerialManager()
        print(str(connection))
        arduino = ArduinoApi(connection = connection)
        claw = Servo(servoPin)
except:
        print("Failed to connect to Arduino")

for i in range(0, len(thrustPins)):
        arduino.pinMode(thrustPins[i], arduino.OUTPUT)
        arduino.pinMode(dirPins[i], arduino.OUTPUT)

#Main Page
@app.route('/')
def index():
        return render_template('index.html')

def gen(camera):
        while True:
                frame = camera.get_frame()
                yield (b'--frame\r\n' b'content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')
#Video streaming route
@app.route('/videoFeed')
def videoFeed():
        return Response(gen(Camera()),mimetype='multipart/x-mixed-replace; boundary=frame')

#Read in motor data and write to Arduino
@app.route('/motorData')
def motorData():
        thrustValues = []
        dirValues = []
        for i in range(0, NUM_MOTORS):
                motor = "motor" + str(i)
                motorVal = request.args.get(motor)
                motorVal = int(motorVal)
                if motorVal < 0:
                        dirValues.append(0)
                        thrustValues.append(0 - motorVal)
                else:
                        dirValues.append(1)
                        thrustValues.append(motorVal)
        try:
                for i in range(0, NUM_MOTORS):
                        arduino.analogWrite(thrustPins[i], thrustValues[i])
                        arduino.digitalWrite(dirPins[i], dirValues[i])
                # Write extra vertical motor
                arduino.analogWrite(thrustPins[NUM_MOTORS], thrustValues[NUM_MOTORS-1])
                arduino.digitalWrite(dirPins[NUM_MOTORS], dirValues[NUM_MOTORS-1])
        except:
                print("MOTORS NOT WORKING: ")
                print(thrustValues)
                for i in range(0, NUM_MOTORS + 1):
                        arduino.analogWrite(thrustPins[i], 0)
        return ""
"""
#Read in claw data and write to Arduino
@app.route('/clawData')
def clawData():
        clawName = "clawValue"
        clawValue = request.args.get(clawName)
        clawValue = int(clawValue)
        try:
                claw.write(clawValue)
        except:
                print("CLAW NOT WORKING: ")
                print(str(clawValue))
                claw.write(CLAW_MAX)
"""
"""
try:
	while True:
		for i in range(0, NUM_MOTORS):
            arduino.analogWrite(motorPin[i], thrustValues[i])

except:
    for i in range(0, NUM_MOTORS):
        arduino.analogWrite(motorPin[i], 0)
"""
if __name__ == '__main__':
        app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)

