//
//  WebViewController.swift
//  Tabble
//
//  Created by 曾德明 on 2023/7/17.
//

import UIKit
import WebKit
import StarIO10
import SwiftyJSON
import AVFoundation

class WebViewController: UIViewController, StarDeviceDiscoveryManagerDelegate, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate, Epos2DiscoveryDelegate {
    @IBOutlet var rootView: UIView!
    @IBOutlet weak var backToScan: UIButton!
    private var webView: WKWebView?
    private var manager: StarDeviceDiscoveryManager? = nil
    private var messageQueue = [String]()
    private var printer: Epos2Printer? = nil
    private var printerName = ""
    private var printerTarget = ""
    private var ttsInfoList = [TTSInfo]()
    private var playingTTS = false
    private var audioPlayer: AVPlayer = AVPlayer()
    private var keyValueObservation: NSKeyValueObservation?
    private var audioFileName = ""
    private var swipeState = 0
    private var tPrevious: TimeInterval = 0
    
    @IBAction func backToLoggonController(_ sender: Any) {
        TabbleService.shared.serviceUrl = ""
        performSegue(withIdentifier: "backToLoginPage", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
        initWebView()
        Epos2Discovery.start(Epos2FilterOption(), delegate: self)
        // add swipe gesture for control panel
        let leftEdgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenLeftEdgeSwiped))
        leftEdgePan.edges = .left
        self.view.addGestureRecognizer(leftEdgePan)
        
        let rightEdgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenRightEdgeSwiped))
        rightEdgePan.edges = .right
        self.view.addGestureRecognizer(rightEdgePan)
        
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(screenRotated(_:)))
        self.view.addGestureRecognizer(rotateGesture)
        
        let swipeUp = UISwipeGestureRecognizer(target:self, action: #selector(swipeGesture(_:)))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target:self, action: #selector(swipeGesture(_:)))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        let swipeLeft = UISwipeGestureRecognizer(target:self, action: #selector(swipeGesture(_:)))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target:self, action: #selector(swipeGesture(_:)))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
    }
    
    @objc func swipeGesture(_ recognizer:UISwipeGestureRecognizer) {
        //        if recognizer.direction == .up {
        //            if viewWidgets.count > 0 {
        //                viewWidgets[0].swipeUp()
        //            }
        //
        //            print("向上滑动")
        //        } else if recognizer.direction == .down {
        //            if viewWidgets.count > 0 {
        //                viewWidgets[0].swipeDown()
        //            }
        //
        //            print("向下滑动")
        //        } else if recognizer.direction == .left {
        //            if viewWidgets.count > 0 {
        //                viewWidgets[0].swipeLeft()
        //            }
        //
        //            print("向左滑动")
        //        } else if recognizer.direction == .right {
        //            if viewWidgets.count > 0 {
        //                viewWidgets[0].swipeRight()
        //            }
        //
        //            print("向右滑动")
        //        }
    }
    
    @objc func screenLeftEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .recognized {
            print("Screen left edge swiped!")
            
            if swipeState == 1 {
                let tCurrent = Date().timeIntervalSince1970
                let duration = tCurrent - tPrevious
                if duration < 1.5 {
                    self.backToScan.isHidden = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
                        self.backToScan.isHidden = true
                    })
                }
                print(">>>duration: \(duration)")
                swipeState = 0
            }
        }
    }
    
    @objc func screenRightEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .recognized {
            print("Screen right edge swiped!")
            if swipeState == 0 {
                swipeState = 1
                tPrevious = Date().timeIntervalSince1970
            }
        }
    }
    
    @objc func screenRotated(_ recognizer: UIRotationGestureRecognizer) {
        let radian = recognizer.rotation
        let angle = radian * (180 / CGFloat(Double.pi))
        
        //        print("旋轉角度： \(angle)")
        
        if angle > 30 {
            let tCurrent = Date().timeIntervalSince1970
            
            let duration = tCurrent - tPrevious
            if duration > 3 {
                tPrevious = tCurrent
                self.backToScan.isHidden = false
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
                    self.backToScan.isHidden = true
                })
            }
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        createNotification(count: 0)
        super.viewDidAppear(animated)
    }
    
    func createNotification(count: NSNumber) {
        let content = UNMutableNotificationContent()
        content.badge = count
    }
    
    func initWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()
        configuration.userContentController.add(self, name: "printMessage")
        configuration.userContentController.add(self, name: "getNotificationInfo")
        configuration.userContentController.add(self, name: "playTts")
        configuration.userContentController.add(self, name: "playAudio")
        configuration.userContentController.add(self, name: "resetBadgeNumber")
        webView = WKWebView(frame: getContentRegion(), configuration: configuration)
        webView?.navigationDelegate = self
        webView?.uiDelegate = self
        keyValueObservation = webView?.observe(\.url, changeHandler: {(view, change) in
            let url = view.url?.description ?? ""
            if url.contains("tabble") && url.contains("sign_in") {
                self.backToScan.isHidden = false
            } else {
                self.backToScan.isHidden = true
            }
        })
        
        if let webView = webView {
            view.addSubview(webView)
            self.rootView.bringSubviewToFront(backToScan)
            loadUrl()
            //loadxxx()
        }
    }
    
    private func getContentRegion() -> CGRect {
        let bannerHeight: CGFloat = 20
        let bounds = UIScreen.main.bounds
        return CGRect(x: 0, y: bannerHeight, width: bounds.width, height: bounds.height - bannerHeight)
    }
    
    //    func loadxxx() {
    //        self.webView?.load(URLRequest(url: URL(string: "https://staging.tabble.io/cp/stores/yaDpL4wptLMTNLBRnC27ucYXGlpw-Ye2dVYN/v2/apps")!))
    //
    //    }
    
    func loadUrl() {
        let urlString = TabbleService.shared.serviceUrl
        if urlString.isEmpty {return}
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            self.webView?.load(request)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        webView?.stopLoading()
        webView?.removeFromSuperview()
        webView = nil
        super.viewDidDisappear(animated)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        message.name.logI(tag: "xyz")
        if message.name == "resetBadgeNumber" {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        
        guard let body = message.body as? String else { return }
        let json = JSON(parseJSON: body)
        
        switch message.name {
        case "printMessage":
            guard let picString = json[0].string else {return}
            print(picString)
            messageQueue.append(picString)
            printStar()
            printEpson(picString: picString)
        case "playTts":
            guard let content = json[0].string, let locale = json[1].string, let delayTime = json[2].int else {return}
            ttsInfoList.append(TTSInfo(content: content, locale: locale, delay: delayTime))
            queueToPlayTTS()
        case "playAudio":
            guard let url = json[0].string else {return}
            guard let index = url.lastIndex(of: "/") else {return}
            var fileName = String(url[index...])
            fileName.removeFirst()
            audioFileName = fileName
            DataManager.downloadResource(downloadPath: "https:\(url)", fileName: fileName)
        case "getNotificationInfo":
            guard let callbackID = json[0].int else {return}
            guard let token = TabbleService.shared.apnsToken else {return}
            sendMessageToWeb(callbackID: callbackID, token: token)
        case "resetBadgeNumber":
            UIApplication.shared.applicationIconBadgeNumber = 0
        default:
            print("no such function")
        }
    }
    
    func sendMessageToWeb(callbackID:Int, token: String) {
        var array = Array<String>()
        let info = NotificationInfo(notifyToken: token)
        let data = try! JSONEncoder().encode(info)
        let string = String(data: data, encoding: .utf8) ?? ""
        array.append(string)
        webView?.evaluateJavaScript("nativeBridgeCallback(\(callbackID), \(array))")
    }
    
    func printStar() {
        let interfaceTypeArray : [InterfaceType] = [InterfaceType.usb]
        do {
            manager = try StarDeviceDiscoveryManagerFactory.create(interfaceTypes: interfaceTypeArray)
            manager?.discoveryTime = 20000
            manager?.delegate = self
            try manager?.startDiscovery()
        } catch let error {
            print("Error: \(error)")
        }
    }
    
    func printEpson(picString: String) {
        if self.printerTarget == "" {
            Epos2Discovery.start(Epos2FilterOption(), delegate: self)
        }
        let queue = OperationQueue()
        queue.addOperation({ [self] in
            guard let image = self.base64ToImage(base64String: picString) else {
                print("xyzreturn")
                return}
            printer = Epos2Printer(printerSeries:EPOS2_TM_T88.rawValue, lang: EPOS2_MODEL_TAIWAN.rawValue)
            printer?.connect(self.printerTarget, timeout:Int(EPOS2_PARAM_DEFAULT))
            printer?.addHPosition(25)
            printer?.add(image, x: 0, y:0,
                         width:Int(image.size.width),
                         height:Int(image.size.height),
                         color:EPOS2_COLOR_1.rawValue,
                         mode:EPOS2_MODE_MONO.rawValue,
                         halftone:EPOS2_HALFTONE_DITHER.rawValue,
                         brightness:Double(EPOS2_PARAM_DEFAULT),
                         compress:EPOS2_COMPRESS_AUTO.rawValue)
            printer?.addCut(EPOS2_CUT_FEED.rawValue)
            printer?.sendData(Int(EPOS2_PARAM_DEFAULT))
        })
    }
    
    func base64ToImage (base64String: String) -> UIImage? {
        guard let imageData = Data.init(base64Encoded: base64String, options: .init(rawValue: 0)), let image = UIImage(data: imageData) else { return nil }
        return image
    }
    
    func queueToPlayTTS() {
        if playingTTS {return}
        if ttsInfoList.count <= 0 {
            playingTTS = false
            return
        }
        self.audioPlayer.replaceCurrentItem(with: DataManager.getLocalVideoResource(fileName:audioFileName))
        self.audioPlayer.play()
        
    }
    
    func manager(_ manager: StarIO10.StarDeviceDiscoveryManager, didFind printer: StarIO10.StarPrinter) {
        DispatchQueue.main.async {
            switch printer.connectionSettings.interfaceType {
            case .bluetooth:
                self.printTicket(printer: printer, type: .bluetooth)
                
            case .bluetoothLE:
                self.printTicket(printer: printer, type: .bluetoothLE)
                
            case .usb:
                self.printTicket(printer: printer, type: .usb)
                
            default:
                break
            }
        }
    }
    
    func printTicket(printer: StarIO10.StarPrinter, type: InterfaceType) {
        if self.messageQueue.isEmpty { return }
        guard let message = self.messageQueue.first, let image = self.base64ToImage(base64String: message) else { return }
        let starConnectionSettings = StarConnectionSettings(interfaceType: type,
                                                            identifier: printer.connectionSettings.identifier)
        let printer = StarPrinter(starConnectionSettings)
        let builder = StarXpandCommand.StarXpandCommandBuilder()
        _ = builder.addDocument(StarXpandCommand.DocumentBuilder.init()
            .addPrinter(StarXpandCommand.PrinterBuilder()
                .styleAlignment(.center)
                .actionPrintImage(StarXpandCommand.Printer.ImageParameter(image: image, width: 384)).actionCut(StarXpandCommand.Printer.CutType.partial)
            ))
        
        
        let command = builder.getCommands()
        if #available(iOS 13.0, *) {
            Task {
                do {
                    try await printer.open()
                    defer {
                        Task {
                            await printer.close()
                        }
                    }
                    
                    try await printer.print(command: command)
                    self.messageQueue.remove(at: 0)
                    
                } catch let error {
                    print("Error: \(error)")
                }
            }
        }
        
    }
    
    func managerDidFinishDiscovery(_ manager: StarIO10.StarDeviceDiscoveryManager) {
        
    }
    
    func onDiscovery(_ deviceInfo: Epos2DeviceInfo!) {
        printerName = deviceInfo.deviceName
        printerTarget = deviceInfo.target
        Epos2Discovery.stop()
    }
    
    @objc func orientationChanged(_ notification: NSNotification) {
        DispatchQueue.main.async(execute: {
            self.webView?.frame = self.getContentRegion()
        })
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
//        let alert = UIAlertController(title: nil, message: "網頁錯誤, 請重新掃描", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
//        alert.addAction(UIAlertAction(title: "重試", style: .default, handler: { (action) -> Void in
//            self.webView?.reload()
//        }))
//        self.present(alert, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
            self.backToScan.isHidden = false
        })
    }
}
