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
    color: '#000'
    property real fs: Screen.width * 0.03

    Settings{
        id: apps
        property color fontColor: 'white'
        property color backgroundColor: 'black'
    }

    Connections{
        target: qmlErrorLogger
        onMessagesChanged:{
            log.text+=''+qmlErrorLogger.messages[qmlErrorLogger.messages.length-1]+'<br>'
        }
    }
    Rectangle{
        id: xLog
        color: apps.backgroundColor
        width: Screen.width-videoOutput.width
        height: Screen.height-app.fs*6
        anchors.right: parent.right
        border.width: 3
        border.color: 'red'
        anchors.verticalCenter: parent.verticalCenter
        //visible: false
        Flickable{
            width: parent.width
            height: parent.height
            contentWidth: width
            contentHeight: log.contentHeight
            Text{
                id: log
                width: xLog.width-app.fs
                color: apps.fontColor
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                onTextChanged: {
                    if(log.text!=='')xLog.visible=true
                    clipboard.setText(log.text)
                }
            }
        }
    }


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
        interval: 5000
        repeat: false
        //onTriggered: updateCameraDevice()
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
    /*CaptureSession {
        id: captureSession
        camera: Camera {
            id: camera
            active: cameraPermission.status === Qt.PermissionStatus.Granted
        }
        videoOutput: videoOutput
    }*/
    CaptureSession {
        id: captureSession
        camera: Camera {
            id: camera
            // Seleccionar explícitamente la cámara frontal encontrada
            cameraDevice: {
                for (var i = 0; i < mediaDevices.videoInputs.length; ++i) {
                    if (mediaDevices.videoInputs[i].position === Camera.FrontFace) {
                        return mediaDevices.videoInputs[i];
                    }
                }
                return MediaDevices.defaultVideoDevice; // Fallback
            }
        }
        recorder: MediaRecorder {}
        videoOutput: videoOutput
    }

    // 4. Salida de video
    VideoOutput {
        id: videoOutput
        //anchors.fill: parent
        width: Screen.width*0.5
        height: width/9*16
        anchors.left: parent.left
    }

    // Interfaz de estado
    Rectangle {
        id: xApp
        //anchors.fill: parent
        width: Screen.width-app.fs*2
        height: Screen.height-app.fs*8
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
                    //updateCameraDevice()
                    var cams = mediaDevices.videoInputs;
                    log.text+='Cantidad de cámaras: '+cams.length+'<br>'
                    if (cams.length === 0) {
                        // Si todavía no hay dispositivos listos, reintentamos en breve
                        //initTimer.restart();
                        return;
                    }
                    log.text+='Dato: '+cams[0]+'<br>'
                    log.text+='Dato: '+cams[1]+'<br>'
                    var selectedDevice = mediaDevices.defaultVideoInput;
                    selectedDevice = cams[0];
                    /*return


                    for (var i = 0; i < cams.length; ++i) {
                        // Buscamos explícitamente la cámara frontal
                        if (cams[i].position === CameraDevice.FrontFace) {
                            selectedDevice = cams[i];
                            break;
                        }
                    }*/

                    // Asignación segura
                    if (camera.cameraDevice !== selectedDevice) {
                        camera.cameraDevice = selectedDevice;
                    }

                    if (!camera.active) {
                        camera.start();
                    }
                }
            }
        }
    }

}
