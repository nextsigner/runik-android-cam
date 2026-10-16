import QtQuick
import QtMultimedia

Window {
    id: window
    visible: true
    width: 480
    height: 800
    title: "Cámara Frontal Directa"
    color: "black"

    CameraPermission {
        id: cameraPermission
    }

    Component.onCompleted: {
        if (cameraPermission.status !== Qt.PermissionStatus.Granted) {
            cameraPermission.request();
        }
    }

    CaptureSession {
        id: captureSession
        camera: Camera {
            id: camera
            // Se activa automáticamente solo cuando el permiso está concedido
            active: cameraPermission.status === Qt.PermissionStatus.Granted

            // Asignación directa y reactiva del dispositivo frontal
            cameraDevice: {
                var devices = MediaDevices.videoInputs;
                for (var i = 0; i < devices.length; ++i) {
                    if (devices[i].position === CameraDevice.FrontFace) {
                        return devices[i];
                    }
                }
                return devices.length > 0 ? devices[0] : null;
            }
        }
        videoOutput: videoOutput
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
    }

    // Texto indicador para saber en qué estado se encuentra
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        color: "white"
        font.pixelSize: 18
        text: {
            if (cameraPermission.status !== Qt.PermissionStatus.Granted)
                return "Solicitando permisos...";
            if (MediaDevices.videoInputs.length === 0)
                return "No se detectan cámaras en el sistema";
            return "Cámara activa (Buscando frontal...)";
        }
    }
}