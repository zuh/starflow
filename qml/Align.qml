import QtQuick 1.1

Rectangle {
    id: root

    color: "#000000"

    Item {
        id: controls
        width: parent.width / 2
        height: parent.height / 2
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: clipper.left
        anchors.bottom: overview.top

        Grid {
            anchors.centerIn: parent
            width: parent.width - 32
            property int childWidth: (width - spacing * (children.length - 1)) / 2
            spacing: 32
            columns: 2
            rows: 2

            Control {
                id: shootH
                width: parent.childWidth
                height: 64
                enabled: camera.connected
                text: "Shoot horizontal frame of Polaris"
                onClicked: {
                    camera.shootPreview("horizontalPolaris.jpg")
                    plotview.source = ""
                    plotview.source = "../horizontalPolaris.jpg"
                }
            }

            OptionControl {
                id: exposure
                width: parent.childWidth
                height: 64
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

            Control {
                id: shootV
                width: parent.childWidth
                height: 64
                enabled: camera.connected
                text: "Shoot vertical frame of Polaris"
                onClicked: {
                    camera.shootPreview("verticalPolaris.jpg")
                    plotview.source = ""
                    plotview.source = "../verticalPolaris.jpg"
                }
            }

            Control {
                id: plot
                width: parent.childWidth
                height: 64
                enabled: true //camera.connected
                text: "Plot alignment"
                onClicked: {
                    camera.plot()
                    plotview.source = ""
                    plotview.source = "../currentPlot.jpg"
                }
            }

        }
    }

    Image {
        id: overview
        width: parent.width / 2
        height: parent.height / 2
        anchors.bottom: parent.bottom
        fillMode: Image.PreserveAspectFit
        cache: false
        smooth: false
        source: plotview.source

        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 8
            text: "Overview"
            color: "#ffffff"
            opacity: 0.6
        }

        MouseArea {
            id: chooser
            anchors.fill: parent
            onClicked: {
                locate(mouse.x, mouse.y)
            }
            onPositionChanged: {
                locate(mouse.x, mouse.y)
            }

            function locate(x, y) {
                var scaledx = x * (plotview.width / width)
                var scaledy = y * (plotview.height / height)
                plotview.x = -scaledx + clipper.width / 2
                plotview.y = -scaledy + clipper.height / 2
            }
        }

    }

    Rectangle {
        id: clipper

        color: "#000000"

        width: parent.width / 2
        height: parent.height
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.left: controls.right
        clip: true

        Image {
            id: plotview
            width: sourceSize.width
            height: sourceSize.height
            cache: false
            smooth: false
            source: "../currentPlot.jpg"
            onStatusChanged: {
                if (status === Image.Ready) {
                    x = -(plotview.sourceSize.width / 2) + clipper.width / 2
                    y = -(plotview.sourceSize.height / 2) + clipper.height / 2
                }
            }
        }

        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 8
            text: "Plot view"
            color: "#ffffff"
            opacity: 0.6
        }

        MouseArea {
            id: panner
            anchors.fill: parent
            enabled: true
            drag.target: plotview
            drag.minimumX: parent.width-plotview.sourceSize.width
            drag.minimumY: parent.height-plotview.sourceSize.height
            drag.maximumX: 0
            drag.maximumY: 0
        }

    }        

    Progress {
        id: progress
        width: parent.width
        height: parent.height
    }
}
