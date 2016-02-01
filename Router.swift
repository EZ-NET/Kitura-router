/**
 * Copyright IBM Corporation 2015
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import net
import regex
import sys
import Logger

import Foundation

public class Router {
    private var routeElems: [RouterElement] = []
    
    public init() {
        ContentType.initialize()
        Log.verbose("Router initialized")
    }
    
    public func all(handler: RouterHandler) -> Router {
        return routingHelper(.All, pattern: nil, handler: handler)
    }
    
    public func all(path: String, handler: RouterHandler) -> Router {
        return routingHelper(.All, pattern: path, handler: handler)
    }
    
    public func get(handler: RouterHandler) -> Router {
        return routingHelper(.Get, pattern: nil, handler: handler)
    }
    
    public func get(path: String, handler: RouterHandler) -> Router {
        return routingHelper(.Get, pattern: path, handler: handler)
    }
    
    public func post(handler: RouterHandler) -> Router {
        return routingHelper(.Post, pattern: nil, handler: handler)
    }
    
    public func post(path: String, handler: RouterHandler) -> Router {
        return routingHelper(.Post, pattern: path, handler: handler)
    }
    
    public func put(handler: RouterHandler) -> Router {
        return routingHelper(.Put, pattern: nil, handler: handler)
    }
    
    public func put(path: String, handler: RouterHandler) -> Router {
        return routingHelper(.Put, pattern: path, handler: handler)
    }
    
    public func delete(handler: RouterHandler) -> Router {
        return routingHelper(.Delete, pattern: nil, handler: handler)
    }
    
    public func delete(path: String, handler: RouterHandler) -> Router {
        return routingHelper(.Delete, pattern: path, handler: handler)
    }

    public func use(middleware: RouterMiddleware) -> Router {
        routeElems.append(RouterElement(method: .All, pattern: nil, middleware: middleware))
        return self
    }
    
    public func use(path: String, middleware: RouterMiddleware) -> Router {
        routeElems.append(RouterElement(method: .All, pattern: path, middleware: middleware))
        return self
    }

    private func routingHelper(method: RouterMethod, pattern: String?, handler: RouterHandler) -> Router {
        routeElems.append(RouterElement(method: method, pattern: pattern, handler: handler))
        return self
    }
}


extension Router : HttpServerDelegate {

    public func handleRequest(request: ServerRequest, response: ServerResponse) {
        let routeReq = RouterRequest(request: request)
        let routeResp = RouterResponse(response: response)
        let method = RouterMethod(string: request.method)
        
        let urlPath = StringUtils.toUtf8String(routeReq.parsedUrl.path!)
        if  urlPath != nil  {
            var handled = false
            var elemIndex = -1
        
            // Extra variable to get around use of variable in its own initializer
            var callback: ((processed: Bool)->Void)? = nil
        
            let callbackHandler = {(processed: Bool) -> Void in
                if  processed  {
                    handled = true
                }
                elemIndex+=1
                if  elemIndex < self.routeElems.count  &&  routeResp.error == nil {
                    self.routeElems[elemIndex].process(method, urlPath: urlPath!, request: routeReq, response: routeResp, next: callback!)
                }
                else {
                    do {
                        if  routeResp.error != nil  {
                            let message = "Server error: \(routeResp.error!.localizedDescription)"
                            Log.error(message)
                            try routeResp.status(.INTERNAL_SERVER_ERROR).end(message)
                        }
                        else if  !handled {
                            try routeResp.sendStatus(.NOT_FOUND).end()
                        }
                    }
                    catch {
                        // Not much to do here
                    }
                }
            }
            callback = callbackHandler
        
            callbackHandler(false)
        }
    }
}


