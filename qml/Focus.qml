import QtQuick 1.1

Rectangle {
    id: root

    color: "#222222"

    Item {
        id: controls
        width: parent.width / 2
        height: parent.height / 2
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: clipper.left

        Grid {
            id:r
            anchors.centerIn: parent
            columns: 2
            width: parent.width - 32
            property int childWidth: (width - spacing * (columns - 1)) / columns
            spacing: 32

            Control {
                id: shoot
                width: parent.childWidth
                height: 64
                enabled: camera.connected
                text: "Shoot frame"
                onClicked: {
                    camera.shootFocus("currentPhoto.jpg")
                    pixelview.source = ""
                    pixelview.source = "../currentPhoto.jpg"
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
                id: fwhm
                width: parent.childWidth
                height: 64
                enabled: camera.connected
                text: "Analyze"
                onClicked: {
                    var x = -pixelview.x
                    x += clipper.width/2 - 16
                    var y = -pixelview.y
                    y += clipper.height/2 - 16
                    camera.analyze("currentPhoto.fts", x, y)
                }
            }

            Item {
                id: analyze
                width: parent.childWidth
                height: 64

                Text {
                    id: vlabel
                    anchors.left: parent.left
                    color: "#ffffff"
                    text: "Vertical FWHM:"
                }

                Text {
                    id: vvalue
                    anchors.right: parent.right
                    color: "#ffffff"
                    text: camera.vfwhm
                }

                Text {
                    anchors.top: vlabel.bottom
                    anchors.left: parent.left
                    color: "#ffffff"
                    text: "Horizontal FWHM:"
                }

                Text {
                    anchors.top: vvalue.bottom
                    anchors.right: parent.right
                    color: "#ffffff"
                    text: camera.hfwhm
                }

                BarPlot {
                    id: plot
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    width: parent.width
                    height: 64
                    
                    Connections {
                        target: camera
                        onVfwhmChanged: {
                            plot.values.append({'fwhm' : camera.vfwhm})
                            if (plot.values.count > 10)
                                plot.values.remove(0)
                        }
                    }
                }
 
            }
        }
    }

    Image {
        id: overview
        width: parent.width / 2
        height: parent.height / 2
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        fillMode: Image.PreserveAspectFit
        cache: false
        smooth: false
        source: pixelview.source

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
                var scaledx = x * (pixelview.width / width)
                var scaledy = y * (pixelview.height / height)
                pixelview.x = -scaledx + clipper.width / 2
                pixelview.y = -scaledy + clipper.height / 2
            }
        }

    }

    Rectangle {
        id: clipper
        width: parent.width / 2
        height: parent.height
        anchors.right: parent.right
        anchors.top: parent.top
        clip: true
        color: "#000000"

        Image {
            id: pixelview
            width: sourceSize.width
            height: sourceSize.height
            cache: false
            smooth: false
            source: "../currentPhoto.jpg"
        }

        Rectangle {
            id: starmask
            anchors.centerIn: parent
            color: "#00ff00"
            opacity: 0.4
            width: 32
            height: 32
        }

        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 8
            text: "Pixel view"
            color: "#ffffff"
            opacity: 0.6
        }

        MouseArea {
            id: panner
            anchors.fill: parent
            enabled: true
            drag.target: pixelview
            drag.minimumX: parent.width-pixelview.sourceSize.width
            drag.minimumY: parent.height-pixelview.sourceSize.height
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
