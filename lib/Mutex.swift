//
//  Mutex.swift
//  EasySwift
//
//  Created by sergii.kutnii on 18.05.18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import Foundation

/// A simple wrapper around a recursive POSIX mutex providing functionality similar to
/// Objective-C @synchronozed {}
public final class Synchronizer {
    private var _lock = pthread_mutex_t()
    
    init() {
        var attr = pthread_mutexattr_t()
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&_lock, &attr)
        pthread_mutexattr_destroy(&attr)
    }
    
    public func synchronized(_ block: () -> ()) {
        pthread_mutex_lock(&_lock)
        defer {
            pthread_mutex_unlock(&_lock)
        }
        
        block()
    }
}

/// A wrapper around a simple non-recursive mutex
public final class Mutex {
    private var _lock = pthread_mutex_t()
    
    init() {
        pthread_mutex_init(&_lock, nil)
    }
    
    public func lock() {
        pthread_mutex_lock(&_lock)
    }
    
    public func unlock() {
        pthread_mutex_unlock(&_lock)
    }
}
