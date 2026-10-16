import QtQuick gg
import QtMultimedia
import QtCore
import unik.Unik 1.0

Window {
    id: window
    visible: true
    width: 480
    height: 800
    title: "Cámara Frontal - Qt 6.11"
    color: 'red'
    property real fs: Screen.width * 0.03

    Settings{
        id: apps
        property bool autoLoad: false
    }
    // 1. Gestión de permisos de cámara en tiempo de ejecución
    CameraPermission {
        id: cameraPermission
        onStatusChanged: {
            if (status === Qt.PermissionStatus.Granted) {
                updateCameraDevice()
            }
        }
    }
    Component.onCompleted: {
        if (cameraPermission.status === Qt.PermissionStatus.Granted) {
            updateCameraDevice()
        } else {
            cameraPermission.request()
        }
    }

    // 2. Dispositivos multimedia
    MediaDevices {
        id: mediaDevices
        // Forzar actualización al cambiar la lista de entradas de video
        onVideoInputsChanged: {
            updateCameraDevice()
        }
    }

    // Función segura para asignar la cámara frontal
    function updateCameraDevice() {
        if (cameraPermission.status !== Qt.PermissionStatus.Granted) return;

        var cams = mediaDevices.videoInputs;
        for (var i = 0; i < cams.length; ++i) {
            // Buscamos explícitamente la cámara frontal
            if (cams[i].position === CameraDevice.FrontFace) {
                camera.cameraDevice = cams[i];
                camera.start();
                return;
            }
        }

        // Si no encuentra la frontal específica, usa la que esté disponible por defecto
        if (cams.length > 0) {
            camera.cameraDevice = mediaDevices.defaultVideoInput;
            camera.start();
        }
    }

    // 3. Sesión de captura multimedia
    CaptureSession {
        id: captureSession
        camera: Camera {
            id: camera
            // El active se controla de manera segura mediante la función
            active: cameraPermission.status === Qt.PermissionStatus.Granted
        }
        videoOutput: videoOutput
    }

    // 4. Salida de video ocupando toda la pantalla de fondo
    VideoOutput {
        id: videoOutput
        //anchors.fill: parent
        width: 500
        height: 800
        visible: false
    }

    // Interfaz superpuesta (por si deseas agregar botones o controles encima)
    Item {
        id: xApp
        anchors.fill: parent
        //anchors.margins: window.fs * 2

        // Ejemplo: Texto indicador de estado si la cámara no inicia
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            text: cameraPermission.status === Qt.PermissionStatus.Granted ?
                  (mediaDevices.videoInputs.length === 0 ? "Buscando cámaras..." : "") :
                  "Permiso de cámara requerido"
            color: "white"
            font.pixelSize: window.fs * 1.2
            style: Text.Outline; styleColor: "black"
        }
        Button{
            text: apps.autoLoad?'No AutoLoad':'AutoLoad'
            onClicked:{
                apps.autoLoad=!apps.autoLoad
            }
        }
    }

    // Sistema de Logs en pantalla para depuración de errores QML
    Connections {
        target: typeof qmlErrorLogger !== 'undefined' ? qmlErrorLogger : null
        ignoreUnknownSignals: true
        onMessagesChanged: {
            if (typeof qmlErrorLogger !== 'undefined' && qmlErrorLogger.messages.length > 0) {
                log.text += '' + qmlErrorLogger.messages[qmlErrorLogger.messages.length - 1] + '<br>';
                xLog.visible = true;
            }
        }
    }

    Rectangle {
        id: xLog
        color: "rgba(0, 0, 0, 0.8)"
        anchors.fill: parent
        visible: false
        z: 100

        Flickable {
            width: parent.width - window.fs * 4
            height: parent.height - window.fs * 6
            contentWidth: width
            contentHeight: log.contentHeight
            anchors.centerIn: parent

            Text {
                id: log
                width: parent.width
                color: "white"
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
            }
        }

        Rectangle {
            width: window.fs * 3
            height: window.fs * 3
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: window.fs
            color: "red"
            MouseArea {
                anchors.fill: parent
                onClicked: xLog.visible = false
            }
            Text {
                text: "X"
                font.pixelSize: parent.width * 0.6
                color: 'white'
                anchors.centerIn: parent
            }
        }
    }
}
