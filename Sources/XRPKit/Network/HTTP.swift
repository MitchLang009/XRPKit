//
//  File.swift
//  
//
//  Created by Mitch Lang on 1/30/20.
//

import Foundation
import NIO
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif
#if canImport(CoreFoundation)
    import CoreFoundation
#endif

let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)

class HTTP {
    
    // http call to test linux cross platform
    static func post(url: URL, parameters: [String: Any]) -> EventLoopFuture<Any> {
        
        let promise = eventGroup.next().makePromise(of: Any.self)
        
        let httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody

        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                promise.fail(error)
            }
//            if let response = response {
//                print(response)
//            }
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    promise.succeed(json)
                } catch {
                    promise.fail(error)
                }
            }
        }.resume()
        
        return promise.futureResult
        
    }
}
