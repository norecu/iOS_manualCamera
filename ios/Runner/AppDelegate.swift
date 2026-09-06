import Flutter
import UIKit
import AVFoundation
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {

    private let cameraEngine = CameraEngine()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        GeneratedPluginRegistrant.register(with: self)

        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(
                application,
                didFinishLaunchingWithOptions: launchOptions
            )
        }

        let cameraChannel = FlutterMethodChannel(
    name: "ios-camera",
    binaryMessenger: controller.binaryMessenger
)

cameraChannel.setMethodCallHandler { [weak self] call, result in
    guard let self = self else {
        result(
            FlutterError(
                code: "APP_DELEGATE_ERROR",
                message: "AppDelegate를 찾을 수 없습니다.",
                details: nil
            )
        )
        return
    }

    switch call.method {
    case "capturePhoto":
        self.cameraEngine.capturePhoto { captureResult in
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

    default:
        result(FlutterMethodNotImplemented)
    }
}

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


// MARK: - Camera Engine

final class CameraEngine: NSObject, AVCapturePhotoCaptureDelegate {

    let session = AVCaptureSession()

    private let photoOutput = AVCapturePhotoOutput()
    private var videoDevice: AVCaptureDevice?
    private var captureCompletion: ((Result<Void, Error>) -> Void)?

    func setup() throws {

        session.beginConfiguration()

        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            session.commitConfiguration()
            throw CameraError.cameraUnavailable
        }

        videoDevice = device

        let input = try AVCaptureDeviceInput(device: device)

        if session.canAddInput(input) {
            session.addInput(input)
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        session.commitConfiguration()
    }

    func start() {

        guard !session.isRunning else {
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func stop() {

        guard session.isRunning else {
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }

    func capturePhoto(completion: @escaping (Result<Void, Error>) -> Void) {
        let settings = AVCapturePhotoSettings()


        photoOutput.capturePhoto(with: settings, delegate: self)
        self.captureCompletion = completion
        photoOutput.capturePhoto(
            with: settings,
            delegate: self
        )
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
        ) {
        if let error = error {
            captureCompletion?(.failure(error))
            captureCompletion = nil
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            captureCompletion?(
                .failure(CameraError.captureFailed)
            )
            captureCompletion = nil
            return
        }

        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()

            let options = PHAssetResourceCreationOptions()
            request.addResource(
                with: .photo,
                data: data,
                options: options
            )
        }) { success, error in

            DispatchQueue.main.async {
                if let error = error {
                    self.captureCompletion?(.failure(error))
                } else if success {
                    self.captureCompletion?(.success(()))
                } else {
                    self.captureCompletion?(
                        .failure(CameraError.captureFailed)
                    )
                }

                self.captureCompletion = nil
            }
        }   
    }
}

enum CameraError: Error {
    case cameraUnavailable
    case captureFailed
}

// MARK: - Camera Preview

final class CameraPreviewView: UIView {

    private let previewLayer: AVCaptureVideoPreviewLayer

    init(session: AVCaptureSession) {

        previewLayer = AVCaptureVideoPreviewLayer(
            session: session
        )

        super.init(frame: .zero)

        previewLayer.videoGravity = .resizeAspectFill

        layer.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        previewLayer.frame = bounds
    }
}


// MARK: - Flutter Platform View

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


// MARK: - Flutter Platform View Factory

final class CameraPlatformViewFactory: NSObject, FlutterPlatformViewFactory {

    private let cameraEngine: CameraEngine

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

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {

        return FlutterStandardMessageCodec.sharedInstance()
    }
}