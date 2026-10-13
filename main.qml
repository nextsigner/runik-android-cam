import QtQuick
import QtMultimedia
import QtCore

Window {
    id: window
    visible: true
    width: 480
    height: 800
    title: "Cámara Frontal - Qt 6.11"
    color: 'black'
    property int fs: Screen.width*0.03

    Connections{
        target: qmlErrorLogger
        onMessagesChanged:{
            log.text+=''+qmlErrorLogger.messages[qmlErrorLogger.messages.length-1]+'<br>'
        }
    }
    Item{
        id: xApp
        width: parent.width-app.fs*4
        height: parent.height-app.fs*6
        anchors.centerIn: parent

    }

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
    Rectangle{
        id: xLog
        color: apps.backgroundColor
        anchors.fill: parent
        visible: false
        Flickable{
            width: parent.width-app.fs*4
            height: parent.height-app.fs*6
            contentWidth: width
            contentHeight: log.contentHeight
            anchors.centerIn: parent
            Text{
                id: log
                width: xLog.width-app.fs
                color: apps.fontColor
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                onTextChanged: {
                    if(text!=='')xLog.visible=true
                }
            }
            Rectangle{
                width: app.fs*2
                height: width
                anchors.right: parent.right
                MouseArea{
                    anchors.fill: parent
                    onClicked: xLog.visible=false
                }
                Text{
                    text: "X"
                    font.pixelSize: parent.width*0.8
                    color: 'black'
                    anchors.centerIn: parent
                }
            }
        }
    }
}
