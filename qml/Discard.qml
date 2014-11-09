import QtQuick 1.1
import Qt.labs.folderlistmodel 1.0

Rectangle {
    id: root

    color: "#000000"

    onVisibleChanged: {
        if (pixelview.source == "")
            pixelview.source = "../currentDiscard.tiff"
    }

    Item {
        id: controls
        width: parent.width / 2
        height: parent.height / 2
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: clipper.left

        Row {
            anchors.centerIn: parent
            width: parent.width - 32
            property int childWidth: (width - spacing * (children.length - 1)) / children.length
            spacing: 32

            Rectangle {
                id: batchname
                property alias text: nameedit.text
                width: parent.childWidth
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
                    text: "kuvei"
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

            Control {
                id: keep
                width: parent.childWidth
                height: 64
                enabled: camera.connected
                text: "Keep frame"
                onClicked: {
                    pixelview.source = ""
                    pixelview.source = "../currentPhoto.jpg"
                }
            }

            Control {
                id: discard
                width: parent.childWidth
                height: 64
                enabled: frames.currentIndex > -1
                text: "Discard"
                onClicked: {
                    frames.currentIndex = frames.currentIndex + 1
                }
            }
        }
    }

    FolderListModel {
        id: folderModel
        folder: "../" + batchname.text
    }

    ListView {
        id: frames
        width: parent.width / 2
        height: parent.height / 2
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        clip: true
        focus: true
        highlight: Rectangle { color: "#990000" }
        model: folderModel
        delegate: Control {
            id: control
            width: frames.width
            height: 64
            text: filePath
            onClicked: frames.currentIndex = index
            selected: ListView.isCurrentItem
        }
        onCurrentIndexChanged: {
            if (currentIndex < 0)
                return
            if (!root.visible)
                return

            camera.rawToTiff(currentItem.text, "currentDiscard.tiff")
            pixelview.source = ""
            pixelview.source = "../currentDiscard.tiff"

        }
    }

    Image {
        id: overview
        width: parent.width / 2
        height: parent.height / 2
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        fillMode: Image.PreserveAspectFit
        cache: false
        smooth: false
        source: pixelview.source
        property int xOffset: (width - paintedWidth) / 2
        property int yOffset: (height - paintedHeight) / 2

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
                locate(mouse.x - overview.xOffset, mouse.y - overview.yOffset)
            }
            onPositionChanged: {
                locate(mouse.x - overview.xOffset, mouse.y - overview.yOffset)
            }

            function locate(x, y) {
                var scaledx = x * (pixelview.width / overview.paintedWidth)
                var scaledy = y * (pixelview.height / overview.paintedHeight)
                pixelview.x = -scaledx + clipper.width / 2
                pixelview.y = -scaledy + clipper.height / 2
            }
        }

    }

    Rectangle {
        id: clipper
        width: parent.width / 2
        height: parent.height / 2
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
            source: ""
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
}
