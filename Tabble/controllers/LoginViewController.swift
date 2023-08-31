//
//  LoginViewController.swift
//  Tabble
//
//  Created by 曾德明 on 2023/7/12.
//

import UIKit
import AVFAudio

enum OperationStateType: Int {
    case login              = 0
    case qr                 = 1
}

protocol LayerProtocool {
    func rotate()
}

class LoginViewController: UIViewController, LoginViewProtocol {
    @IBOutlet var rootView: UIView!
    @IBAction func backToLoginPage(segue: UIStoryboardSegue) {
        
    }
    
    private var delegate: LayerProtocool?
    private var _state: OperationStateType = .login
    private var viewContent: LoginView!
    var state: OperationStateType {
        get {
            return _state
        }
        
        set {
            if _state != newValue || viewContent == nil {
                _state = newValue
                updateState()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadState()
    }
    
    private func loadState() {
        if !TabbleService.shared.serviceUrl.isEmpty {
            self.performSegue(withIdentifier: "goToWebView", sender: self)
        } else {
            self.state = .login
        }
    }
    
    private func updateState() {
        var v: LoginView
        let rect = getContentRegion()
        
        switch self.state {
        case .login:
            v = LoginView(frame: rect)
            break
        case .qr:
            v = ScanView(frame: rect)
            self.delegate = v
            break
        }
        v.delegate = self
        v.frame = rect
        
        if viewContent != nil {
            UIView.animate(withDuration: 0.2, animations: {
                self.viewContent.alpha = 0
            }, completion: {(complated: Bool) -> () in
                self.viewContent.removeAll()
                self.viewContent.removeFromSuperview()
                self.viewContent = nil
                self.viewContent = v
                self.viewContent.alpha = 0
                self.view.addSubview(self.viewContent)
                UIView.animate(withDuration: 0.3, animations: {
                    self.viewContent.alpha = 1
                }, completion: nil)
            })
        }
        else {
            self.viewContent = v
            self.view.addSubview(self.viewContent)
        }
        
    }
    
    private func getContentRegion() -> CGRect {
        let bannerHeight: CGFloat = 20
        let bounds = UIScreen.main.bounds
        return CGRect(x: 0, y: bannerHeight, width: bounds.width, height: bounds.height - bannerHeight)
    }
    
    @objc func orientationChanged(_ notification: NSNotification) {
        if viewContent == nil { return }
        DispatchQueue.main.async(execute: {
            self.viewContent.frame = self.getContentRegion()
        })
        
        if state == .qr {
            delegate?.rotate()
        }
    }
    
    func openQRScanner() {
        state = .qr
    }
    
    func openWebView() {
        state = .login
        self.performSegue(withIdentifier: "goToWebView", sender: self)
    }
}
