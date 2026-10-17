import QtQuick
import QtQuick.Controls
import QtMultimedia
import QtCore

Window {
    id: app
    visible: true
    width: 480
    height: 800
    title: "Cámara Frontal - Qt 6.11"
    color: '#ff8833'
    property real fs: Screen.width * 0.03

    // 1. Gestión de permisos de cámara en tiempo de ejecución
    CameraPermission {
        id: cameraPermission
        onStatusChanged: {
            if (status === Qt.PermissionStatus.Granted) {
                // Damos un pequeño respiro para asegurar que el backend nativo monte los dispositivos
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
        interval: 300
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

    // Función robusta para asignar la cámara frontal o la predeterminada
    function updateCameraDevice() {
        if (cameraPermission.status !== Qt.PermissionStatus.Granted) return;

        var cams = mediaDevices.videoInputs;
        if (cams.length === 0) {
            // Si todavía no hay dispositivos listos, reintentamos en breve
            initTimer.restart();
            return;
        }

        var selectedDevice = mediaDevices.defaultVideoInput;

        for (var i = 0; i < cams.length; ++i) {
            // Buscamos explícitamente la cámara frontal
            if (cams[i].position === CameraDevice.FrontFace) {
                selectedDevice = cams[i];
                break;
            }
        }

        // Asignación segura
        if (camera.cameraDevice !== selectedDevice) {
            camera.cameraDevice = selectedDevice;
        }
        
        if (!camera.active) {
            camera.start();
        }
    }

    // 3. Sesión de captura multimedia
    CaptureSession {
        id: captureSession
        camera: Camera {
            id: camera
            active: cameraPermission.status === Qt.PermissionStatus.Granted
        }
        videoOutput: videoOutput
    }

    // 4. Salida de video
    VideoOutput {
        id: videoOutput
        //anchors.fill: parent
        width: 400
        height: 600
    }

    // Interfaz de estado
    Rectangle {
        id: xApp
        //anchors.fill: parent
        width: Screen.width-app.fs*6
        height: Screen.height-app.fs*6
        color: 'black'
        border.width: 3
        border.color: 'yellow'
        z:videoOutput.z-1
        anchors.centerIn: parent
        Column{
            id: col
            spacing: app.fs
            anchors.bottom: parent.bottom
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20
                text: cameraPermission.status === Qt.PermissionStatus.Granted ?
                          (mediaDevices.videoInputs.length === 0 ? "Buscando cámaras..." : "") :
                          "Permiso de cámara requerido"
                color: "white"
                font.pixelSize: app.fs * 3
            }
            Button{
                text: "Probar"
                onClicked:{
                    updateCameraDevice()
                }
            }
        }
    }

}
