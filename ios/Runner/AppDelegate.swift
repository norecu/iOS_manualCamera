import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    let cameraEngine = CameraEngine()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        GeneratedPluginRegistrant.register(with: self)

        let controller = window?.rootViewController as! FlutterViewController

        let factory = CameraPlatformViewFactory(
            cameraEngine: cameraEngine
        )

        controller.registrar(
            forPlugin: "CameraPlatformView"
        ).register(
            factory,
            withId: "ios-camera-preview"
        )

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