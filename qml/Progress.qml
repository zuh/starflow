import QtQuick 1.1

Rectangle {
    id: root
    visible: false
    opacity: 0.8
    color: "#000000"
    property string progress: ""

    Connections {
        target: camera
        onProgressChanged: {
            if (camera.progress == "") {
                root.visible = false
            } else {
                root.progress = camera.progress
                root.visible = true
            }

        }
    }

/* Needs Qt5.2 :(
    SequentialAnimation {
        id: fadein

        OpacityAnimator {
            duration: 250
            target: root
            from: 0.0
            to: 0.8
        }
    }

    SequentialAnimation {
        id: fadeout

        OpacityAnimator {
            duration: 250
            target: root
            to: 0.0
            from: 0.8
        }

        ScriptAction {
            script: root.visible = false
        }
    }
*/

    Rectangle {
        anchors.centerIn: parent
        width: 400
        height: 128
        color: "#330000"

        Text {
            anchors.centerIn: parent 
            color: "#ffffff"
            opacity: 0.6
            text: root.progress
        }
    }

    MouseArea {
        anchors.fill: parent
    }
}
