//
//  ScanViewController.swift
//  Tabble
//
//  Created by 曾德明 on 2023/7/17.
//

import UIKit
import AVFoundation

class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        configurationScanner()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
        super.viewDidLoad()
    }
    
    func configurationScanner() {
        //        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: AVMediaType.video, position: .back)
        //        guard let captureDevice = deviceDiscoverySession.devices.first else {
        //            print("無法獲取相機裝置")
        //            return
        //        }
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
            view.layer.addSublayer(videoPreviewLayer!)
            settingScannerFrame()
            captureSession!.startRunning()
        } catch {
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
            view.addSubview(qrCodeFrameView)
            view.bringSubviewToFront(qrCodeFrameView)
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
                        self.performSegue(withIdentifier: "openWebView", sender: self)
                    }
                }
            }
        }
    }
    
    @objc func orientationChanged(_ notification: NSNotification) {
        print("xyz")
        DispatchQueue.main.async(execute: {
            //self.videoPreviewLayer?.frame = self.getContentRegion()
            

        })
    }
}
