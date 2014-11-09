import QtQuick 1.1

Rectangle {
    id: root

    color: "#000000"

    Row {
        
        property int edgeSpacing: 64
        anchors.centerIn: parent
        width: parent.width - edgeSpacing * 2
        height: 64
        spacing: 16

        Control {
            id: connect
            width: parent.width / parent.children.length
            height: parent.height
            text: camera.connected ? "Disconnect camera" : "Connect to camera"
            onClicked: {
                if (camera.connected) {
                    camera.close()
                } else {
                    camera.connect()
                }
            }
        }

        OptionControl {
            id: iso
            width: parent.width / parent.children.length
            height: parent.height
            text: "ISO speed: " + camera.iso
            enabled: camera.connected
            model: camera.isovalues
            onValueChanged: camera.iso = value
            modalParent: root
        }

        OptionControl {
            id: aperture
            width: parent.width / parent.children.length
            height: parent.height
            text: "Aperture: " + camera.aperture
            enabled: camera.connected
            model: camera.aperturevalues
            onValueChanged: camera.aperture = value
            modalParent: root
        }

    }
}
