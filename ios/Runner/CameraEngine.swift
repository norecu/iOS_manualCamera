import AVFoundation
import UIKit

final class CameraEngine: NSObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()

    private var videoDevice: AVCaptureDevice?

    func setup() throws {
        session.beginConfiguration()

        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
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
        guard !session.isRunning else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func stop() {
        guard session.isRunning else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }
}

enum CameraError: Error {
    case cameraUnavailable
}