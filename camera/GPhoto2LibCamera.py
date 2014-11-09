import os
import sys
import subprocess
from multiprocessing import Queue, Process
from Queue import Empty
import ctypes
import time

def CB_shutter(expose):
    fd = os.open("/dev/ttyACM0", os.O_WRONLY)
    os.write(fd, "\r\n")
    os.write(fd, "fs0\r\n")
    if expose == 1:
        time.sleep(0.1)
        os.write(fd, "fs1\r\n")
        time.sleep(0.1)
        os.write(fd, "fs0\r\n")
        time.sleep(2)
        os.write(fd, "fs1\r\n")
    os.close(fd)

def expose(q, t):
    q.put("Mirror lock")
    CB_shutter(1)
    start = time.time()
    q.put(str(t) + " seconds of exposure left")
    while start + t > time.time():
        l = t - int(time.time() - start)
        q.put(str(l) + " seconds of exposure left")
        time.sleep(0.5)
    CB_shutter(0)

class Camera:
    """Camera operating class"""

    # Constants from gphoto2
    GP_CAPTURE_IMAGE = 0
    GP_FILE_TYPE_PREVIEW = 0
    GP_FILE_TYPE_NORMAL = 1

    # Structs from gphoto2
    class CameraFilePath(ctypes.Structure):  
        _fields_ = [('name', (ctypes.c_char * 128)),  
                    ('folder', (ctypes.c_char * 1024))]

    lib = None
    context = ctypes.c_void_p()
    camera = ctypes.c_void_p()
    config = ctypes.c_void_p()
    is_canon = True
    mirror_lock = False
    bulb_mode = False
    exposure = 1
    captured = []

    def __init__(self):
        # Load library
        try:
            self.lib = ctypes.CDLL('libgphoto2.so.6.0.0')  
        except OSError:
            self.lib = None

        if not self.lib:
            try:
                self.lib = ctypes.CDLL('libgphoto2.so.2.4.0')
            except OSError:
                print "Unable to load libgphoto2, camera won't work!"

    def connect(self):
        # Init camera
        self.context = self.lib.gp_context_new()
        self.lib.gp_camera_new(ctypes.pointer(self.camera))
        ret = self.lib.gp_camera_init(self.camera, self.context)
        if ret == -105:
            print "Error: Camera not found"
        if ret == -110:
            print "Error: Camera busy"
        if ret != 0:
            return ret

        ret = self.lib.gp_camera_get_config(self.camera,
                                            ctypes.pointer(self.config),
                                            self.context)
        return ret

    def close(self):
        self.lib.gp_camera_exit(self.camera, self.context)
        self.lib.gp_camera_unref(self.camera)

    def get_config_options(self, key):
        widget = ctypes.c_void_p()
        ret = self.lib.gp_widget_get_child_by_name(self.config, key, ctypes.pointer(widget))
        if ret != 0:
            print "Error", ret, "when getting child"
            return ["N/A"]
        count = self.lib.gp_widget_count_choices(widget)
        choices = []
        for i in range(0, count):
            choice = ctypes.c_char_p()
            if self.lib.gp_widget_get_choice(widget, i, ctypes.pointer(choice)) == 0:
                choices.append(choice.value)
        return choices

    def get_config(self, key, cached=False):
        if key == "exposure":
            return str(self.exposure)
        widget = ctypes.c_void_p()
        ret = self.lib.gp_widget_get_child_by_name(self.config, key, ctypes.pointer(widget))
        if ret != 0:
            #print "Error", ret, "when getting child", key
            return "N/A"
        value = ctypes.c_char_p()
        ret = self.lib.gp_widget_get_value(widget, ctypes.pointer(value))
        if ret != 0:
            print "Error", ret, "when getting value"
            return "N/A"
        return value.value

    def set_config(self, key, value):
        if key == "exposure":
            self.set_exposure(value)
            return
        widget = ctypes.c_void_p()
        ret = self.lib.gp_widget_get_child_by_name(self.config, key, ctypes.pointer(widget))
        if ret != 0:
            print "Error", ret, "when getting child", key
            return
        ret = self.lib.gp_widget_set_value(widget, ctypes.c_char_p(value))
        if ret != 0:
            print "Error", ret, "when setting value", value
            return
        ret = self.lib.gp_camera_set_config(self.camera, self.config, self.context)
        if ret != 0:
            print "Error", ret, "when setting config"
            return

    def set_int_config(self, key, value):
        widget = ctypes.c_void_p()
        intval = ctypes.c_int(value)
        ret = self.lib.gp_widget_get_child_by_name(self.config, key, ctypes.pointer(widget))
        if ret != 0:
            print "Error", ret, "when getting child", key
            return
        ret = self.lib.gp_widget_set_value(widget, ctypes.pointer(intval))
        if ret != 0:
            print "Error", ret, "when setting value", value
            return
        ret = self.lib.gp_camera_set_config(self.camera, self.config, self.context)
        if ret != 0:
            print "Error", ret, "when setting config"
            return

    def capture(self):
        # Capture image
        path = self.CameraFilePath()
        self.lib.gp_camera_capture(self.camera,
                                   self.GP_CAPTURE_IMAGE,
                                   ctypes.pointer(path),
                                   self.context)
        if path.name != "":
            self.captured.append(path)

    def capture_burst(self, count):
        for i in range(0, count):
            self.capture()

    def download_one(self, name=None):
        try:
            path = self.captured.pop(0)
        except IndexError:
            return
        if not name:
            name = path.name
        outpath = os.path.dirname(name)
        if outpath != "" and not os.path.exists(outpath):
            os.makedirs(outpath)
        fd = os.open(name, os.O_CREAT | os.O_WRONLY)
        f = ctypes.c_void_p()
        self.lib.gp_file_new_from_fd(ctypes.pointer(f), fd)
        self.lib.gp_camera_file_get(self.camera,
                                    path.folder,
                                    path.name,
                                    self.GP_FILE_TYPE_NORMAL,
                                    f,
                                    self.context)
        self.lib.gp_camera_file_delete(self.camera,
                                       path.folder,
                                       path.name,
                                       self.context)
        self.lib.gp_file_unref(f);
        return name

    def download(self):
        downloaded = []
        for path in self.captured:
            if path.name == "":
                continue
            fd = os.open(path.name, os.O_CREAT | os.O_WRONLY)
            f = ctypes.c_void_p()
            self.lib.gp_file_new_from_fd(ctypes.pointer(f), fd)
            self.lib.gp_camera_file_get(self.camera,
                                        path.folder,
                                        path.name,
                                        self.GP_FILE_TYPE_NORMAL,
                                        f,
                                        self.context)
            self.lib.gp_camera_file_delete(self.camera,
                                           path.folder,
                                           path.name,
                                           self.context)
            self.lib.gp_file_unref(f);
            downloaded.append(path.name)
        self.captured = []
        return downloaded

    def set_iso(self, value):
        self.set_config("iso", str(value))

    def set_shutterspeed(self, value):
        if type(value) is str and value is "bulb":
            self.bulb_mode = True
        else:
            self.bulb_mode = False
        self.set_config("shutterspeed", str(value))

    def set_eosviewfinder(self, value):
        self.set_config("eosviewfinder", int(value))

    def set_bulb(self, value):
        self.set_config("bulb", int(value))

    def set_exposure(self, value):
        # Fractions are always set through shutterspeed
        if type(value) is str and '/' in value:
            self.set_shutterspeed(value)
        # Otherwise we use our own timing in bulb mode
        self.set_shutterspeed("bulb")
        self.exposure = int(value)

    def set_mirror_lock(self, value):
        self.mirror_lock = value is True

    def set_cb_capture(self, value):
        fd = os.open("/dev/ttyACM0", os.O_WRONLY)
        os.write(fd, "\n")
        os.write(fd, "g21\n")
        if value == 1:
            os.write(fd, "g20\n")
            time.sleep(0.1)
            os.write(fd, "g21\n")
            time.sleep(2)
            os.write(fd, "g20\n")
        os.close(fd)

    def bulb_capture(self, exposure, status_cb):
        event = ctypes.c_int(0)
        data = ctypes.c_void_p()
        q = Queue()
        p = Process(target=expose, args=(q, exposure))
        p.start()
        while p.is_alive():
            if status_cb is None:
                p.join(1)
            else:
                try:
                    status_cb(q.get(True, 1))
                except Empty:
                    pass

        if status_cb is not None:
            status_cb("Waiting for camera to report the file...")
        while event.value != 2:
            self.lib.gp_camera_wait_for_event(self.camera,
                                          100,
                                          ctypes.pointer(event),
                                          ctypes.pointer(data),
                                          self.context)
        path = ctypes.cast(data, ctypes.POINTER(self.CameraFilePath)).contents
        self.captured.append(path)
        
    def shoot(self, name, status_cb=None):
        if self.exposure < 1:
            self.capture()
        else:
            self.bulb_capture(self.exposure, status_cb)

        if status_cb is not None:
            status_cb("Downloading...")
        self.download_one(name)

        if status_cb is not None:
            status_cb("")

