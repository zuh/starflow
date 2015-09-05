#!/usr/bin/env python

import datetime
import json
import os
import os.path
import sys
import subprocess
import urllib
import argparse


parser = argparse.ArgumentParser(description='Starflow command-line interface')
parser.add_argument('session',
                    help='Name for the session')
parser.add_argument('-e', '--exposure', type=int, default=10,
                    help='Exposure time in seconds (default: 10)')
parser.add_argument('-i', '--iso', type=int, default=400,
                    help='ISO value (default: 400)')
parser.add_argument('-a', '--aperture', type=int, default=4,
                    help='Aperture value (default: 4)')
parser.add_argument('-f', '--frames', type=int, default=1,
                    help='Number of frames to expose (default: 1)')
parser.add_argument('-t', '--type', default='light',
                    choices=['light', 'flat', 'bias'],
                    help='Type of exposures (default: light)')
parser.add_argument('--exposer', default='/usr/bin/exposer',
                    help='Executable to use as exposer interface')
args = parser.parse_args()

date = datetime.date.today().isoformat()

#'/media/zuh/Kattegat/tools/starflow/exposers/build-dummy-Desktop-Debug/dummy'
class Exposer:
  args = None
  def __init__(self, args):
    self.args = args
    self.exposer = subprocess.Popen([args.exposer],
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                               stderr=open(os.devnull, "w"))

  def expose(self):
    exposure = json.loads('{ "type" : "exposure" }')
    exposure["exposure"] = self.args.exposure
    exposure["iso"] = self.args.iso
    exposure["aperture"] = self.args.aperture
    exposure["intent"] = self.args.type

    self.exposer.stdin.write(json.dumps(exposure) + '\n')
    self.exposer.stdin.flush()

  def event(self):
    sys.stdout.flush()
    line = ""
    while len(line) == 0:
      line = self.exposer.stdout.readline().strip()
    if len(line) == 0:
      return json.loads('{ "event" : "none" }')
    return json.loads(line)

  def framedone(self, frame):
    obj = json.loads('{ "type" : "framedone" }')
    obj["location"] = frame
    self.exposer.stdin.write(json.dumps(obj) + '\n')
    self.exposer.stdin.flush()

frame = 0
previousmessage = ""
exposer = Exposer(args)
exposer.expose()
while True:
  event = exposer.event()
  if event["type"] == "error":
    continue
  if event["event"] == "exposure":
    sys.stdout.write('\rExposing: ' + str(event["elapsed"]) + " / " + str(event["duration"]))
    if event["elapsed"] == event["duration"]:
      sys.stdout.write('\n')
      sys.stdout.flush()
  elif event["event"] == "frame":
    frame += 1
    print "Frame available at", event["location"]
    (d, ext) = os.path.splitext(event["location"])
    fstr = ("{:0" + str(len(str(args.frames))) + "d}").format(frame)
    dest = "%s-%s-%s-%s%s" % (args.session, date, args.type, fstr, ext)
    (f, h) = urllib.urlretrieve(event["location"], dest)
    print "Frame", frame, "saved as", dest
    exposer.framedone(event["location"])
    if frame == args.frames:
      sys.exit()
    exposer.expose()
    if args.type == "light":
      sys.stdout.write('Exposing: 0 / ' + str(args.exposure))
    sys.stdout.flush()
  elif event["event"] == "message":
    if event["message"] == previousmessage:
      continue
    if len(event["message"]) > 0:
      event["message"] == previousmessage
      print "Exposer:", event["message"]

