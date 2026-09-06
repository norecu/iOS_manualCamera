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
            case "setShutter":
    guard let seconds = call.arguments as? Double else {
        result(
            FlutterError(
                code: "INVALID_SHUTTER",
                message: "셔터 속도 값이 올바르지 않습니다.",
                details: nil
            )
        )
        return
    }

    do {
        try cameraEngine.setShutter(seconds)
        result(nil)
    } catch {
        result(
            FlutterError(
                code: "SHUTTER_FAILED",
                message: error.localizedDescription,
                details: nil
            )
        )
    }

case "setFocus":
    guard let focus = call.arguments as? Double else {
        result(
            FlutterError(
                code: "INVALID_FOCUS",
                message: "초점 값이 올바르지 않습니다.",
                details: nil
            )
        )
        return
    }

    do {
        try cameraEngine.setFocus(Float(focus))
        result(nil)
    } catch {
        result(
            FlutterError(
                code: "FOCUS_FAILED",
                message: error.localizedDescription,
                details: nil
            )
        )
    }

case "setZoom":
    guard let zoom = call.arguments as? Double else {
        result(
            FlutterError(
                code: "INVALID_ZOOM",
                message: "줌 값이 올바르지 않습니다.",
                details: nil
            )
        )
        return
    }

    do {
        try cameraEngine.setZoom(Float(zoom))
        result(nil)
    } catch {
        result(
            FlutterError(
                code: "ZOOM_FAILED",
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