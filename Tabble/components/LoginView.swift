//
//  LoginView.swift
//  Tabble
//
//  Created by 曾德明 on 2023/7/12.
//

import UIKit
import AVFoundation

protocol LoginViewProtocol {
    func openQRScanner()
    func openWebView()
}

class LoginView: UIView, LayerProtocool {
    @IBOutlet var contentView: UIView!
    @IBAction func startScan(_ sender: Any) {
        self.delegate?.openQRScanner()
    }
    var delegate: LoginViewProtocol?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("LoginView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func rotate() {
        
    }
}
