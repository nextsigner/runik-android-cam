import QtQuick
import QtMultimedia

Window {
    id: window
    visible: true
    width: 480
    height: 800
    title: "Cámara Frontal - Qt 6"
    color: "black" // Cambiamos a negro para notar si el video fluye

    // 1. Permiso nativo de Qt 6
    CameraPermission {
        id: cameraPermission
        onStatusChanged: {
            if (status === Qt.PermissionStatus.Granted) {
                // Activamos la cámara de forma segura cuando el permiso es concedido
                camera.active = true;
            }
        }
    }

    Component.onCompleted: {
        if (cameraPermission.status === Qt.PermissionStatus.Granted) {
            camera.active = true;
        } else {
            cameraPermission.request();
        }
    }

    // 2. Sesión y dispositivos
    CaptureSession {
        id: captureSession
        camera: Camera {
            id: camera
            active: false // Arranca apagada hasta tener permisos

            // Selección directa de la cámara frontal usando MediaDevices
            cameraDevice: {
                var devices = MediaDevices.videoInputs;
                for (var i = 0; i < devices.length; ++i) {
                    if (devices[i].position === CameraDevice.FrontFace) {
                        return devices[i];
                    }
                }
                // Si no encuentra la frontal explícitamente, usa la predeterminada para evitar cuelgues
                return MediaDevices.defaultVideoInput;
            }
        }
        videoOutput: videoOutput
    }

    // 3. Salida de video en pantalla completa
    VideoOutput {
        id: videoOutput
        anchors.fill: parent
    }

    // Texto de estado simple
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        text: cameraPermission.status === Qt.PermissionStatus.Granted ? "Cámara Activa" : "Esperando permisos..."
        color: "white"
        font.pixelSize: 16
    }
}