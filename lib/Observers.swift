//
//  WatchScope.swift
//  EasySwift
//
//  Created by Serge Kutny on 1/27/18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import Foundation

protocol Observer : AnyObject {
    func onChange(_ :AnyObject)
}

protocol Observable {
    var watch: WatchScope { get }
}

//TODO: thread safety
class WatchScope {
    
    weak var observable: AnyObject?
    
    private class Watcher {
        
        weak var delegate: Observer?
        
        init(_ target: Observer) {
            delegate = target
        }
    }
    
    private var watchers = [Watcher]()
    
    //Collect garbage: watchers whose delegates have gone
    private func gc() {
        watchers = watchers.filter {
            watcher in
            return (nil != watcher.delegate)
        }
    }
    
    //Attention: avoid strong references in callbacks
    func add(watcher: Observer) {
        gc()
        watchers.append(Watcher(watcher))
    }
    
    func remove(watcher: Observer) {
        gc()
        watchers = watchers.filter {
            theWatcher in
            return (theWatcher.delegate !== watcher)
        }
    }
    
    var empty: Bool {
        get {
            return (watchers.count == 0)
        }
    }
    
    func notify() {
        guard nil != observable else {
            return
        }
        
        let object = observable!
        
        watchers.forEach {
            watcher in
            watcher.delegate?.onChange(object)
        }
    }
    
    init(_ observable: AnyObject) {
        self.observable = observable
    }
}

