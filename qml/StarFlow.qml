import QtQuick 1.1

Column {
    id: root

    width: 800
    height: 600
    property int contentHeight: height - header.height - navbar.height

    property bool cameraConnected: camera.connected
    property string cameraModel: camera.connected ? "Canon EOS 450D" : "No camera"

    onCameraConnectedChanged: {
        if (!camera.connected)
            state = "setup"
    }

    state: "setup"
    states: [
        State { name: "setup" },
        State { name: "focus" },
        State { name: "align" },
        State { name: "frame" },
        State { name: "shoot" },
        State { name: "discard" }
    ]

    Header {
        id: header
        height: 32
        width: parent.width
    }

    Setup {
        id: setup
        width: parent.width
        height: parent.contentHeight 
        visible: root.state === "setup"
    }

    Focus {
        id: focus
        width: parent.width
        height: parent.contentHeight 
        visible: root.state === "focus"
    }

    Align {
        id: align
        width: parent.width
        height: parent.contentHeight 
        visible: root.state === "align"
    }

    Framing {
        id: frame
        width: parent.width
        height: parent.contentHeight 
        visible: root.state === "frame"
    }

    Shoot {
        id: shoot
        width: parent.width
        height: parent.contentHeight 
        visible: root.state === "shoot"
    }
/*
    Discard {
        id: discard
        width: parent.width
        height: parent.contentHeight 
        visible: root.state === "discard"
    }
*/
    Row {
        id: navbar
        width: parent.width
        height: 32
        spacing: 0

        property int controlWidth: width / children.length

        Control {
            width: parent.controlWidth
            height: parent.height
            enabled: true
            selected: root.state === "setup"
            text: "Setup"
            onClicked: root.state = "setup"
        }

        Control {
            width: parent.controlWidth
            height: parent.height
            enabled: true
            selected: root.state === "focus"
            text: "Focus"
            onClicked: root.state = "focus"
        }

        Control {
            width: parent.controlWidth
            height: parent.height
            enabled: true
            selected: root.state === "align"
            text: "Polar Alignment"
            onClicked: root.state = "align"
        }

        Control {
            width: parent.controlWidth
            height: parent.height
            enabled: true
            selected: root.state === "frame"
            text: "Framing"
            onClicked: root.state = "frame"
        }

        Control {
            width: parent.controlWidth
            height: parent.height
            enabled: true
            selected: root.state === "shoot"
            text: "Shoot"
            onClicked: root.state = "shoot"
        }
/*
        Control {
            width: parent.controlWidth
            height: parent.height
            enabled: true
            selected: root.state === "discard"
            text: "Discard"
            onClicked: root.state = "discard"
        }
*/
    }
}

