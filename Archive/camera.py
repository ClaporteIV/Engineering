from picamera import PiCamera, Color
from time import sleep

camera = PiCamera()

camera.start_preview()
camera.annotate_text = "Hello David!"
sleep(30)
camera.stop_preview()
