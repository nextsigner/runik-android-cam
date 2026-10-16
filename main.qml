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

    Connections{
        target: qmlErrorLogger
        onMessagesChanged:{
            //if(Qt.platform.os==='linux' && app.enableQmlErrorLog && apps.dev && ap){
                //app.flags=Qt.Window
                //app.visibility="Maximized"
                log.text+=''+qmlErrorLogger.messages[qmlErrorLogger.messages.length-1]+'<br>'
            //}
        }
    }


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
        interval: 400
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
    Rectangle{
        id: xLog
        color: 'black'
        //anchors.fill: parent
        width: parent.width-app.fs*4
        height: parent.height-app.fs*6
        anchors.centerIn: parent
        visible: false
        onVisibleChanged: log.text=''
        Flickable{
            width: parent.width
            height: parent.height
            contentWidth: width
            contentHeight: log.contentHeight
            Text{
                id: log
                width: xLog.width-app.fs
                color: 'white'
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                onTextChanged: {
                    if(text!=='')xLog.visible=true
                }
            }
        }
        Button{
            text: 'Cerrar'
            onClicked: xLog.visible=false
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: app.fs*4
        }
    }

    // Función robusta para forzar la cámara frontal (la de la pantalla)
    function updateCameraDevice() {
        if (cameraPermission.status !== Qt.PermissionStatus.Granted) return;

        var cams = mediaDevices.videoInputs;
        if (cams.length === 0) {
            initTimer.restart();
            return;
        }

        var frontCamera = null;

        // Intentamos encontrar la cámara frontal por su posición lógica
        for (var i = 0; i < cams.length; ++i) {
            console.log("Cámara detectada [" + i + "]:", cams[i].description, "Posición:", cams[i].position);
            if (cams[i].position === CameraDevice.FrontFace) {
                frontCamera = cams[i];
                break;
            }
        }

        // Plan B: Si el driver del teléfono no mapea bien el enum FrontFace,
        // por lo general la cámara frontal es el segundo dispositivo en la lista (índice 1)
        // o el último si hay múltiples lentes traseros.
        if (!frontCamera) {
            if (cams.length > 1) {
                // Si hay más de una cámara, probamos con la segunda (índice 1 suele ser la frontal en la mayoría de Android)
                frontCamera = cams[1];
            } else {
                frontCamera = cams[0];
            }
        }

        // Asignamos la cámara encontrada y la iniciamos
        if (camera.cameraDevice !== frontCamera) {
            camera.cameraDevice = frontCamera;
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
            // IMPORTANTE: La dejamos en false inicialmente para evitar que tome
            // la cámara trasera por defecto antes de que el script elija la frontal.
            active: false
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
                      (mediaDevices.videoInputs.length === 0 ? "Buscando cámaras..." : "Usando cámara frontal") :
                      "Permiso de cámara requerido"
            color: "white"
            font.pixelSize: window.fs * 1.2
            style: Text.Outline; styleColor: "black"
        }
    }
}