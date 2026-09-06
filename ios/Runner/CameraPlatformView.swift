import AVFoundation
import UIKit
import Flutter

// MARK: - Camera Preview

final class CameraPreviewView: UIView {

    private let previewLayer:
        AVCaptureVideoPreviewLayer

    init(session: AVCaptureSession) {

        previewLayer =
            AVCaptureVideoPreviewLayer(
                session: session
            )

        super.init(frame: .zero)

        previewLayer.videoGravity =
            .resizeAspectFill

        layer.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) {
        fatalError(
            "init(coder:) has not been implemented"
        )
    }

    override func layoutSubviews() {

        super.layoutSubviews()

        previewLayer.frame = bounds
    }
}

// MARK: - Flutter Platform View

final class CameraPlatformView:
    NSObject,
    FlutterPlatformView {

    private let cameraView:
        CameraPreviewView

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        cameraEngine: CameraEngine
    ) {

        cameraView =
            CameraPreviewView(
                session: cameraEngine.session
            )

        super.init()
    }

    func view() -> UIView {
        return cameraView
    }
}