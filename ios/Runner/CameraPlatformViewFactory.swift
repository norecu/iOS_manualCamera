import Flutter
import UIKit

final class CameraPlatformViewFactory:
    NSObject,
    FlutterPlatformViewFactory {

    private let cameraEngine:
        CameraEngine

    init(cameraEngine: CameraEngine) {

        self.cameraEngine = cameraEngine

        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {

        return CameraPlatformView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            cameraEngine: cameraEngine
        )
    }

    func createArgsCodec()
        -> FlutterMessageCodec & NSObjectProtocol {

        return FlutterStandardMessageCodec
            .sharedInstance()
    }
}