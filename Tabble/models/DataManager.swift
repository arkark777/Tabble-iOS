//
//  DataManager.swift
//  Tabble
//
//  Created by 曾德明 on 2023/7/18.
//

import Foundation
import Alamofire
import AVFoundation

class DataManager {
    class func downloadResource(downloadPath: String, fileName: String) {
        if let url = URL(string: downloadPath) {
            let manager = Alamofire.SessionManager.default
            
            let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let filePath = documentsURL.appendingPathComponent(fileName)
                return (filePath, [.removePreviousFile])
            }
            
            let tmpPath = NSTemporaryDirectory() + "/\(fileName)"
            var downloadRequest: DownloadRequest
            if FileManager.default.fileExists(atPath: tmpPath) {
                let resumeData = try! Data(contentsOf: URL(fileURLWithPath: tmpPath))
                downloadRequest = manager.download(resumingWith: resumeData, to: destination)
            }
            else {
                downloadRequest = manager.download(url, to: destination)
            }
            
            downloadRequest.downloadProgress(queue: .main, closure: { (progress) in
                let percentage = Int(progress.fractionCompleted * 100)
                
            }).validate { request, response, temporaryURL, destinationURL in
                return .success
            }.responseData { response in
                
                if response.destinationURL != nil {
                    
                } else {
                    
                    if let data = response.resumeData {
                        let tmpPath = NSTemporaryDirectory() + "/\(fileName)"
                        try! data.write(to: URL(fileURLWithPath: tmpPath))
                        print("~~~tmpPath: \(tmpPath)")
                    }
                    
                    print("\(fileName) download fail!")
                }
            }
        }
    }
    
    class func getLocalVideoResource(fileName: String) -> AVPlayerItem? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsURL.appendingPathComponent(fileName)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath.path) {
            print("FILE AVAILABLE")
        } else {
            print("FILE NOT AVAILABLE")
        }
        
        let fileURL = URL(fileURLWithPath: filePath.path)
        return AVPlayerItem(url: fileURL)
    }
}

