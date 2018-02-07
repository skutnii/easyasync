//
//  Fetch.swift
//  EasySwift
//
//  Created by Serge Kutny on 1/26/18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import Foundation

class Fetch {
    
    class func request(_ request: URLRequest) -> Promise<Data> {
        return Promise<Data> {
            resolve, reject in
            
            URLSession.shared.dataTask(with: request) {
                data, response, error in
                guard nil == error else {
                    reject("Connection error")
                    return
                }
                
                let code = (response as? HTTPURLResponse)?.statusCode ?? 400
                guard code <= 400 else {
                    reject("HTTP error \(code)")
                    return
                }
                
                guard nil != data else {
                    reject("No data")
                    return
                }
                
                resolve(data!)
            } .resume()
        }
    }
    
    class func url(_ url: URL) -> Promise<Data> {
        return request(URLRequest(url:url))
    }
    
    class func from(_ link: String) -> Promise<Data> {
        let url = URL(string: link)
        guard nil != url else {
            return Promise<Data>.reject("Invalid URL \(link)")
        }
        
        return request(URLRequest(url: url!))
    }
    
    class func json(request: URLRequest) -> Promise<Any> {
        return self.request(request).then  {
            data in
            do {
                let content = try JSONSerialization.jsonObject(with: data, options: [])
                return content
            } catch {
                return Promise<Any>.reject("Parse error")
            }
        }
    }
    
    class func json(_ link: String) -> Promise<Any> {
        let url = URL(string: link)
        guard nil != url else {
            return Promise.reject("Invalid URL \(link)")
        }
        
        return json(request: URLRequest(url: url!))
    }
    
    
}
