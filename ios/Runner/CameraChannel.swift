import Flutter
import UIKit

final class CameraChannel {

    private init() {}

    static func register(
        controller: FlutterViewController,
        cameraEngine: CameraEngine
    ) {

        let channel = FlutterMethodChannel(
            name: "ios-camera",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler {
            call,
            result in

            switch call.method {

            // MARK: - Capture

            case "capturePhoto":

                cameraEngine.capturePhoto { captureResult in

                    DispatchQueue.main.async {

                        switch captureResult {

                        case .success:
                            result(nil)

                        case .failure(let error):

                            result(
                                FlutterError(
                                    code: "CAPTURE_FAILED",
                                    message: error.localizedDescription,
                                    details: nil
                                )
                            )
                        }
                    }
                }

            // MARK: - ISO

            case "setISO":

                guard let iso =
                    call.arguments as? Double
                else {

                    result(
                        FlutterError(
                            code: "INVALID_ISO",
                            message: "ISO 값이 올바르지 않습니다.",
                            details: nil
                        )
                    )

                    return
                }

                do {

                    try cameraEngine.setISO(
                        Float(iso)
                    )

                    result(nil)

                } catch {

                    result(
                        FlutterError(
                            code: "ISO_FAILED",
                            message: error.localizedDescription,
                            details: nil
                        )
                    )
                }

            // MARK: - Unknown

            default:

                result(
                    FlutterMethodNotImplemented
                )
            }
        }
    }
}