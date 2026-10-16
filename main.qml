import QtQuick
import QtMultimedia
import QtCore

Window {
    id: window
    visible: true
    width: 480
    height: 800
    title: "Cámara Frontal - Qt 6.11"
    color: 'red'
    property real fs: Screen.width * 0.03

    // 1. Gestión de permisos de cámara en tiempo de ejecución
    CameraPermission {
        id: cameraPermission
        onStatusChanged: {
            if (status === Qt.PermissionStatus.Granted) {
                initTimer.restart();
            }
        }
    }

    Component.onCompleted: {
        if (cameraPermission.status === Qt.PermissionStatus.Granted) {
            initTimer.restart();
        } else {
            cameraPermission.request();
        }
    }

    // Timer de retardo para la inicialización segura del hardware en Android
    Timer {
        id: initTimer
        interval: 400 // Un poco más de margen para que Android exponga los lentes
        repeat: false
        onTriggered: updateCameraDevice()
    }

    // 2. Dispositivos multimedia
    MediaDevices {
        id: mediaDevices
        onVideoInputsChanged: {
            updateCameraDevice();
        }
    }

    // Función robusta para forzar la selección de la cámara frontal
    function updateCameraDevice() {
        if (cameraPermission.status !== Qt.PermissionStatus.Granted) return;

        var cams = mediaDevices.videoInputs;
        if (cams.length === 0) {
            initTimer.restart();
            return;
        }

        var frontCamera = null;

        // Buscamos de forma estricta la cámara frontal
        for (var i = 0; i < cams.length; ++i) {
            console.log("Cámara detectada:", cams[i].description, "Posición:", cams[i].position);
            if (cams[i].position === CameraDevice.FrontFace) {
                frontCamera = cams[i];
                break;
            }
        }

        // Si por alguna razón el hardware no reportó el enum FrontFace exacto,
        // tomamos la segunda cámara como alternativa (usualmente la frontal en móviles)
        if (!frontCamera) {
            frontCamera = cams.length > 1 ? cams[1] : cams[0];
        }

        // Asignamos y encendemos la cámara explícitamente
        camera.cameraDevice = frontCamera;

        if (!camera.active) {
            camera.active = true;
        }
    }

    // 3. Sesión de captura multimedia
    CaptureSession {
        id: captureSession
        camera: Camera {
            id: camera
            active: false // La iniciamos apagada para controlarla desde updateCameraDevice
        }
        videoOutput: videoOutput
    }

    // 4. Salida de video
    VideoOutput {
        id: videoOutput
        anchors.fill: parent
    }

    // Interfaz de estado
    Item {
        id: xApp
        anchors.fill: parent

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
    }
}