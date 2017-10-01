/*
 * Processing code to take inputs and send them
 * over HTTP request to a server on the Rasp Pi
 *
 * @auth: Ethan Seide
 * @date: 3-14-17
 * @version: 1.0
 */
 
// IMPORTS
import http.requests.*; //HTTP library
import org.gamecontrolplus.gui.*;
import org.gamecontrolplus.*;
import net.java.games.input.*;

// Globals
ControlIO control; //Initializes the control library
ControlDevice xbox; //The control device

float leftStickX, leftStickY;
float rightStickX, rightStickY;
float leftTrigger, rightTrigger;
boolean leftBumper, rightBumper;

int NUM_MOTORS = 5;
int NUM_HORIZ_MOTORS = 4;

int[] thrustValues; //Motor Thrust Values
int[] previousValues; //Old Motor Thrust Values

int CLAW_MIN = 103;
int CLAW_MAX = 50;

int clawValue;
int previousClaw;

String SERVER_PATH = "http://172.31.17.88:5000/";
String MOTOR_PATH = "motorData?";
String CLAW_PATH = "clawData?";
String[] varNames = {"motor0=", "motor1=", "motor2=", "motor3=", "motor4="};
String clawName = "clawValue=";
String sendString;
GetRequest get;

void setup() {
  thrustValues = new int[NUM_MOTORS];
  previousValues = new int[NUM_MOTORS];
  clawValue = CLAW_MAX;
  previousClaw = clawValue;
  sendString = SERVER_PATH;
  
  get = new GetRequest(SERVER_PATH);
  size(600,600);
  
  control = ControlIO.getInstance(this); // Initialize the ControlIO...idk what this really does
  xbox = control.getMatchedDevice("ROVConfig"); // Load the config file
  if (xbox == null) {
    println("Device not configured!");
    System.exit(-1);
  }
}

void draw() {
  background(0);
  stroke(255);
  parseControlValues();
  text("Motor 0: " + str(thrustValues[0]), 25, 25);
  text("Motor 1: " + str(thrustValues[1]), 25, 50);
  text("Motor 2: " + str(thrustValues[2]), 25, 75);
  text("Motor 3: " + str(thrustValues[3]), 25, 100);
  text("Motor 4: " + str(thrustValues[4]), 25, 125);
  text("Claw: " + str(clawValue), 25, 150);
  text("test:" + xbox.getSlider("leftStickX").getValue(), 25, 175);
  
  // Resets motor values to 0 when keys aren't pressed
  if (!keyPressed) {
    for (int i = 0; i < NUM_MOTORS - 1; i++) {
      thrustValues[i] = 0;
    }
  }
  // Only sends data if the data is different. More efficient
  for (int i = 0; i < NUM_MOTORS; i++) {
    if (thrustValues[i] != previousValues[i]) {
      sendString = sendString + MOTOR_PATH;
      for (int j = 0; j < NUM_MOTORS; j++) {
        sendString = sendString + varNames[j] + str(thrustValues[j]) + "&";
      }
      get = new GetRequest(sendString);
      get.send();
      for (int k = i; k < NUM_MOTORS; k++) {
        previousValues[k] = thrustValues[k];
      }
      sendString = SERVER_PATH;
      break;
    }
  }
  /*
  if (clawValue != previousClaw) {
    sendString = SERVER_PATH + CLAW_PATH + clawName + str(clawValue);
    previousClaw = clawValue;
    sendString = SERVER_PATH;
  }*/
    
}

void parseControlValues() {
  getControlValues();
  float thrustConst = 0;
  float rotatConst = 0;
  if (getMag(leftStickX, leftStickY)+getMag(rightStickX,0) > 0) {
    thrustConst = getMag(leftStickX, leftStickY)/(getMag(leftStickX, leftStickY)+getMag(rightStickX,0));
    rotatConst = getMag(rightStickX,0)/(getMag(leftStickX, leftStickY)+getMag(rightStickX,0));
  }
  for (int i = 0; i < NUM_HORIZ_MOTORS; i++) {
    thrustValues[i] = int((thrustConst*getTranslation(leftStickX, leftStickY)[i])+(rotatConst*getRotation(rightStickX)[i]));
    thrustValues[i] = constrain(thrustValues[i], -255, 255);
  }
  thrustValues[NUM_MOTORS - 1] = getAltitude(leftTrigger, rightTrigger);
  thrustValues[NUM_MOTORS - 1] = constrain(thrustValues[NUM_MOTORS - 1], -255, 255);
  
  //setClaw(leftBumper, rightBumper);
  setClawBetter(leftBumper, rightBumper);
}

void getControlValues() {
  leftStickX = xbox.getSlider("leftStickX").getValue();
  leftStickY = xbox.getSlider("leftStickY").getValue();
  rightStickX = xbox.getSlider("rightStickX").getValue();
  rightStickY = xbox.getSlider("rightStickY").getValue();
  //leftTrigger = xbox.getSlider("leftTrigger").getValue();
  //rightTrigger = xbox.getSlider("rightTrigger").getValue();
  //leftBumper = xbox.getButton("leftBumper").pressed();
  //rightBumper = xbox.getButton("rightBumper").pressed();
}

float[] getTranslation(float x, float y) {
  float mag = sqrt((x*x) + (y*y));
  if (mag > 255) {
    x *= (255/mag);
    y *= (255/mag);
  }
  x *= sqrt(2);
  y *= sqrt(2);
  float[] vals = new float[NUM_HORIZ_MOTORS];
  vals[0] = 0 - (x + y);
  vals[1] = x-y;
  vals[2] = vals[0];
  vals[3] = vals[1];
  for (int i = 0; i < NUM_HORIZ_MOTORS; i++) {
    vals[i] = map(vals[i], -512, 512, -255, 255);
  }
  return vals;
}

int[] getRotation(float x) {
  int[] vals = new int[NUM_HORIZ_MOTORS];
  vals[0] = int(x);
  vals[1] = int(0 - x);
  vals[2] = vals[1];
  vals[3] = vals[0];
  for (int i = 0; i < NUM_HORIZ_MOTORS; i++) {
    vals[i] = constrain(vals[i], -255, 255);
  }
  return vals;
}

int getMag(float x, float y) {
  return int(sqrt((x*x) + (y*y)));
}

int getAltitude(float left, float right) {
  left += 127.0;
  right += 127.0;
  return int(right - left);
}

void setClaw(boolean left, boolean right) {
  if ((left)&&(clawValue < CLAW_MIN)) {
    clawValue += 1;
  }
  else if ((right)&&(clawValue > CLAW_MAX)) {
    clawValue -= 1;
  }
  clawValue = constrain(clawValue, CLAW_MAX, CLAW_MIN);
}

void setClawBetter(boolean left, boolean right) {
  if (left) {
    clawValue = CLAW_MIN;
  }
  else if (right) {
    clawValue = CLAW_MAX;
  }
}
  

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      thrustValues[0] = 255;
      thrustValues[1] = 255;
      thrustValues[2] = -255;
      thrustValues[3] = -255;
    }
    if (keyCode == DOWN) {
      thrustValues[0] = -255;
      thrustValues[1] = -255;
      thrustValues[2] = 255;
      thrustValues[3] = 255;
    }
    if (keyCode == LEFT) {
      thrustValues[0] = -255;
      thrustValues[1] = 255;
      thrustValues[2] = 255;
      thrustValues[3] = -255;
    }
    if (keyCode == RIGHT) {
      thrustValues[0] = 255;
      thrustValues[1] = -255;
      thrustValues[2] = -255;
      thrustValues[3] = 255;
    }
  }
}
