import QtQuick 2.7
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.3

import "../../styles-uit"
import "../audio" as HifiAudio

Item {
    id: tablet
    objectName: "tablet"
    property int rowIndex: 0
    property int columnIndex: 0
    property int count: (flowMain.children.length - 1)

    // used to look up a button by its uuid
    function findButtonIndex(uuid) {
        if (!uuid) {
            return -1;
        }

        for (var i in flowMain.children) {
            var child = flowMain.children[i];
            if (child.uuid === uuid) {
                return i;
            }
        }
        return -1;
    }

    function sortButtons() {
        var children = [];
        for (var i = 0; i < flowMain.children.length; i++) {
            children[i] = flowMain.children[i];
        }

        children.sort(function (a, b) {
            if (a.sortOrder === b.sortOrder) {
                // subsort by stableOrder, because JS sort is not stable in qml.
                return a.stableOrder - b.stableOrder;
            } else {
                return a.sortOrder - b.sortOrder;
            }
        });

        flowMain.children = children;
    }

    // called by C++ code when a button should be added to the tablet
    function addButtonProxy(properties) {
        var component = Qt.createComponent("TabletButton.qml");
        var button = component.createObject(flowMain);

        // copy all properites to button
        var keys = Object.keys(properties).forEach(function (key) {
            button[key] = properties[key];
        });

        // pass a reference to the tabletRoot object to the button.
        if (tabletRoot) {
            button.tabletRoot = tabletRoot;
        } else {
            button.tabletRoot = parent.parent;
        }

        sortButtons();

        return button;
    }

    // called by C++ code when a button should be removed from the tablet
    function removeButtonProxy(properties) {
        var index = findButtonIndex(properties.uuid);
        if (index < 0) {
            console.log("Warning: Tablet.qml could not find button with uuid = " + properties.uuid);
        } else {
            flowMain.children[index].destroy();
        }
    }

    Rectangle {
        id: bgTopBar
        height: 90

        anchors {
            top: parent.top
            topMargin: 0
            left: parent.left
            leftMargin: 0
            right: parent.right
            rightMargin: 0
        }

        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#2b2b2b"
            }

            GradientStop {
                position: 1
                color: "#1e1e1e"
            }
        }

        HifiAudio.MicBar {
            anchors {
                left: parent.left
                leftMargin: 30
                verticalCenter: parent.verticalCenter
            }
        }

        Item {
            width: 150
            height: 50
            anchors.right: parent.right
            anchors.rightMargin: 30
            anchors.verticalCenter: parent.verticalCenter

            ColumnLayout {
                anchors.fill: parent

                RalewaySemiBold {
                    text: Account.loggedIn ? qsTr("Log out") : qsTr("Log in")
                    horizontalAlignment: Text.AlignRight
                    anchors.right: parent.right
                    font.pixelSize: 20
                    color: "#afafaf"
                }

                RalewaySemiBold {
                    visible: Account.loggedIn
                    height: Account.loggedIn ? parent.height/2 - parent.spacing/2 : 0
                    text: Account.loggedIn ? "[" + tabletRoot.usernameShort + "]" : ""
                    horizontalAlignment: Text.AlignRight
                    anchors.right: parent.right
                    font.pixelSize: 20
                    color: "#afafaf"
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!Account.loggedIn) {
                        DialogsManager.showLoginDialog()
                    } else {
                        Account.logOut()
                    }
                }
            }
        }
    }

    Rectangle {
        id: bgMain
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#2b2b2b"
            }

            GradientStop {
                position: 1
                color: "#0f212e"
            }
        }
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: bgTopBar.bottom
        anchors.topMargin: 0

        Flickable {
            id: flickable
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: pageIndicator.top
                topMargin: 20
                leftMargin: 30
                rightMargin: 30
                bottomMargin: 0
            }

            //required for flick direction calculations
            property real oldContentX: 0

            //flicking direction
            property bool flickingLeft: true

            readonly property real pageWidth: width - leftMargin - rightMargin
            contentWidth:  Math.ceil(flowMain.childrenRect.width / pageWidth) * pageWidth;
            contentHeight: flowMain.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.HorizontalFlick

            // animate final transition to page edge
            Behavior on contentX {
                NumberAnimation { duration: 200; }
            }

            onContentXChanged: {
                flickingLeft = (contentX > oldContentX);
                oldContentX = contentX
            }

            onFlickEnded: {
                if (parseFloat(contentX / flickable.pageWidth) !==  pageIndicator.currentIndex * flickable.pageWidth) {
                    if (flickingLeft) {
                        pageIndicator.currentIndex++
                    } else {
                        pageIndicator.currentIndex--
                    }

                    contentX = pageIndicator.currentIndex * flickable.pageWidth +
                            flowMain.rowSpacing * pageIndicator.currentIndex //compensate spacing
                }
            }

            Grid {
                id: flowMain
                rows: 4
                height: parent.height - parent.topMargin - parent.bottomMargin
                rowSpacing: 16
                columnSpacing: 16
                flow: Flow.TopToBottom
            }
        }

        PageIndicator {
            id: pageIndicator
            currentIndex: 0

            delegate: Item {
                width: 15
                height: 15

                Rectangle {
                    anchors.centerIn: parent
                    opacity: index === pageIndicator.currentIndex ? 0.95 : pressed ? 0.7 : 0.45
                    implicitWidth: index == pageIndicator.currentIndex ? 15 : 10
                    implicitHeight: implicitWidth
                    radius: width/2
                    color: "white"
                    Behavior on opacity {
                        OpacityAnimator {
                            duration: 100
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        flickable.contentX = flickable.pageWidth * index  +
                                flowMain.rowSpacing * index //compensate spacing
                        pageIndicator.currentIndex = index
                    }
                }
            }

            interactive: false
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            count: Math.ceil(flickable.contentWidth / flickable.pageWidth)
        }
    }

    function setCurrentItemState(state) {
        var index = rowIndex + columnIndex;

        if (index >= 0 && index <= count ) {
            flowMain.children[index].state = state;
        }
    }

    function nextItem() {
        setCurrentItemState("base state");
        var nextColumnIndex = (columnIndex + 3 + 1) % 3;
        var nextIndex = rowIndex + nextColumnIndex;
        if(nextIndex <= count) {
            columnIndex = nextColumnIndex;
        };
        setCurrentItemState("hover state");
    }

    function previousItem() {
        setCurrentItemState("base state");
        var prevIndex = (columnIndex + 3 - 1) % 3;
        if((rowIndex + prevIndex) <= count){
            columnIndex = prevIndex;
        }
        setCurrentItemState("hover state");
    }

    function upItem() {
        setCurrentItemState("base state");
        rowIndex = rowIndex - 3;
        if (rowIndex < 0 ) {
            rowIndex =  (count - (count % 3));
            var index = rowIndex + columnIndex;
            if(index  > count) {
                rowIndex = rowIndex - 3;
            }
        }
        setCurrentItemState("hover state");
    }

    function downItem() {
        setCurrentItemState("base state");
        rowIndex = rowIndex + 3;
        var index = rowIndex + columnIndex;
        if (index  > count ) {
            rowIndex = 0;
        }
        setCurrentItemState("hover state");
    }

    function selectItem() {
        flowMain.children[rowIndex + columnIndex].clicked();
        if (tabletRoot) {
            tabletRoot.playButtonClickSound();
        }
    }

    Keys.onRightPressed: nextItem();
    Keys.onLeftPressed: previousItem();
    Keys.onDownPressed: downItem();
    Keys.onUpPressed: upItem();
    Keys.onReturnPressed: selectItem();
}
