// ══════════════════════════════════════════════════════════════
//   AURORA · SDDM theme
//   teal → violet glass · JetBrains Mono Nerd Font
// ══════════════════════════════════════════════════════════════

import QtQuick 2.15
import QtQuick.Window 2.15

Item {
    id: root

    width: Screen.width
    height: Screen.height
    focus: true

    // ── палитра ────────────────────────────────────────────────
    readonly property color cTeal:   "#5eead4"
    readonly property color cViolet: "#a78bfa"
    readonly property color cPink:   "#f472b6"
    readonly property color cText:   "#e8f0f7"
    readonly property color cMuted:  "#93a4b5"
    readonly property color cDim:    "#6f8093"
    readonly property string fontMain: "JetBrainsMono Nerd Font"

    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string lastUser: userModel.lastUser ? userModel.lastUser : "studen"

    function prettyUser(u) {
        return u && u.length > 0 ? u.charAt(0).toUpperCase() + u.slice(1) : "Гость";
    }

    function greeting(h) {
        if (h >= 5 && h < 12)  return "Доброе утро";
        if (h >= 12 && h < 17) return "Добрый день";
        if (h >= 17 && h < 23) return "Добрый вечер";
        return "Доброй ночи";
    }

    function shortSession(name) {
        if (!name) return "";
        if (name.indexOf("uwsm") !== -1) return "Hyprland · uwsm";
        if (name.indexOf("Hyprland") !== -1) return "Hyprland";
        if (name.indexOf("Xfce") !== -1)
            return name.indexOf("Wayland") !== -1 ? "Xfce Wayland" : "Xfce";
        if (name === "Сеанс" || name === "Session") return "Xfce";
        if (name.indexOf("Default") !== -1) return "X11";
        if (name.length > 18) return name.substring(0, 17) + "…";
        return name;
    }

    function showError(msg) {
        errorText.text = msg;
    }

    function login() {
        errorText.text = "";
        var user = userField.text.trim();
        if (user.length === 0) {
            showError("Введите имя пользователя");
            userField.forceActiveFocus();
            return;
        }
        if (passField.text.length === 0) {
            showError("Введите пароль");
            passField.forceActiveFocus();
            return;
        }
        sddm.login(user, passField.text, sessionIndex);
    }

    // ── фон ────────────────────────────────────────────────────
    Image {
        id: background
        anchors.fill: parent
        source: "Backgrounds/aurora.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        smooth: true
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#59040811" }
            GradientStop { position: 0.55; color: "#4004070d" }
            GradientStop { position: 1.0; color: "#cc030509" }
        }
    }

    // дополнительное затемнение слева — под часы
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#73050a12" }
            GradientStop { position: 0.55; color: "#00050a12" }
        }
    }

    // ── часы / приветствие ─────────────────────────────────────
    Column {
        id: hero
        anchors.left: parent.left
        anchors.leftMargin: Math.max(64, root.width * 0.075)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(56, root.height * 0.10)
        spacing: 4
        opacity: 0

        Text {
            id: greetingLabel
            text: root.greeting(new Date().getHours())
            color: root.cMuted
            font.family: root.fontMain
            font.pixelSize: Math.round(Math.max(15, Math.min(22, root.height * 0.024)))
            font.letterSpacing: 0.6
        }

        Text {
            id: timeLabel
            text: Qt.formatTime(new Date(), "HH:mm")
            color: "#f4fbff"
            font.family: root.fontMain
            font.pixelSize: Math.round(Math.max(64, Math.min(148, root.height * 0.145)))
            font.weight: Font.Light
            font.letterSpacing: -2
        }

        Text {
            id: dateLabel
            text: Qt.formatDate(new Date(), Qt.locale("ru_RU"), "dddd, d MMMM")
            color: root.cMuted
            font.family: root.fontMain
            font.pixelSize: Math.round(Math.max(13, Math.min(19, root.height * 0.021)))
            font.letterSpacing: 1.2
        }

        Item { width: 1; height: 18 }

        Row {
            spacing: 12

            Rectangle {
                width: 34
                height: 3
                radius: 2
                anchors.verticalCenter: parent.verticalCenter
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: root.cTeal }
                    GradientStop { position: 1.0; color: root.cViolet }
                }
            }

            Text {
                text: "AURORA  ·  HYPRLAND"
                color: root.cDim
                font.family: root.fontMain
                font.pixelSize: 11
                font.letterSpacing: 2.4
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // ── карточка входа ─────────────────────────────────────────
    Rectangle {
        id: card
        width: Math.min(410, root.width * 0.34)
        height: 556
        anchors.right: parent.right
        anchors.rightMargin: Math.max(48, root.width * 0.068)
        anchors.verticalCenter: parent.verticalCenter
        radius: 26
        color: "#c00a1018"
        border.width: 1
        border.color: "#335eead4"
        opacity: 0
        scale: 0.97
        transformOrigin: Item.Center

        // верхний градиентный блик
        Rectangle {
            width: 120
            height: 3
            radius: 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 22
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: root.cTeal }
                GradientStop { position: 1.0; color: root.cViolet }
            }
        }

        // аватар
        Image {
            id: avatar
            width: 96
            height: 96
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 46
            source: "Assets/avatar.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        Text {
            id: userName
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: avatar.bottom
            anchors.topMargin: 12
            text: root.prettyUser(root.lastUser)
            color: root.cText
            font.family: root.fontMain
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: userName.bottom
            anchors.topMargin: 5
            text: "ВХОД В СИСТЕМУ"
            color: root.cDim
            font.family: root.fontMain
            font.pixelSize: 10
            font.letterSpacing: 3
        }

        // ── пользователь ───────────────────────────────────────
        Text {
            id: userLabel
            anchors.left: parent.left
            anchors.leftMargin: 32
            anchors.top: parent.top
            anchors.topMargin: 215
            text: "ПОЛЬЗОВАТЕЛЬ"
            color: root.cDim
            font.family: root.fontMain
            font.pixelSize: 10
            font.letterSpacing: 2
        }

        Rectangle {
            id: userBox
            height: 44
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 32
            anchors.rightMargin: 32
            anchors.top: userLabel.bottom
            anchors.topMargin: 7
            radius: 11
            color: "#66141d27"
            border.width: 1
            border.color: userField.activeFocus ? "#995eead4" : "#1affffff"

            Behavior on border.color { ColorAnimation { duration: 140 } }

            TextInput {
                id: userField
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                verticalAlignment: TextInput.AlignVCenter
                color: root.cText
                font.family: root.fontMain
                font.pixelSize: 14
                selectionColor: root.cTeal
                selectedTextColor: "#04120f"
                onAccepted: passField.forceActiveFocus()

                Keys.onEscapePressed: {
                    text = root.lastUser;
                    event.accepted = true;
                }
            }
        }

        // ── пароль ─────────────────────────────────────────────
        Text {
            id: passLabel
            anchors.left: parent.left
            anchors.leftMargin: 32
            anchors.top: userBox.bottom
            anchors.topMargin: 16
            text: "ПАРОЛЬ"
            color: root.cDim
            font.family: root.fontMain
            font.pixelSize: 10
            font.letterSpacing: 2
        }

        Rectangle {
            id: passBox
            height: 44
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 32
            anchors.rightMargin: 32
            anchors.top: passLabel.bottom
            anchors.topMargin: 7
            radius: 11
            color: "#66141d27"
            border.width: 1
            border.color: passField.activeFocus ? "#995eead4" : "#1affffff"

            Behavior on border.color { ColorAnimation { duration: 140 } }

            TextInput {
                id: passField
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "●"
                passwordMaskDelay: 0
                color: root.cText
                font.family: root.fontMain
                font.pixelSize: 14
                selectionColor: root.cTeal
                selectedTextColor: "#04120f"
                onAccepted: root.login()

                Keys.onEscapePressed: {
                    text = "";
                    errorText.text = "";
                    event.accepted = true;
                }
            }

            Text {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                verticalAlignment: Text.AlignVCenter
                text: "Пароль"
                color: root.cDim
                font.family: root.fontMain
                font.pixelSize: 14
                visible: passField.text.length === 0 && !passField.activeFocus
            }
        }

        // ── ошибка ─────────────────────────────────────────────
        Text {
            id: errorText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: passBox.bottom
            anchors.topMargin: 10
            height: 16
            text: ""
            color: root.cPink
            font.family: root.fontMain
            font.pixelSize: 12
            opacity: text.length > 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
        }

        // ── кнопка входа ───────────────────────────────────────
        Rectangle {
            id: loginBtn
            height: 50
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 32
            anchors.rightMargin: 32
            anchors.top: errorText.bottom
            anchors.topMargin: 6
            radius: 13
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: root.cTeal }
                GradientStop { position: 1.0; color: root.cViolet }
            }
            scale: loginMouse.pressed ? 0.985 : 1.0
            opacity: loginMouse.containsMouse ? 0.92 : 1.0

            Behavior on scale   { NumberAnimation { duration: 90 } }
            Behavior on opacity { NumberAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: "Войти"
                color: "#04120f"
                font.family: root.fontMain
                font.pixelSize: 15
                font.weight: Font.Bold
                font.letterSpacing: 0.6
            }

            MouseArea {
                id: loginMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.login()
            }
        }

        // ── сессии ─────────────────────────────────────────────
        Flow {
            id: sessionRow
            width: parent.width - 64
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: loginBtn.bottom
            anchors.topMargin: 16
            spacing: 7

            Repeater {
                model: sessionModel

                delegate: Rectangle {
                    height: 28
                    width: sessionText.implicitWidth + 24
                    radius: 14
                    color: root.sessionIndex === index ? "#2e5eead4" : "#0fffffff"
                    border.width: 1
                    border.color: root.sessionIndex === index ? "#665eead4" : "#14ffffff"

                    Text {
                        id: sessionText
                        anchors.centerIn: parent
                        text: root.shortSession(model.name)
                        color: root.sessionIndex === index ? root.cTeal : root.cMuted
                        font.family: root.fontMain
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.sessionIndex = index
                    }
                }
            }
        }

        // ── питание ────────────────────────────────────────────
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            spacing: 10

            Rectangle {
                width: 38; height: 38; radius: 19
                color: powerSuspend.containsMouse ? "#1f22d3ee" : "#0fffffff"
                border.width: 1
                border.color: powerSuspend.containsMouse ? "#5522d3ee" : "#14ffffff"
                visible: sddm.canSuspend

                Text {
                    anchors.centerIn: parent
                    text: "\uf186"
                    color: root.cMuted
                    font.family: root.fontMain
                    font.pixelSize: 14
                }

                MouseArea {
                    id: powerSuspend
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.suspend()
                }
            }

            Rectangle {
                width: 38; height: 38; radius: 19
                color: powerReboot.containsMouse ? "#1fa78bfa" : "#0fffffff"
                border.width: 1
                border.color: powerReboot.containsMouse ? "#55a78bfa" : "#14ffffff"
                visible: sddm.canReboot

                Text {
                    anchors.centerIn: parent
                    text: "\uf021"
                    color: root.cMuted
                    font.family: root.fontMain
                    font.pixelSize: 14
                }

                MouseArea {
                    id: powerReboot
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.reboot()
                }
            }

            Rectangle {
                width: 38; height: 38; radius: 19
                color: powerOff.containsMouse ? "#1ff472b6" : "#0fffffff"
                border.width: 1
                border.color: powerOff.containsMouse ? "#55f472b6" : "#14ffffff"
                visible: sddm.canPowerOff

                Text {
                    anchors.centerIn: parent
                    text: "\uf011"
                    color: root.cMuted
                    font.family: root.fontMain
                    font.pixelSize: 14
                }

                MouseArea {
                    id: powerOff
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.powerOff()
                }
            }
        }
    }

    // ── сигналы SDDM ───────────────────────────────────────────
    Connections {
        target: sddm

        function onLoginFailed() {
            root.showError("Неверный пароль — попробуйте ещё раз");
            passField.text = "";
            passField.forceActiveFocus();
        }

        function onInformationMessage(message) {
            root.showError(message);
        }
    }

    // ── часы ───────────────────────────────────────────────────
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var d = new Date();
            timeLabel.text = Qt.formatTime(d, "HH:mm");
            dateLabel.text = Qt.formatDate(d, Qt.locale("ru_RU"), "dddd, d MMMM");
            greetingLabel.text = root.greeting(d.getHours());
        }
    }

    // ── появление ──────────────────────────────────────────────
    ParallelAnimation {
        id: intro
        NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 500; easing.type: Easing.OutCubic }
        NumberAnimation { target: card; property: "scale";   from: 0.97; to: 1; duration: 500; easing.type: Easing.OutCubic }
        NumberAnimation { target: hero; property: "opacity"; from: 0; to: 1; duration: 650; easing.type: Easing.OutCubic }
    }

    Component.onCompleted: {
        userField.text = root.lastUser;
        if (root.lastUser.length > 0)
            passField.forceActiveFocus();
        else
            userField.forceActiveFocus();
        intro.start();
    }
}
