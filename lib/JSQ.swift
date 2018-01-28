//
//  JSQ.swift
//  EasySwift
//
//  Created by Serge Kutny on 1/27/18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import Foundation

/*
 Search engine for JSON
 Example queries:
 /a/b/c is equivalent to getting .a.b.c properties in JS
 /a/[1] is equivalent to .a[1]
 
 Queries must not contain spaces
 
 TODO: support predicates
 */
func JSQ(_ data: Any?, _ query: String) -> Any? {
    
    func prop(_ obj: Any?, _ name:String) -> Any? {
        guard nil != obj else {
            return nil
        }
        
        let dict = obj as? [String: Any]
        guard nil != dict else {
            return nil
        }
        
        return dict![name]
    }
    
    func i(_ obj: Any?, _ index: Int) -> Any? {
        guard nil != obj else {
            return nil
        }
        
        let array = obj as? [Any] ?? []
        guard (index < array.count) && (index >= 0) else {
            return nil
        }
        
        return array[index]
    }
    
    func index(from query: String) -> Int {
        let format = "^\\[\\d+\\]$"
        do {
            let regex = try NSRegularExpression(pattern:format)
            let matches = regex.matches(in: query, options: [], range: NSMakeRange(0, query.count))
            guard matches.count == 1 else {
                //query is not an index one
                return -1
            }
            
            let numeric = query.dropFirst().dropLast()
            return Int(numeric) ?? -1
        } catch {
            return -1;
        }
    }
    
    var parts = query.split(separator: "/", maxSplits: Int.max, omittingEmptySubsequences: true)
    var result = data
    while parts.count > 0 {
        let part = String(parts.remove(at:0))
        let pos = index(from:part)
        if (pos > -1) {
            result = i(result, pos)
        } else {
            result = prop(result, part)
        }
    }
    
    return result
}
