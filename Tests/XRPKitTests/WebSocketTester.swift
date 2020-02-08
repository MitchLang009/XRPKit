//
//  File.swift
//  
//
//  Created by Mitch Lang on 2/3/20.
//

import Foundation
import XRPKit

class WebSocketTester: XRPWebSocketDelegate {

    var completion: (XRPWebSocketResponse)->()
    
    init(completion: @escaping (XRPWebSocketResponse)->()) {
        self.completion = completion
    }
    
    func onConnected(connection: XRPWebSocket) {
        print("onConnected")
    }
    
    func onDisconnected(connection: XRPWebSocket, error: Error?) {
        print("onDisconnected")
    }
    
    func onError(connection: XRPWebSocket, error: Error) {
        print("onError")
    }
    
    func onResponse(connection: XRPWebSocket, response: XRPWebSocketResponse) {
        self.completion(response)
    }
    
    func onStream(connection: XRPWebSocket, object: NSDictionary) {
        print(object)
    }
}
