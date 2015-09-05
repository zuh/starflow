#!/usr/bin/env python

import json
import os
import os.path
import subprocess
import sys
import time

from GPhoto2Camera import Camera

def message(msg):
  sys.stdout.write('{ "type" : "event", "event" : "message", "message" : "%s" }\n' % msg)
  sys.stdout.flush()

cam = Camera()
cam.connect()
time.sleep(2)
n = 1
while True:
  line = sys.stdin.readline().strip()
  cmd = json.loads(line)
  if cmd["type"] == "exposure":
    filename = "frame%d.cr2" % n
    n += 1

    cam.set_iso(cmd["iso"])
    cam.set_config("aperture", str(cmd["aperture"]))

    cb = None
    if cmd["intent"] == "light":
      cam.set_exposure(cmd["exposure"])
      cb = message
    elif cmd["intent"] == "bias":
      cam.set_shutterspeed("1/4000")
    elif cmd["intent"] == "flat":
      cam.set_shutterspeed("1/125")

    cam.shoot(filename, cb)

    sys.stdout.write('{ "type" : "event", "event" : "frame", "location" : "file://%s" }\n' % os.path.abspath(filename))
    sys.stdout.flush()

  elif cmd["type"] == "framedone":
    try:
      if cmd["location"].startswith("file://"):
        os.remove(cmd["location"][7:])
      else:
        os.remove(cmd["location"])
    except OSError:
      pass


