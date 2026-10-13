import QtQuick
import QtMultimedia
import QtCore

Window {
    id: window
    visible: true
    width: 480
    height: 800
    title: "Cámara Frontal - Qt 6.11"

    // 1. Gestión de permisos en tiempo de ejecución (obligatorio en Android/iOS)
    CameraPermission {
        id: cameraPermission
        onStatusChanged: {
            if (status === Qt.PermissionStatus.Granted) {
                camera.start()
            }
        }
    }

    // Solicitar permisos al iniciar la aplicación si aún no están concedidos
    Component.onCompleted: {
        if (cameraPermission.status === Qt.PermissionStatus.Granted) {
            camera.start()
        } else {
            cameraPermission.request()
        }
    }

    // 2. Dispositivos multimedia disponibles en el sistema
    MediaDevices {
        id: mediaDevices
    }

    // Función para buscar explícitamente la cámara frontal (FrontFace)
    function getFrontCamera() {
        for (var i = 0; i < mediaDevices.videoInputs.length; ++i) {
            var device = mediaDevices.videoInputs[i]
            if (device.position === CameraDevice.FrontFace) {
                return device
            }
        }
        // Si no se encuentra la frontal, usa la cámara por defecto
        return mediaDevices.defaultVideoInput
    }

    // 3. Sesión de captura multimedia de Qt 6
    CaptureSession {
        id: captureSession
        camera: Camera {
            id: camera
            cameraDevice: getFrontCamera()
            active: cameraPermission.status === Qt.PermissionStatus.Granted
        }
        videoOutput: videoOutput
    }

    // 4. Salida de video en pantalla (Visualizador de la cámara)
    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        // Nota: Por lo general, las cámaras frontales se muestran con efecto espejo, 
        // puedes ajustar rotaciones o escalas aquí si lo requieres.
    }
}
