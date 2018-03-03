//
//  Fetch.swift
//  EasySwift
//
//  Created by Serge Kutny on 1/26/18.
//  Copyright © 2018 skutnii. All rights reserved.
//

import Foundation

public enum FetchError : Error {
    case connectionError
    case httpError(Int)
    case noData
    case invalidLink(String)
    case parseError
}

class Fetch {
    
    class func request(_ request: URLRequest) -> Promise<Data> {
        let innerPromise = Promise<Data>()
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            guard nil == error else {
                innerPromise.reject(FetchError.connectionError)
                return
            }
            
            let code = (response as? HTTPURLResponse)?.statusCode ?? 400
            guard code <= 400 else {
                innerPromise.reject(FetchError.httpError(code))
                return
            }
            
            guard nil != data else {
                innerPromise.reject(FetchError.noData)
                return
            }
            
            innerPromise.resolve(data!)
        }
        
        let promise = Promise<Data>(discard: {
            [weak task] in
            task?.cancel()
        })
        
        promise.chain(after: innerPromise)
        task.resume()
        
        return promise
    }
    
    class func url(_ url: URL) -> Promise<Data> {
        return request(URLRequest(url:url))
    }
    
    class func from(_ link: String) -> Promise<Data> {
        let url = URL(string: link)
        guard nil != url else {
            return Promise<Data>.reject(FetchError.invalidLink(link))
        }
        
        return request(URLRequest(url: url!))
    }
    
    class func json(request: URLRequest) -> Promise<Any> {
        return self.request(request).then  {
            data -> Any in
            do {
                let content = try JSONSerialization.jsonObject(with: data, options: [])
                return content
            } catch {
                throw FetchError.parseError
            }
        }
    }
    
    class func json(_ link: String) -> Promise<Any> {
        let url = URL(string: link)
        guard nil != url else {
            return Promise<Any>.reject(FetchError.invalidLink(link))
        }
        
        return json(request: URLRequest(url: url!))
    }
    
    
}
