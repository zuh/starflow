import QtQuick 1.1

Item {
    id: root

    property ListModel values: ListModel {
        ListElement { fwhm : 4.3 }
        ListElement { fwhm : 5.3 }
        ListElement { fwhm : 2.3 }
        ListElement { fwhm : 3.3 }
    }
    
    ListView {
        anchors.fill: parent
        model: root.values
        orientation: ListView.Horizontal
        interactive: false

        delegate: Rectangle {
            y: parent.height - height
            height: root.height * (fwhm/10.0)
            width: root.width / root.values.count

            Text {
                text: fwhm
                color: "#000000"
            }
        }    
    }    

}

