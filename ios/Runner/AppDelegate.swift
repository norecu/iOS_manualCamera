import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    private let cameraEngine = CameraEngine()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        GeneratedPluginRegistrant.register(with: self)

        guard let controller =
            window?.rootViewController as? FlutterViewController
        else {
            return super.application(
                application,
                didFinishLaunchingWithOptions: launchOptions
            )
        }

        // Flutter ↔ Swift 카메라 통신
        CameraChannel.register(
            controller: controller,
            cameraEngine: cameraEngine
        )

        // Flutter 카메라 미리보기
        let factory = CameraPlatformViewFactory(
            cameraEngine: cameraEngine
        )

        guard let registrar = controller.registrar(
            forPlugin: "CameraPlatformView"
        ) else {
            return super.application(
                application,
                didFinishLaunchingWithOptions: launchOptions
            )
        }

        registrar.register(
            factory,
            withId: "ios-camera-preview"
        )

        // 카메라 초기화
        do {
            try cameraEngine.setup()
            cameraEngine.start()
        } catch {
            print("Camera setup error: \(error)")
        }

        return super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }
}