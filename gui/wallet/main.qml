import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

Window {
    width: 360
    height: 520
    visible: true
    title: qsTr("Hai Wallet")
    id: root // screen
    color: "#070707"

    property bool swap: true

    Rectangle {
        id: background
        anchors.centerIn: parent
        anchors.fill: parent
        opacity: 0.2
        z: 0

        AnimatedImage {
            z: 1
            width: root.width
            height: root.height
            anchors.centerIn: parent
            id: animImage
            mirror: false
            source: "qrc:/images/files/cube.gif"
            playing: true
            fillMode: Image.PreserveAspectCrop
        }
    }

    function swaps(swp) {
        animImage.mirror = swp

        if (swp === true) {
            testing.buy()
        }

        if (swp === false) {
            testing.sell()
        }

        root.swap = !root.swap
    }

    Connections {
        target: libhai

        function onAddressUpdate(data) {
            lblAddress.text = data
            btnSwap.enabled = true
        }

        function onDeroUpdate(data) {
            deros.text = data
        }

        function onTokenUpdate(data) {
            hais.text = data
        }

        function onEndWait() {
            btnSwap.enabled = true
        }
    }

    Row {
        anchors.centerIn: parent

        Column {
            id: column
            width: 200
            height: 400
            spacing: 100
            anchors.verticalCenter: parent.verticalCenter

            Column {
                id: colTop
                width: parent.width
                height: 75
                spacing: 30
                anchors.horizontalCenter: parent.horizontalCenter

                Image {
                    id: logo
                    width: 75
                    height: 75
                    source: "qrc:/images/files/dero_logo_w.png"
                    fillMode: Image.PreserveAspectFit
                    anchors.horizontalCenter: parent.horizontalCenter
                }


                Label {
                    id: lblAddress
                    text: "Generating Address"
                    color: "gray"
                    font.pointSize: 15
                    font.bold: true
                    font.family: "Terminal"
                    anchors.horizontalCenter: parent.horizontalCenter
                }


            }

            Column {
                spacing: 0
                anchors.horizontalCenter: parent.horizontalCenter

                Row { // Dero
                    spacing: 5
                    anchors.horizontalCenter: parent.horizontalCenter

                    Label {
                        id: deros
                        color: "white"
                        font.pointSize: 20
                        text: "0.00"
                        font.bold: false
                        font.family: "Terminal"
                    }

                    Label {
                        id: sDero
                        color: "white"
                        font.pointSize: 20
                        text: "Dero"
                        font.bold: false
                        font.family: "Terminal"
                    }
                } // Row

                Row { // Hai
                    spacing: 5
                    anchors.horizontalCenter: parent.horizontalCenter

                    Label {
                        id: hais
                        color: "lightgrey"
                        text: "0.00"
                        font.bold: false
                        font.pointSize: 11
                        font.family: "Terminal"
                        font.italic: true
                    }

                    Label {
                        id: shai
                        color: "lightgrey"
                        text: "Hai"
                        font.bold: false
                        font.pointSize: 11
                        font.family: "Terminal"
                        font.italic: true
                    }
                } // Row
            } // Column

            RoundButton {
                id: btnSwap
                width: 50
                height: 50
                enabled: false
                anchors.horizontalCenter: parent.horizontalCenter
                //text: "\u2302" // home
                text: (root.swap) ? "\u21C6" : "\u21c4" // double arrow / swap
                font.pointSize: 25
                onClicked: {
                    btnSwap.enabled = false
                    swaps(root.swap)
                }
            } // RoundButton

        } // Column
    } // Row
} // Window

