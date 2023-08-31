//
//  ScanView.swift
//  Tabble
//
//  Created by 曾德明 on 2023/7/31.
//

import UIKit
import AVFoundation

class ScanView: LoginView, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        contentView.removeAll()
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        configurationScanner()
    }
    
    func configurationScanner() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("無法獲取相機裝置")
            return }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = getContentRegion()
            layer.addSublayer(videoPreviewLayer!)
            settingScannerFrame()
            captureSession!.startRunning()
        } catch {
            error.localizedDescription.logI(tag: "error")
            return
        }
    }
    
    private func getContentRegion() -> CGRect {
        let bounds = UIScreen.main.bounds
        return CGRect(x: bounds.width / 2 - 150, y: bounds.height / 2 - 150, width: 300, height: 300)
    }
    
    func settingScannerFrame() {
        qrCodeFrameView = UIView()
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            addSubview(qrCodeFrameView)
            bringSubviewToFront(qrCodeFrameView)
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.isEmpty {
            qrCodeFrameView?.frame = CGRect.zero
            return
        }
        
        if let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject {
            if metadataObj.type == AVMetadataObject.ObjectType.qr {
                let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
                qrCodeFrameView?.frame = barCodeObject!.bounds
                if let value = metadataObj.stringValue {
                    if value.starts(with: "https://") && value.contains("tabble"){
                        captureSession?.stopRunning()
                        TabbleService.shared.serviceUrl = value
                        delegate?.openWebView()
                    }
                }
            }
        }
    }
    
    override func rotate() {
        DispatchQueue.main.async(execute: {
            self.videoPreviewLayer?.frame = self.getContentRegion()
            self.fixVideoRotation()
        })
    }
    
    func fixVideoRotation() {
        let deviceCurrentOrientation: UIDeviceOrientation = UIDevice.current.orientation
        switch deviceCurrentOrientation {
        case .faceDown:
            print("faceDown...")
        case .faceUp:
            print("faceUp...")
        case .landscapeLeft:
            self.videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            print("landscapeLeft...")
        case .landscapeRight:
            self.videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            print("landscapeRight...")
        case .portrait:
            self.videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            print("portrait...")
        case .portraitUpsideDown:
            self.videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            print("portraitUpsideDown...")
        case .unknown:
            print("unknown...")
        @unknown default:
            print("unknown default...")
        }
    }
}
