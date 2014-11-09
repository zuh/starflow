#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import os
import subprocess
import json
import time
from PySide.QtCore import *
from PySide.QtGui import *
from PySide.QtDeclarative import QDeclarativeView
from camera.GPhoto2LibCamera import Camera

class OptionListModel(QAbstractListModel):
    COLUMNS = ('value',)
 
    def __init__(self, values):
        QAbstractListModel.__init__(self)
        self._values = values
        self.setRoleNames(dict(enumerate(OptionListModel.COLUMNS)))
 
    def rowCount(self, parent=QModelIndex()):
        return len(self._values)
 
    def data(self, index, role):
        if index.isValid() and role == OptionListModel.COLUMNS.index('value'):
            return self._values[index.row()]
        return None

    @Slot(str)
    def add(self, value):
        count = len(self._values)
        self.beginInsertRows(QModelIndex(), count, count)
        self._values.append(value)
        self.endInsertRows()

    @Slot()
    def clear(self):
        count = len(self._values)
        self.beginRemoveRows(QModelIndex(), 0, count)
        self._values = []
        self.endRemoveRows()


class CameraControl(QObject):
    camera = None

    properties = {}
    property_changed = Signal()

    def load_settings(self):
        try:
            f = open(".starflowrc", 'r')
            self.properties = json.load(f)
            self.property_changed.emit()
            f.close()
        except IOError:
            pass
        except ValueError:
            pass

    def store_settings(self):
        try:
            f = open(".starflowrc", 'w')
            json.dump(self.properties, f)
            f.close()
        except IOError:
            pass

    def get_camera_property(self, key):
        if self.camera is None:
            return "N/A"
        return self.camera.get_config(key, cached=True)

    def set_camera_property(self, key, value):
        if self.camera is None:
            return
        self.camera.set_config(key, value)
        self.property_changed.emit()

    def get_property(self, key):
        if key not in self.properties:
            return ""
        return self.properties[key]

    def set_property(self, key, value):
        self.properties[key] = value
        self.store_settings()
        self.property_changed.emit()

    def get_connected(self):
        return self.camera is not None

    def set_connected(self, connected):
        self.connected_changed.emit()
        pass
        
    connected_changed = Signal()
    connected = Property(bool, get_connected, set_connected, notify=connected_changed)

    def get_iso(self):
        return self.get_camera_property("iso")

    def set_iso(self, iso):
        self.set_camera_property("iso", iso)

    iso = Property(str, get_iso, set_iso, notify=property_changed)

    def get_isovalues(self):
        return self._isovalues
    
    _isovalues = OptionListModel([])
    isovalues = Property(QObject, get_isovalues, notify=property_changed)

    def get_aperture(self):
        return self.get_camera_property("aperture")

    def set_aperture(self, aperture):
        self.set_camera_property("aperture", aperture)

    aperture = Property(str, get_aperture, set_aperture, notify=property_changed)

    def get_aperturevalues(self):
        return self._aperturevalues
    
    _aperturevalues = OptionListModel([])
    aperturevalues = Property(QObject, get_aperturevalues, notify=property_changed)

    def get_shutterspeedvalues(self):
        return self._shutterspeedvalues
    
    _shutterspeedvalues = OptionListModel([])
    shutterspeedvalues = Property(QObject, get_shutterspeedvalues, notify=property_changed)

    def get_exposure(self):
        return self.get_camera_property("exposure")

    def set_exposure(self, exposure):
        self.set_camera_property("exposure", exposure)

    exposure = Property(str, get_exposure, set_exposure, notify=property_changed)

    def get_interval(self):
        return self.get_property("interval")

    def set_interval(self, interval):
        self.set_property("interval", interval)

    interval = Property(str, get_interval, set_interval, notify=property_changed)

    def get_batchname(self):
        return self.get_property("batchname")

    def set_batchname(self, value):
        self.set_property("batchname", value)

    batchname = Property(str, get_batchname, set_batchname, notify=property_changed)

    def get_frames(self):
        return self.get_property("frames")

    def set_frames(self, value):
        self.set_property("frames", value)

    frames = Property(str, get_frames, set_frames, notify=property_changed)

    def get_frametype(self):
        return self.get_property("frametype")

    def set_frametype(self, value):
        self.set_property("frametype", value)

    frametype = Property(str, get_frametype, set_frametype, notify=property_changed)

    def get_error(self):
        return self._error

    def set_error(self, error):
        self._error = error
        self.error_changed.emit()

    _error = ""
    error_changed = Signal()
    error = Property(str, get_error, set_error, notify=error_changed)

    def get_progress(self):
        return self._progress

    def set_progress(self, progress):
        self._progress = progress
        self.progress_changed.emit()
        while app.hasPendingEvents():
            app.processEvents()

    _progress = ""
    progress_changed = Signal()
    progress = Property(str, get_progress, set_progress, notify=progress_changed)

    def get_vfwhm(self):
        return self._vfwhm

    def set_vfwhm(self, vfwhm):
        self._vfwhm = float(vfwhm)
        self.vfwhm_changed.emit()

    _vfwhm = 0.0
    vfwhm_changed = Signal()
    vfwhm = Property(float, get_vfwhm, set_vfwhm, notify=vfwhm_changed)

    def get_hfwhm(self):
        return self._hfwhm

    def set_hfwhm(self, hfwhm):
        self._hfwhm = float(hfwhm)
        self.hfwhm_changed.emit()

    _hfwhm = 0.0
    hfwhm_changed = Signal()
    hfwhm = Property(float, get_hfwhm, set_hfwhm, notify=hfwhm_changed)

    @Slot()
    def connect(self):
        self.set_progress("Connecting to camera...")
        self.camera = Camera()
        if self.camera.connect() != 0:
            self.set_error("Could not find camera!")
            self.set_progress("")
            return
        self.set_progress("")
        self.set_connected(True)
        self._isovalues.clear()
        map(self._isovalues.add, self.camera.get_config_options("iso"))
        self._aperturevalues.clear()
        map(self._aperturevalues.add, self.camera.get_config_options("aperture"))
        self._shutterspeedvalues.clear()
        speeds = self.camera.get_config_options("shutterspeed")
        map(self._shutterspeedvalues.add, [s for s in speeds if '/' in s])
        self.load_settings()

    @Slot()
    def close(self):
        self.set_connected(False)
        if (self.camera):
            self.camera.close()
            self.camera = None

    @Slot(str)
    def shoot(self, name):
        self.camera.shoot(name, self.set_progress)

    @Slot(str)
    def shootFocus(self, name):
        tmpname = "tmp-" + name
        self.camera.shoot(tmpname, self.set_progress)
        pnm = name.replace("jpg","pnm")
        fts = name.replace("jpg","fts")
        self.set_progress("Converting RAW to JPEG...")
        self.rawToJpeg(tmpname, name)
#        self.set_progress("Converting RAW to PNM...")
#        self.rawToPnm(tmpname, pnm)
#        self.set_progress("Converting PNM to FITS...")
#        subprocess.call(["an-pnmtofits", pnm, "-o", fts]);
#        self.set_progress("Converting PNM to JPEG...")
#        subprocess.call(["convert", pnm, name]);
        self.set_progress("")

    @Slot(str)
    def shootPreview(self, name):
        tmpname = "tmp-" + name
        self.camera.shoot(tmpname, self.set_progress)
        self.set_progress("Converting RAW to JPEG...")
        self.rawToJpeg(tmpname, name)
        self.set_progress("")
        try:
            os.remove(tmpname)
        except OSError:
            pass

    @Slot(str, str)
    def rawToPnm(self, rawname, name):
        if rawname.startswith("file://"):
            rawname = rawname[7:]
        print rawname, name
        print time.time()
        fd = os.open(name, os.O_CREAT | os.O_WRONLY)
        subprocess.call(["dcraw", "-q", "0",  "-c", rawname], stdout=fd)
        os.close(fd)
        print time.time()

    @Slot(str, str)
    def rawToJpeg(self, rawname, name):
        if rawname.startswith("file://"):
            rawname = rawname[7:]
        print rawname, name
        fd = os.open(name, os.O_CREAT | os.O_WRONLY)
        subprocess.call(["dcraw", "-e", "-c", rawname], stdout=fd)
        os.close(fd)

    @Slot(str, str)
    def rawToTiff(self, rawname, name):
        if rawname.startswith("file://"):
            rawname = rawname[7:]
        print rawname, name
        fd = os.open(name, os.O_CREAT | os.O_WRONLY)
        subprocess.call(["dcraw", "-h", "-w", "-T", "-c", rawname], stdout=fd)
        os.close(fd)

    @Slot()
    def plot(self):
        plot = subprocess.Popen(["polar-plot/polar-plot",
                                 "horizontalPolaris.jpg",
                                 "verticalPolaris.jpg",
                                 "currentPlot.jpg" ])
        self.set_progress("Plotting")
        while plot.poll() is None:
            app.processEvents()
        self.set_progress("")

    @Slot(str, int, int)
    def analyze(self, fits, x, y):
        analyze = subprocess.Popen(["star-analyze/star-analyze",
                                   fits, str(x), str(y)],
                                   stdout=subprocess.PIPE)
        self.set_progress("Started")
        app.processEvents()
        (out, err) = analyze.communicate()
        for line in out.split('\n'):
            if line.startswith("Vertical"):
                self.set_vfwhm(line.split(":")[-1].strip())
            if line.startswith("Horizontal"):
                self.set_hfwhm(line.split(":")[-1].strip())
        self.set_progress("")

    @Slot(str)
    def getIndex(self, frametype, folder):
        files = [f for f in os.listdir(folder)]
        files.sort()
        i = files.length()
#        while files[i].rfind('-' + frametype + '-') < 0 and i > 0:
#            i--
        if files[i].rfind('-' + frametype + '-') < 0:
            number = files[i][files[i].rfind('-'):-3]
            return int(number)

# Create Qt application and the QDeclarative view
app = QApplication(sys.argv)
view = QDeclarativeView()
view.setResizeMode(QDeclarativeView.SizeRootObjectToView)
rc = view.rootContext()
cc = CameraControl()

rc.setContextProperty('camera', cc)

# Set the QML file and show
view.setSource(QUrl('qml/StarFlow.qml'))
view.resize(800, 480)
view.showFullScreen()

# Enter Qt main loop
ret = app.exec_()
cc.close()
sys.exit(ret)
