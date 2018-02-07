//
//  WebImage.swift
//  EasySwift
//
//  Created by Serge Kutny on 1/27/18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import Foundation
import UIKit

//TODO: Cache cleanup
class WebImage : Observable {
    
    static let Cache : URL = {
        let cache = "WebImageCache"
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let root = (paths[0] as NSString).appendingPathComponent(cache)
        
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        let exists = withUnsafeMutablePointer(to: &isDir) {
            pDir -> Bool in
            return fileManager.fileExists(atPath:root, isDirectory:pDir)
        }
        
        if (!exists) {
            try? fileManager.createDirectory(atPath: root,
                                        withIntermediateDirectories: true)
        } else if (isDir.boolValue != true) {
            try? fileManager.removeItem(atPath: root)
            try? fileManager.createDirectory(atPath: root,
                                             withIntermediateDirectories: true)
        }
        
        return URL(fileURLWithPath:root)
    }()
    
    var cache : URL {
        get {
            let root = WebImage.Cache
            
            let src = url.absoluteString
            let dest = String(src.map {
                char in
                switch char {
                    case ":": return "C"
                    case "/": return "S"
                    case "&": return "N"
                    case ";": return "I"
                    case "@": return "A"
                    case "=": return "E"
                    case "~": return "T"
                    case "%": return "P"
                    default: return char
                }
            })
            
            return root.appendingPathComponent(dest)
        }
    }
    
    private lazy var _scope = { [unowned self] in return WatchScope(self) }()
    var watch: WatchScope {
        get {
            return _scope
        }
    }
    
    let url: URL
    var content: UIImage? = nil {
        didSet {
            _scope.notify()
        }
    }
    
    func fetch() -> Promise<WebImage> {
        return Fetch.url(url).then {
            (data: Data) -> WebImage in
            
            do {
                try data.write(to: self.cache)
            } catch {
                print("WebImage cache error")
            }
            
            self.content = UIImage(data:data)
            return self
        }
    }
    
    init(_ url: URL) {
        self.url = url
        let data = try? Data(contentsOf:cache)
        guard nil != data else {
            return
        }
        
        self.content = UIImage(data:data!)
    }
}
