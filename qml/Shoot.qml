import QtQuick 1.1

Rectangle {
    id: root

    color: "#000000"

    property int index: 1
    property string currentName: buildName(batchname.text, frametype.value, index)

    Image {
        id: shootingview
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        cache: false
        smooth: false
        source: "../currentShot.jpg"
    }

    Grid {
        columns: 2
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Rectangle {
            id: batchname
            property alias text: nameedit.text
            width: (parent.width - 16) / parent.columns
            height: 64
            color: "#660000"

            Text {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 16
                color: "#ffffff"
                opacity: 0.6
                text: "Batch name:"
            }
            
            TextEdit {
                id: nameedit
                width: parent.width * 0.6
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 24
                color: "#ffffff"
                opacity: 0.6
                text: camera.batchname
                onTextChanged: camera.batchname = text
                focus: true
            }
            
            Rectangle {
                color: "#ffffff"
                opacity: 0.6
                width: nameedit.width
                height: 2
                anchors.left: nameedit.left
                anchors.top: nameedit.bottom
            }
        }

        OptionControl {
            id: frames
            width: (parent.width - 16) / parent.columns
            height: 64
            enabled: true
            defaultValue: camera.frames
            onValueChanged: camera.frames = value
            text: "Frames to shoot: " + value
            model: ListModel {
                ListElement { value: "1" }
                ListElement { value: "5" }
                ListElement { value: "10" }
                ListElement { value: "20" }
                ListElement { value: "40" }
                ListElement { value: "60" }
                ListElement { value: "80" }
                ListElement { value: "100" }
                ListElement { value: "200" }
                ListElement { value: "400" }
                ListElement { value: "800" }
                ListElement { value: "1000" }
            }
            modalParent: root
        }

        OptionControl {
            id: exposure
            width: (parent.width - 16) / parent.columns
            height: 64
            enabled: camera.connected
            text: "Exposure: " + camera.exposure
            model: frametype.value == "light" ? lightexposure : camera.shutterspeedvalues
            onValueChanged: {
                camera.exposure = value
                camera.exposure = value
            }
            modalParent: root

            ListModel {
                id: lightexposure
                ListElement { value: "2" }
                ListElement { value: "4" }
                ListElement { value: "8" }
                ListElement { value: "10" }
                ListElement { value: "15" }
                ListElement { value: "20" }
                ListElement { value: "30" }
                ListElement { value: "45" }
                ListElement { value: "60" }
                ListElement { value: "90" }
                ListElement { value: "120" }
                ListElement { value: "180" }
                ListElement { value: "240" }
                ListElement { value: "300" }
                ListElement { value: "600" }
            }
        }

        Control {
            id: reset
            width: (parent.width - 16) / parent.columns
            height: 64
            text: "Reset frame counter"
            enabled: true
            onClicked: {
                root.index = 1
            }
        }

        OptionControl {
            id: frametype
            width: (parent.width - 16) / parent.columns
            height: 64
            enabled: true
            defaultValue: camera.frametype
            onValueChanged: camera.frametype = value
            text: "Frame type: " + value
            model: ListModel {
                ListElement { value: "light" }
                ListElement { value: "flat" }
                ListElement { value: "bias" }
                ListElement { value: "dark" }
            }
            modalParent: root
        }

        Rectangle {
            id: frameindex
            property alias text: indexedit.text
            width: (parent.width - 16) / parent.columns
            height: 64
            color: "#660000"

            Text {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 16
                color: "#ffffff"
                opacity: 0.6
                text: "Current frame:"
            }
            
            TextEdit {
                id: indexedit
                width: parent.width * 0.6
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 24
                color: "#ffffff"
                opacity: 0.6
                text: root.index
                onTextChanged: root.index = parseInt(text)
                focus: true
            }
            
            Rectangle {
                color: "#ffffff"
                opacity: 0.6
                width: indexedit.width
                height: 2
                anchors.left: indexedit.left
                anchors.top: indexedit.bottom
            }
        }

        Control {
            id: shoot
            width: (parent.width - 16) / parent.columns
            height: 64
            text: shoottimer.running ? "Stop!" : "Shoot!"
            enabled: camera.connected
            onClicked: {
                if (shoottimer.running)
                    shoottimer.stop()
                else
                    shoottimer.start()
            }

            Timer {
                id: shoottimer
                running: false
                repeat: true
                interval: 1
                onTriggered: {
                    camera.shoot(currentName)
                    camera.rawToJpeg(currentName, "currentShot.jpg")
                    if (++index >= parseInt(frames.value)) {
                        stop()
                    }
                    shootingview.source = ""
                    shootingview.source = "../currentShot.jpg"
                }
            }

        }
    }

    Text {
        id: file
        width: parent.width
        height: 32
        anchors.bottom: parent.bottom
        anchors.margins: 32
        color: "#ffffff"
        opacity: 0.6
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "Next frame: " + root.currentName
    }

    Progress {
        id: progress
        width: parent.width
        height: parent.height
    }

    function buildName(name, type, index) {
        var indexString = ""
        for (var i = index.toString().length; i < frames.value.length; i++)
            indexString = "0" + indexString
        indexString = indexString + index.toString()
        return name + "/" + name + "-" + type + "-" + indexString + ".cr2"
    }
}
