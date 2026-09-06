import AVFoundation
import Photos

final class CameraEngine: NSObject, AVCapturePhotoCaptureDelegate {

    let session = AVCaptureSession()

    private let photoOutput = AVCapturePhotoOutput()
    private var cameraDevice: AVCaptureDevice?

    private var captureCompletion:
        ((Result<Void, Error>) -> Void)?

    // MARK: - Setup

    func setup() throws {

        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }

        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            throw CameraError.cameraUnavailable
        }

        cameraDevice = device

        let input = try AVCaptureDeviceInput(
            device: device
        )

        if session.canAddInput(input) {
            session.addInput(input)
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
    }

    // MARK: - Session

    func start() {

        guard !session.isRunning else {
            return
        }

        DispatchQueue.global(
            qos: .userInitiated
        ).async { [weak self] in
            self?.session.startRunning()
        }
    }

    func stop() {

        guard session.isRunning else {
            return
        }

        DispatchQueue.global(
            qos: .userInitiated
        ).async { [weak self] in
            self?.session.stopRunning()
        }
    }

    // MARK: - Photo Capture

    func capturePhoto(
        completion: @escaping (Result<Void, Error>) -> Void
    ) {

        let settings = AVCapturePhotoSettings()

        // 반드시 completion을 먼저 저장
        captureCompletion = completion

        // 사진 촬영
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
            finishCapture(.failure(error))
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            finishCapture(
                .failure(CameraError.captureFailed)
            )
            return
        }

        // 사진 앱에 저장
        PHPhotoLibrary.shared().performChanges({

            let request =
                PHAssetCreationRequest.forAsset()

            let options =
                PHAssetResourceCreationOptions()

            request.addResource(
                with: .photo,
                data: data,
                options: options
            )

        }) { [weak self] success, error in

            DispatchQueue.main.async {

                guard let self = self else {
                    return
                }

                if let error = error {
                    self.finishCapture(
                        .failure(error)
                    )
                } else if success {
                    self.finishCapture(
                        .success(())
                    )
                } else {
                    self.finishCapture(
                        .failure(
                            CameraError.captureFailed
                        )
                    )
                }
            }
        }
    }

    private func finishCapture(
        _ result: Result<Void, Error>
    ) {
        captureCompletion?(result)
        captureCompletion = nil
    }

    // MARK: - ISO

    func setISO(_ iso: Float) throws {

        guard let device = cameraDevice else {
            throw CameraError.cameraUnavailable
        }

        try device.lockForConfiguration()

        defer {
            device.unlockForConfiguration()
        }

        let minISO = device.activeFormat.minISO
        let maxISO = device.activeFormat.maxISO

        let clampedISO = min(
            max(iso, minISO),
            maxISO
        )

        device.setExposureModeCustom(
            duration: device.exposureDuration,
            iso: clampedISO
        )
    }

    // MARK: - EV

func setEV(_ ev: Float) throws {

    guard let device = cameraDevice else {
        throw CameraError.cameraUnavailable
    }

    try device.lockForConfiguration()

    defer {
        device.unlockForConfiguration()
    }

    let minEV: Float = -2.0
    let maxEV: Float = 2.0

    let clampedEV = min(
        max(ev, minEV),
        maxEV
    )

    device.setExposureTargetBias(
        clampedEV
    )
}

// MARK: - Focus

func setFocus(_ focus: Float) throws {

    guard let device = cameraDevice else {
        throw CameraError.cameraUnavailable
    }

    guard device.isFocusModeSupported(.locked) else {
        throw CameraError.focusUnavailable
    }

    try device.lockForConfiguration()

    defer {
        device.unlockForConfiguration()
    }

    let clampedFocus = min(
        max(focus, 0.0),
        1.0
    )

    device.setFocusModeLocked(
        lensPosition: clampedFocus
    )
}

// MARK: - Shutter

func setShutter(_ seconds: Double) throws {

    guard let device = cameraDevice else {
        throw CameraError.cameraUnavailable
    }

    try device.lockForConfiguration()

    defer {
        device.unlockForConfiguration()
    }

    let minDuration = CMTimeGetSeconds(
        device.activeFormat.minExposureDuration
    )

    let maxDuration = CMTimeGetSeconds(
        device.activeFormat.maxExposureDuration
    )

    let clampedSeconds = min(
        max(seconds, minDuration),
        maxDuration
    )

    let duration = CMTimeMakeWithSeconds(
        clampedSeconds,
        preferredTimescale: 1_000_000
    )

    device.setExposureModeCustom(
        duration: duration,
        iso: device.iso
    )
}

// MARK: - Zoom

func setZoom(_ zoom: Float) throws {

    guard let device = cameraDevice else {
        throw CameraError.cameraUnavailable
    }

    try device.lockForConfiguration()

    defer {
        device.unlockForConfiguration()
    }

    let minZoom = device.minAvailableVideoZoomFactor
    let maxZoom = device.maxAvailableVideoZoomFactor

    let clampedZoom = min(
        max(CGFloat(zoom), minZoom),
        maxZoom
    )

    device.videoZoomFactor = clampedZoom
}
}

// MARK: - Camera Error

enum CameraError: Error {

    case cameraUnavailable
    case captureFailed
    case focusUnavailable
}