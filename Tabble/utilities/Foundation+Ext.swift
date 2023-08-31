//
//  Foundation+Ext.swift
//  Tabble
//
//  Created by 曾德明 on 2023/7/12.
//
import UIKit

extension UIViewController {
    func showMessage(message: String!, completion:(()->())?) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
            if let completion = completion {
                completion()
            }
        }))
        
        DispatchQueue.main.async(execute: {
            self.present(alert, animated: true, completion: nil)
        })
    }
}

extension UIView {
    func removeAll() {
        for view in self.subviews {
            view.removeAll()
        }
        self.layer.removeAllAnimations()
        self.removeFromSuperview()
    }
    
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

extension String {
    func logI(tag: String) {
        print("\(tag): \(self)")
    }
}
