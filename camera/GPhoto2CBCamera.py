import os
import sys
import subprocess
import ctypes
import time

class Camera:
    """Camera operating class"""

    config = {}

    gp2 = None

    def __init__(self):
        pass

    def gp2_call(self, args):
        print "Calling: '", ["gphoto2"] + args, "'"
        self.gp2 = subprocess.Popen(["gphoto2"] + args, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return self.gp2.communicate()[0]

    def gp2_call_background(self, args):
        print "Calling: '", ["gphoto2"] + args, "'"
        self.gp2 = subprocess.Popen(["gphoto2"] + args)

    def connect(self):
        return subprocess.call(["which", "gphoto2"])

    def close(self):
        if self.gp2 is not None:
            try:
                self.gp2.terminate()
            except OSError:
                pass

    def get_config_options(self, key):
        choices = []
        for line in self.gp2_call(["--get-config", key]).split('\n'):
            if line.startswith("Choice"):
                choices.append(line.split()[-1])
        return choices

    def get_config(self, key, cached=False):
        if key not in self.config:
            self.config[key] = "N/A"
        elif cached:
            return self.config[key]
        for line in self.gp2_call(["--get-config", key]).split('\n'):
            if line.startswith("Current"):
                self.config[key] = line[9:]
        return self.config[key]

    def set_config(self, key, value):
        self.config[key] = value

    def set_full_config(self, config):
        self.config = config

    def commit_config(self):
        args = []
        self.config["capturetarget"] = "0"
        self.config["shutterspeed"] = "bulb"
        for key in self.config.keys():
            args.append("--set-config")
            args.append(str(key) + "=" + str(self.config[key]))
        if len(args) > 0:
            self.gp2_call(args)

    def set_cb_capture(self, value):
        fd = os.open("/dev/ttyACM0", os.O_WRONLY)
        print "preamble"
        os.write(fd, "\n")
        print "reset"
        os.write(fd, "g21\n")
        if value == 1:
            print "mirror"
            os.write(fd, "g20\n")
            time.sleep(0.1)
            os.write(fd, "g21\n")
            time.sleep(2)
            print "shoot"
            os.write(fd, "g20\n")
       
        os.close(fd)

    def wait_and_download(self, name):
        while self.gp2.poll() is None:
            if os.path.exists(name):
                self.gp2.send_signal(2)
            else:
                time.sleep(1)
        self.gp2 = None

    def shoot(self, name):
        exposure = int(self.config["exposure"])
#        self.commit_config()
        self.gp2_call_background(["--capture-tethered",
                                  "--set-config", "capturetarget=0",
                                  "--force-overwrite",
                                  "--filename="+name])
        time.sleep(2)
        self.set_cb_capture(1)
        time.sleep(exposure)
        self.set_cb_capture(0)
        self.wait_and_download(name)

if __name__ == "__main__":
    cam = Camera()
    if cam.connect() != 0:
        print "Setup failed, exiting"
        sys.exit(1)
    cam.set_full_config({"shutterspeed" : "1/10", "aperture" : "10", "iso" : "1600"})
    cam.set_config("shutterspeed", "bulb")
    cam.set_config("exposure", "10")
    try:
        os.remove("/tmp/kooppa.cr2")
    except OSError:
        pass
    cam.shoot("/tmp/kooppa.cr2")

