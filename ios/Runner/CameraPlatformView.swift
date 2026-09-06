import Flutter
import UIKit

final class CameraPlatformView: NSObject, FlutterPlatformView {

    private let cameraView: CameraPreviewView

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        cameraEngine: CameraEngine
    ) {
        cameraView = CameraPreviewView(
            session: cameraEngine.session
        )

        super.init()
    }

    func view() -> UIView {
        return cameraView
    }
}