import QtQuick 1.0

Rectangle {
    id: bg

    property alias text: label.text
    property alias enabled: area.enabled
    property bool selected: false
    property bool hilight: false
    signal clicked

    states: [
        State {
            name: "pressed"
            PropertyChanges { target: bg; color: "#990000" }
            PropertyChanges { target: label; color: "#FFFFFF" }
        },
        State {
            name: "selected"
            when: selected
            PropertyChanges { target: bg; color: "#990000" }
            PropertyChanges { target: label; color: "#FFFFFF" }
        },
        State {
            name: "enabled"
            when: enabled
            PropertyChanges { target: bg; color: "#660000" }
            PropertyChanges { target: label; color: "#FFFFFF" }
        }
    ]

    color: "#330000"

    MouseArea {
        id: area
        anchors.fill: parent
        property string oldState
        onPressed: {
            oldState = bg.state
            bg.state = "pressed"
        }
        onCanceled: bg.state = oldState
        onReleased: bg.state = oldState
        onClicked: {
            bg.clicked()
        }
    }

    Text {
        id: label
        color: "#666666"
        opacity: 0.6
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }
}

