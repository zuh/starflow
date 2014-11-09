import QtQuick 1.1

Rectangle {
    id: header
    color: "#330000"
    z: 10

    Item {
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width / 4

        Text {
            anchors.centerIn: parent
            color: "#FFFFFF"
            opacity: 0.6
            font.bold: true
            text: {
                if (!camera.connected)
                    return "No camera connection"
                return "Canon EOS 450D"
            }
        }
    }

    Rectangle {
        id: error
        visible: false
        opacity: 0.0
        color: "#990000"
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: parent.height
        property string error: camera.error
        onErrorChanged: {
            if (camera.error == "")
                return
            visible = true
            errorfadein.running = true
            errorTimer.start()
        }
        onOpacityChanged: {
            if (opacity == 0.0) {
                visible = false
                camera.error = ""
            }
        }

        PropertyAnimation {
            id: errorfadein
            target: error
            property: "opacity"
            to: 1.0
            duration: 100
        }

        PropertyAnimation {
            id: errorfadeout
            target: error
            property: "opacity"
            to: 0.0
        }

        Timer {
            id: errorTimer
            interval: 1000
            repeat: false
            onTriggered: errorfadeout.running = true
        }

        Text {
            anchors.centerIn: parent
            color: "#FFFFFF"
            opacity: 0.6
            font.bold: true
            text: camera.error
        }
    }
}

