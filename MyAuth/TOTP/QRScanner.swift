//
//  QRScanner.swift
//  MyAuth
//
//  Created by Jack Rogers on 5/18/25.
//

import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    var completion: (String) -> Void

    var body: some View {
#if targetEnvironment(simulator)
        VStack {
            Text("Simulator doesn't support camera scanning.")
                .font(.headline)
            Button(action: {
                completion("otpauth://totp/Example:demo@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Example")
            }) {
                Text("Simulate Scan")
                    .foregroundColor(.green)
                    .font(.callout)
            }
        }
        .padding()
#else
        ZStack(alignment: .topTrailing) {
            QRScannerCameraView(completion: completion)

            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.ultraThinMaterial)
                    .padding()
            }
            .accessibilityLabel("Close scanner")
        }
        .ignoresSafeArea()
        
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(width: UIScreen.main.bounds.width * 0.65, height: 60)
                .cornerRadius(20)
                .shadow(radius: 5)
                .overlay(
                    Text("Scan a QR Code")
                        .foregroundStyle(.primary)
                        .font(.system(size: 22, weight: .semibold))
                )
        }
        .ignoresSafeArea()
#endif
    }
}

struct QRScannerCameraView: UIViewControllerRepresentable {
    var completion: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    class Coordinator: NSObject, ScannerDelegate {
        let completion: (String) -> Void
        init(completion: @escaping (String) -> Void) {
            self.completion = completion
        }
        func didFind(code: String) {
            completion(code)
            print(code)
        }
    }
}

protocol ScannerDelegate: AnyObject {
    func didFind(code: String)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerDelegate?
    var session: AVCaptureSession!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        session = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              session.canAddInput(videoInput) else {
            showCameraError()
            return
        }

        session.addInput(videoInput)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            showCameraError()
            return
        }

        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.qr]

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    private func showCameraError() {
        let label = UILabel()
        label.text = "Camera not available or permission denied."
        label.textAlignment = .center
        label.frame = view.bounds
        view.addSubview(label)
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        session.stopRunning()
        if let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let stringValue = object.stringValue {
            delegate?.didFind(code: stringValue)
        }
    }
}

#Preview {
    AuthMainView()
}
