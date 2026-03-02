import SwiftUI
import AVFoundation

/// Custom Camera View with Pinch-to-Zoom and Direct Selection Flow
struct CameraView: View {
    let onImageCaptured: (UIImage) -> Void
    let onCancel: () -> Void

    // Zoom for the LIVE camera
    @State private var cameraZoom: CGFloat = 1.0
    @State private var lastCameraZoom: CGFloat = 1.0
    
    // Emerald design tokens
    private let emerald = Color(red: 0, green: 0.88, blue: 0.56)
    private let bgColor = Color(red: 0.02, green: 0.027, blue: 0.059)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            captureMode
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Detect right swipe to cancel
                            if value.translation.width > 100 && abs(value.translation.height) < 50 {
                                onCancel()
                            }
                        }
                )
        }
    }

    // MARK: - Capture Mode

    private var captureMode: some View {
        ZStack {
            CameraPreview(zoomFactor: cameraZoom, onImageCaptured: { image in
                // IMMEDIATELY pass to parent, skipping review
                onImageCaptured(image)
            })
            .ignoresSafeArea()
            .gesture(
                MagnificationGesture()
                    .onChanged { scale in
                        cameraZoom = max(1.0, min(10.0, lastCameraZoom * scale))
                    }
                    .onEnded { _ in
                        lastCameraZoom = cameraZoom
                    }
            )

            VStack {
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(20)
                    }
                    Spacer()
                }
                Spacer()
                
                // Zoom Indicator
                if cameraZoom > 1.0 {
                    Text(String(format: "%.1fx", cameraZoom))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(.black.opacity(0.5)))
                        .padding(.bottom, 12)
                }
                
                // Shutter Button
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 3)
                        .frame(width: 76, height: 76)
                    Circle()
                        .fill(.white)
                        .frame(width: 64, height: 64)
                        .padding(6)
                }
                .padding(.bottom, 40)
                .contentShape(Circle())
                .onTapGesture {
                    NotificationCenter.default.post(name: NSNotification.Name("CapturePhoto"), object: nil)
                }
            }
        }
    }
}

// MARK: - AVFoundation Camera Wrapper

struct CameraPreview: UIViewRepresentable {
    let zoomFactor: CGFloat
    let onImageCaptured: (UIImage) -> Void

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.onImageCaptured = onImageCaptured
        view.setupSession()
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        uiView.setZoom(zoomFactor)
    }
}

class CameraPreviewView: UIView, AVCapturePhotoCaptureDelegate {
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let output = AVCapturePhotoOutput()
    private var device: AVCaptureDevice?
    var onImageCaptured: ((UIImage) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSession() {
        session.beginConfiguration()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        self.device = device
        
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { 
            session.addOutput(output)
            if #available(iOS 16.0, *) {
                output.maxPhotoQualityPrioritization = .quality
            } else {
                output.isHighResolutionCaptureEnabled = true
            }
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        if let previewLayer = previewLayer {
            layer.addSublayer(previewLayer)
        }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(capturePhoto), name: NSNotification.Name("CapturePhoto"), object: nil)
    }

    func setZoom(_ factor: CGFloat) {
        guard let device = device else { return }
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = max(1.0, min(factor, device.activeFormat.videoMaxZoomFactor))
            device.unlockForConfiguration()
        } catch {
            print("❌ CameraPreviewView: Failed to set zoom: \(error)")
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        if output.availablePhotoCodecTypes.contains(.jpeg) {
            _ = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        }
        
        output.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        
        // Ensure image orientation is correct
        let normalizedImage = image.fixOrientation()
        
        DispatchQueue.main.async {
            self.onImageCaptured?(normalizedImage)
        }
    }
}

// Helper to fix image orientation after capture
extension UIImage {
    func fixOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? self
    }
}
