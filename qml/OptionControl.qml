import QtQuick 1.1

Control {
    id: root

    property alias model: grid.model
    property string value: defaultValue
    property string defaultValue
    property string oldState
    property Item modalParent: undefined

    onClicked: {
        if (state != "selected")
            oldState = state
        state = "selected"
    }

    Rectangle {
        parent: modalParent
        visible: root.state === "selected"

        anchors.fill: parent
        anchors.margins: 16
        
        color: "#330000"
        opacity: 0.9

        Rectangle {
            id: header
            color: "#990000"
            height: 32
            width: parent.width
            z: 2

            Text {
                anchors.centerIn: parent
                color: "#FFFFFF"
                text: root.text
                opacity: 0.6
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 16
                color: "#FFFFFF"
                text: "X"
                opacity: 0.6
            }
        }

        GridView {
            id: grid
            z: 1

            anchors.top: header.bottom
            width: parent.width 
            height: parent.height - header.height
            cellWidth: width / 2
            cellHeight: root.height
            clip: true

            delegate: Control {
                width: grid.cellWidth
                height: grid.cellHeight
                text: model.value
                onClicked: {
                    root.value = model.value
                    root.state = root.oldState
                    state = "enabled"
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.state = "enabled"
        }
    }
}

