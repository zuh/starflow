import QtQuick 1.1

Rectangle {
    id: root

    color: "#000000"

    Image {
        id: framingview
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        cache: false
        smooth: false
        source: "../currentFraming.jpg"
    }

    Row {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        width: parent.width
        height: 32
        spacing: 16

        Control {
            id: shoot
            width: (parent.width - 16) / parent.children.length
            height: parent.height
            text: "Shoot framing shot"
            enabled: camera.connected
            onClicked: {
                camera.shootPreview("currentFraming.jpg")
                framingview.source = ""
                framingview.source = "../currentFraming.jpg"
            }
        }

        OptionControl {
            id: exposure
            width: (parent.width - 16) / parent.children.length
            height: parent.height
            enabled: camera.connected
            text: "Exposure: " + camera.exposure
            model: ListModel {
                ListElement { value: "2" }
                ListElement { value: "4" }
                ListElement { value: "8" }
                ListElement { value: "10" }
                ListElement { value: "15" }
                ListElement { value: "20" }
                ListElement { value: "30" }
            }
            onValueChanged: camera.exposure = value
            modalParent: root
        }
    }

    Progress {
        id: progress
        width: parent.width
        height: parent.height
    }
}
