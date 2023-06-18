import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15
import Qt.labs.platform 1.1

import gui 1.0
import "../../style"
import "../../components"

Item {
    id: root

    function tr(str, file = "BasicInputs.qml") {
        return TRANSLATOR.instance.translate(str, file)
    }

    ListView {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        id: inputListView
        interactive: false
        boundsBehavior: Flickable.StopAtBounds
        clip:true
        orientation: Qt.Horizontal
        width: Math.min(contentWidth, parent.width)
        model: BASIC.inputs

        ScrollBar.horizontal: SScrollBarH { 
            id: scrollBar
            stepSize: 1/(4*Math.ceil(BASIC.inputs.length))
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: {
                if(wheel.angleDelta.y < 0) {
                    scrollBar.increase()
                } else {
                    scrollBar.decrease()
                }
            }
        }

        Connections {
            target: BASIC
            function onOpenedUpdated() {
                if(BASIC.openedArea == "input") {
                    inputListView.currentIndex = BASIC.openedIndex
                    inputListView.positionViewAtIndex(inputListView.currentIndex, ListView.Center)
                }
            }
        }

        delegate: Item {
            id: item
            height: Math.floor(inputListView.height)
            width: height-9
            property var input: modelData

            onActiveFocusChanged: {
                if(activeFocus) {
                    itemFrame.forceActiveFocus()
                }
            }

            Rectangle {
                id: itemFrame
                anchors.fill: parent
                anchors.margins: 9
                anchors.leftMargin: 0
                color: COMMON.bg00
                clip: false

                property var highlight: activeFocus || inputContextMenu.opened || inputFileDialog.visible || centerDrop.containsDrag
                property var settings: false
                
                Item {
                    anchors.fill: parent

                    Rectangle {
                        visible: modelData.linked
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: -4
                        anchors.right: trueFrame.left
                        height: parent.height/4
                        color: COMMON.fg2

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: 1
                            color: COMMON.fg3
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: COMMON.fg3
                        }
                    }

                    Rectangle {
                        visible: modelData.linkedTo
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: -5
                        anchors.left: trueFrame.right
                        height: parent.height/4
                        color: COMMON.fg2
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: 1
                            color: COMMON.fg3
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: COMMON.fg3
                        }
                    }


                    RectangularGlow {
                        visible: trueFrame.valid
                        anchors.fill: trueFrame
                        glowRadius: 5
                        opacity: 0.4
                        spread: 0.2
                        color: "black"
                        cornerRadius: 10
                    }

                    TransparencyShader {
                        visible: trueFrame.valid
                        anchors.fill: trueFrame
                    }

                    Item {
                        anchors.fill: parent
                        anchors.margins: 1
                        ImageDisplay {
                            id: itemImage
                            visible: !modelData.empty
                            anchors.fill: parent
                            image: modelData.display
                            centered: true
                        }
                    }

                    Item {
                        id: trueFrame
                        property var valid: itemImage.trueWidth != 0
                        x: valid ? itemImage.trueX + 1: 0
                        y: valid ? itemImage.trueY + 1: 0
                        width: valid ? itemImage.trueWidth : parent.width
                        height: valid ? itemImage.trueHeight : parent.height

                        Rectangle {
                            visible: itemImage.sourceWidth > 0
                            property var factor: parent.width/itemImage.sourceWidth
                            border.color: modelData.extentWarning ? "red" : "#00ff00"
                            border.width: 1
                            color: "transparent"

                            x: modelData.extent.x*factor
                            y: modelData.extent.y*factor
                            width: Math.floor(modelData.extent.width*factor)
                            height: Math.floor(modelData.extent.height*factor)
                        }
                    }

                    Item {
                        id: borderFrame
                        property var valid: itemImage.trueWidth != 0
                        x: valid ? itemImage.trueX: 0
                        y: valid ? itemImage.trueY: 0
                        width: valid ? itemImage.trueWidth+2 : parent.width
                        height: valid ? itemImage.trueHeight+2 : parent.height
                        

                        Rectangle {
                            anchors.fill: roleLabel
                            color: "#e0101010"
                            border.width: 1
                            border.color: COMMON.bg3
                        }

                        SText {
                            id: roleLabel
                            text: root.tr(modelData.displayName, "Role")
                            anchors.top: parent.top
                            anchors.left: parent.left
                            leftPadding: 3
                            topPadding: 3
                            rightPadding: 3
                            bottomPadding: 3
                            color: COMMON.fg1_5
                            font.pointSize: 9.8
                        }

                        Rectangle {
                            visible: modeLabel.visible
                            anchors.fill: modeLabel
                            color: "#e0101010"
                            border.width: 1
                            border.color: COMMON.bg3
                        }

                        SText {
                            id: modeLabel
                            text: root.tr(modelData.mode)
                            visible: text != ""
                            anchors.top: roleLabel.bottom
                            anchors.topMargin: -1
                            anchors.left: parent.left
                            leftPadding: 3
                            topPadding: 3
                            rightPadding: 3
                            bottomPadding: 3
                            color: COMMON.fg1_5
                            font.pointSize: 9.8
                        }

                        Rectangle {
                            visible: sizeLabel.text != ""
                            anchors.fill: sizeLabel
                            color: "#e0101010"
                            border.width: 1
                            border.color: COMMON.bg3
                        }

                        SText {
                            id: sizeLabel
                            text: modelData.size
                            anchors.top: parent.top
                            anchors.right: parent.right
                            height: roleLabel.height
                            leftPadding: 3
                            topPadding: 3
                            rightPadding: 3
                            bottomPadding: 3
                            color: COMMON.fg1_5
                            font.pointSize: 9.2
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            width: 21
                            height: 22
                            visible: settingsButton.visible
                            color: "#e0101010"
                            border.width: 1
                            border.color: COMMON.bg3
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            width: 21
                            height: 22
                            visible: refreshButton.visible
                            color: "#e0101010"
                            border.width: 1
                            border.color: COMMON.bg3
                        }
                    }

                    Rectangle {
                        anchors.fill: borderFrame
                        border.color: itemFrame.highlight ? COMMON.fg2 : COMMON.bg4
                        border.width: 1
                        color: "transparent"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    property var startPosition: Qt.point(0,0)
                    property var startOffset: 0
                    property bool ready: false
                    property var image
                    onPressed: {
                        startPosition = Qt.point(mouse.x, mouse.y)
                        startOffset = modelData.offset
                        if (mouse.button == Qt.LeftButton) {
                            inputListView.currentIndex = index
                            itemFrame.forceActiveFocus()
                            ready = false
                            itemFrame.grabToImage(function(result) {
                                image = result.image;
                                ready = true
                            })
                        }
                        if (mouse.button == Qt.RightButton) {
                            inputContextMenu.popup()
                        }
                    }

                    onDoubleClicked: {
                        if(!modelData.empty) {
                            BASIC.open(index, "input")
                        }
                    }

                    onPositionChanged: {
                        if((pressedButtons & Qt.LeftButton) && ready) {
                            var delta = Qt.point(mouse.x-startPosition.x, mouse.y-startPosition.y)
                            if(Math.pow(delta.x*delta.x + delta.y*delta.y, 0.5) > 5) {
                                modelData.drag(index, image)
                            }
                        }
                        if(pressedButtons & Qt.MiddleButton) {
                            var d = 0
                            var z = 0
                            if(modelData.offsetDirection) {
                                d = mouse.y-startPosition.y
                                z = ((trueFrame.width/modelData.originalWidth)*modelData.originalHeight) - trueFrame.height
                            } else {
                                d = mouse.x-startPosition.x
                                z = ((trueFrame.height/modelData.originalHeight)*modelData.originalWidth) - trueFrame.width
                            }

                            modelData.offset = startOffset - (d/z)
                        }
                    }

                    SContextMenu {
                        y: 35
                        id: inputContextMenu
                        width: 100
                        SContextMenuItem {
                            visible: !modelData.empty
                            text: root.tr("Save", "General")
                            onPressed: {
                                saveDialog.open()
                            }
                        }

                        SContextMenuSeparator {
                            visible: !modelData.empty
                        }

                        SContextMenuItem {
                            text: root.tr("Clear", "General")
                            onPressed: {
                                BASIC.deleteInput(index)
                            }
                        }
                        
                        SContextMenu {
                            width: 90
                            title: root.tr("Set role")
                            SContextMenuItem {
                                text: root.tr("Image", "Role")
                                onPressed: {
                                    modelData.role = 1
                                }
                            }
                            SContextMenuItem {
                                text: root.tr("Mask", "Role")
                                onPressed: {
                                    modelData.role = 2
                                }
                            }
                            SContextMenu {
                                title: root.tr("Control", "Role")
                                width: 100
                                Repeater {
                                    id: controlRepeater
                                    property var tmp: BASIC.parameters.values.get("CN_modes")
                                    model: tmp
                                    SContextMenuItem {
                                        text: root.tr(modelData, "Role")
                                        onPressed: {
                                            item.input.role = 4
                                            item.input.settings.set("mode", modelData)
                                        }
                                    }
                                }
                                SContextMenuItem {
                                    visible: BASIC.parameters.values.get("CN_modes").length == 0
                                    text: root.tr("Download")
                                    onPressed: {
                                        GUI.openLink("https://huggingface.co/lllyasviel/ControlNet-v1-1/tree/main")
                                    }
                                }
                            }
                        }
                    }

                    FileDialog {
                        id: saveDialog
                        title: root.tr("Save image", "General")
                        nameFilters: [root.tr("Image files") + " (*.png)"]
                        fileMode: FileDialog.SaveFile
                        defaultSuffix: "png"
                        onAccepted: {
                            input.saveImage(saveDialog.file)
                        }
                    }
                }

                Rectangle {
                    visible: settingsArea.visible
                    x: borderFrame.x + 1
                    y: borderFrame.y + borderFrame.height - settingsArea.height
                    width: borderFrame.width - 2
                    height: settingsArea.height - 22
                    color: "#e0101010"
                }

                SIconButton {
                    id: settingsButton
                    visible: modelData.role == 4 && !modelData.empty
                    color: "transparent"
                    icon: "qrc:/icons/settings.svg"
                    x: borderFrame.x + 1
                    y: borderFrame.y + borderFrame.height - 20.5
                    height: 20
                    width: 20
                    inset: 5

                    onPressed: {
                        parent.settings = !parent.settings
                    }
                }

                SIconButton {
                    id: refreshButton
                    visible: modelData.role == 4 && !modelData.empty
                    color: "transparent"
                    icon: "qrc:/icons/refresh.svg"
                    x: borderFrame.x + borderFrame.width - 20
                    y: borderFrame.y + borderFrame.height - 20
                    height: 20
                    width: 20
                    inset: 5

                    onPressed: {
                        modelData.annotate()
                    }

                    onContextMenu: {
                        modelData.resetDisplay()
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 5

                    SIconButton {
                        visible: modelData.empty
                        id: uploadButton
                        icon: "qrc:/icons/folder.svg"
                        onPressed: {
                            itemFrame.forceActiveFocus()
                            inputFileDialog.open()
                        }
                        border.color: COMMON.bg4
                        border.width: 1
                        color: COMMON.bg1
                    }

                    SIconButton {
                        visible: modelData.empty && (modelData.role == 2 || modelData.role == 3)
                        id: paintButton
                        icon: "qrc:/icons/paint.svg"
                        onPressed: {
                            itemFrame.forceActiveFocus()
                            modelData.setImageCanvas()
                        }
                        border.color: COMMON.bg4
                        border.width: 1
                        color: COMMON.bg1
                    }
                }

                Item {
                    id: settingsArea
                    visible: parent.settings && !modelData.empty && modelData.role == 4
                    x: borderFrame.x + 20
                    y: borderFrame.y + borderFrame.height - height
                    width: borderFrame.width - 40
                    height: settingsColumn.implicitHeight + 2 + Math.min(0, width - 170)*2
                    clip: true
                    
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        color: COMMON.bg0
                    }

                    Column {
                        id: settingsColumn
                        anchors.fill: parent
                        opacity: 0.85
                        OChoice {
                            label: root.tr("Preprocessor")
                            width: parent.width
                            height: 22

                            bindMap: modelData.settings
                            bindKeyCurrent: "CN_preprocessor"
                            bindKeyModel: "CN_preprocessors"
                        }
                        OChoice {
                            visible: label != ""
                            width: parent.width
                            height: visible ? 22 : 0

                            bindMap: modelData.settings
                            bindKeyCurrent: "CN_bool"
                            bindKeyModel: "CN_bools"
                            bindKeyLabel: "CN_bool_label"

                            function label_display(text) {
                                return root.tr(text)
                            }
                        }
                        OSlider {
                            visible: label != ""
                            width: parent.width
                            height: visible ? 22 : 0

                            bindMap: modelData.settings
                            bindKey: "CN_slider_a"
                            bindKeyLabel: "CN_slider_a_label"

                            function label_display(text) {
                                return root.tr(text)
                            }

                            minValue: 0
                            maxValue: 1
                            precValue: 2
                            incValue: 0.01
                            snapValue: 0.05
                        }
                        OSlider {
                            visible: label != ""
                            width: parent.width
                            height: visible ? 22 : 0

                            bindMap: modelData.settings
                            bindKey: "CN_slider_b"
                            bindKeyLabel: "CN_slider_b_label"

                            function label_display(text) {
                                return root.tr(text)
                            }

                            minValue: 0
                            maxValue: 1
                            precValue: 2
                            incValue: 0.01
                            snapValue: 0.05
                        }
                        OSlider {
                            width: parent.width
                            height: 22
                            label: root.tr("Strength")

                            bindMap: modelData.settings
                            bindKey: "CN_strength"

                            minValue: 0
                            maxValue: 1
                            precValue: 2
                            incValue: 0.01
                            snapValue: 0.05
                        }
                    }
                }

                FileDialog {
                    id: inputFileDialog
                    nameFilters: [root.tr("Image files") + " (*.png *.jpg *.jpeg)"]

                    onAccepted: {
                        modelData.setImageFile(inputFileDialog.file)
                    }
                }

                AdvancedDropArea {
                    id: leftDrop
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 10 + 5
                    anchors.leftMargin: -5

                    onDropped: {
                        BASIC.addDrop(mimeData, index)
                    }

                    Rectangle {
                        visible: leftDrop.containsDrag
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        color: COMMON.fg2
                    }
                }

                AdvancedDropArea {
                    id: centerDrop
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 20

                    onDropped: {
                        modelData.setImageDrop(mimeData, index)
                    }
                }

                AdvancedDropArea {
                    id: rightDrop
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: -5
                    width: 10 + 5

                    onDropped: {
                        BASIC.addDrop(mimeData, index+1)
                    }

                    Rectangle {
                        visible: rightDrop.containsDrag
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        color: COMMON.fg2
                    }
                }

                Keys.onPressed: {
                    event.accepted = true
                    if(event.modifiers & Qt.ControlModifier) {
                        switch(event.key) {
                        case Qt.Key_C:
                            BASIC.copyItem(index, "input")
                            break;
                        case Qt.Key_V:
                            BASIC.pasteItem(index, "input")
                            break;
                        default:
                            event.accepted = false
                            break;
                        }
                    } else {
                        switch(event.key) {
                        case Qt.Key_Delete:
                            modelData.clearImage()
                            BASIC.deleteInput(index)
                            break;
                        default:
                            event.accepted = false
                            break;
                        }
                    }
                }
            }
        }

        header: Item {
            height: parent.height
            width: 9
        }

        footer:  Item {
            height: parent.height
            width: height-9
            Rectangle {
                id: itmFooter
                anchors.fill: parent
                anchors.margins: 9
                anchors.leftMargin: 0
                color: "transparent"
                border.width: 1
                border.color: (itmFooter.activeFocus || addDrop.containsDrag) ? COMMON.bg6 : "transparent"

                RectangularGlow {
                    anchors.fill: addButton
                    glowRadius: 5
                    opacity: 0.3
                    spread: 0.2
                    color: "black"
                    cornerRadius: 10
                }

                Rectangle {
                    anchors.fill: addButton
                    border.color: COMMON.bg4
                    border.width: 1
                    color: COMMON.bg1
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: {
                        itmFooter.forceActiveFocus()
                    }
                }

                SIconButton {
                    id: addButton
                    icon: "qrc:/icons/plus.svg"
                    color: "transparent"
                    anchors.centerIn: parent

                    onPressed: {
                        addContextMenu.open()
                    }

                    SContextMenu {
                        y: 34
                        id: addContextMenu
                        width: 110
                        clipShadow: true
                        SContextMenuItem {
                            text: root.tr("Image", "Role")
                            onPressed: {
                                BASIC.addImage()
                                addContextMenu.close()
                            }
                        }
                        SContextMenuItem {
                            text: root.tr("Mask", "Role")
                            onPressed: {
                                BASIC.addMask()
                                addContextMenu.close()
                            }
                        }
                        SContextMenuItem {
                            text: root.tr("Subprompts", "Role")
                            onPressed: {
                                BASIC.addSubprompt()
                                addContextMenu.close()
                            }
                        }
                        SContextMenu {
                            title: root.tr("Control", "Role")
                            width: 100
                            Repeater {
                                id: controlRepeater
                                property var tmp: BASIC.parameters.values.get("CN_modes")
                                model: tmp
                                SContextMenuItem {
                                    text: root.tr(modelData, "Role")
                                    onPressed: {
                                        BASIC.addControl(modelData)
                                        addContextMenu.close()
                                    }
                                }
                            }
                            SContextMenuItem {
                                visible: BASIC.parameters.values.get("CN_modes").length == 0
                                text: root.tr("Download")
                                onPressed: {
                                    GUI.openLink("https://huggingface.co/lllyasviel/ControlNet-v1-1/tree/main")
                                }
                            }
                        }
                    }
                }

                AdvancedDropArea {
                    id: addDrop
                    anchors.fill: parent

                    onDropped: {
                        BASIC.addDrop(mimeData, -1)
                    }
                }

                Keys.onPressed: {
                    event.accepted = true
                    if(event.modifiers & Qt.ControlModifier) {
                        switch(event.key) {
                        case Qt.Key_V:
                            BASIC.pasteItem(-1, "input")
                            break;
                        default:
                            event.accepted = false
                            break;
                        }
                    }
                }
            }
        }
    }
}