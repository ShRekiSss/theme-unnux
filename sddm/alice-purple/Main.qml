import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: 1920
    height: 1080

    // ── Палитра (как в панели Hyprland) ──────────────────────
    readonly property color violet:  "#8b5cf6"
    readonly property color cyan:    "#22d3ee"
    readonly property color paper:   "#ece9f7"
    readonly property color dim:     "#9d94b8"
    readonly property color cardBg:  "#d9141020"

    // Русские месяцы/дни — чтобы дата была по-русски при любой локали
    readonly property var months: ["января", "февраля", "марта", "апреля", "мая", "июня",
                                   "июля", "августа", "сентября", "октября", "ноября", "декабря"]
    readonly property var days: ["воскресенье", "понедельник", "вторник", "среда",
                                 "четверг", "пятница", "суббота"]

    function dateLabel() {
        var d = new Date()
        return days[d.getDay()] + ", " + d.getDate() + " " + months[d.getMonth()]
    }

    // Тёмная подложка, чтобы не мигало белым при загрузке
    Rectangle {
        anchors.fill: parent
        color: "#0d0a14"
    }

    Image {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    // Затемнение + фиолетовый градиент поверх картинки
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#66120b1e" }
            GradientStop { position: 0.55; color: "#b3120b20" }
            GradientStop { position: 1.0; color: "#e6120b20" }
        }
    }

    // Мягкое свечение по центру
    Rectangle {
        anchors.centerIn: parent
        width: 900
        height: 900
        radius: width / 2
        color: "#12" + "8b5cf6"
    }

    // ── Карточка входа ───────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 430
        implicitHeight: content.implicitHeight + 64
        radius: 20
        color: cardBg
        border.color: "#668b5cf6"
        border.width: 1

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 32
            spacing: 14

            Text {
                id: clock
                text: Qt.formatTime(new Date(), "HH:mm")
                color: paper
                font.pixelSize: 64
                font.weight: Font.Light
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                id: dateText
                text: root.dateLabel()
                color: violet
                font.pixelSize: 14
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.5
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 8
            }

            TextField {
                id: userName
                Layout.fillWidth: true
                Layout.topMargin: 6
                placeholderText: "Имя пользователя"
                text: userModel.lastUser
                color: paper
                placeholderTextColor: dim
                font.pixelSize: 17
                selectByMouse: true
                leftPadding: 16
                rightPadding: 16
                topPadding: 12
                bottomPadding: 12
                background: Rectangle {
                    color: "#3d1a1430"
                    border.color: userName.activeFocus ? violet : "#338b5cf6"
                    border.width: 1
                    radius: 10
                }
            }

            TextField {
                id: password
                Layout.fillWidth: true
                placeholderText: "Пароль"
                echoMode: TextInput.Password
                color: paper
                placeholderTextColor: dim
                font.pixelSize: 17
                selectByMouse: true
                leftPadding: 16
                rightPadding: 16
                topPadding: 12
                bottomPadding: 12
                background: Rectangle {
                    color: "#3d1a1430"
                    border.color: password.activeFocus ? cyan : "#338b5cf6"
                    border.width: 1
                    radius: 10
                }
                onAccepted: root.doLogin()
            }

            ComboBox {
                id: sessionBox
                Layout.fillWidth: true
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
                font.pixelSize: 15
                leftPadding: 16
                rightPadding: 16
                topPadding: 10
                bottomPadding: 10
                background: Rectangle {
                    color: "#2b1a1430"
                    border.color: "#2e8b5cf6"
                    border.width: 1
                    radius: 10
                }
                contentItem: Text {
                    leftPadding: 4
                    text: sessionBox.displayText
                    color: "#c9c2e0"
                    font: sessionBox.font
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }

            Button {
                id: loginButton
                Layout.fillWidth: true
                Layout.topMargin: 6
                implicitHeight: 48
                contentItem: Text {
                    text: "Войти"
                    color: "#0d0a14"
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 10
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: loginButton.down ? "#6d3fd4" : violet }
                        GradientStop { position: 1.0; color: loginButton.down ? "#0e9fb8" : cyan }
                    }
                }
                onClicked: root.doLogin()
            }

            Text {
                id: message
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                color: "#fb7185"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                text: ""
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                spacing: 24

                Text {
                    text: "Перезагрузить"
                    color: dim
                    font.pixelSize: 13
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.reboot()
                    }
                }

                Text {
                    text: "Выключить"
                    color: dim
                    font.pixelSize: 13
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.powerOff()
                    }
                }
            }
        }
    }

    function doLogin() {
        if (userName.text.length === 0) {
            message.text = "Введите имя пользователя"
            return
        }
        message.text = ""
        sddm.login(userName.text, password.text, sessionBox.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            message.text = "Неверное имя или пароль"
            password.text = ""
            password.forceActiveFocus()
        }
        function onInformationMessage(msg) {
            message.text = msg
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            clock.text = Qt.formatTime(new Date(), "HH:mm")
            dateText.text = root.dateLabel()
        }
    }

    Component.onCompleted: {
        if (userName.text.length > 0) {
            password.forceActiveFocus()
        } else {
            userName.forceActiveFocus()
        }
    }
}
