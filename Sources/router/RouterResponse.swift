/**
 * Copyright IBM Corporation 2016
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
import sys

// For JSON parsing support
import SwiftyJSON

import Foundation

// MARK: RouterResponse

public class RouterResponse {

    ///
    /// The server response
    ///
    let response: ServerResponse
    
    ///
    /// The buffer used for output
    ///
    private let buffer = BufferList()

    ///
    /// Whether the response has ended
    ///
    var invokedEnd = false
    
    /// 
    /// Optional error value
    ///
    public var error: NSError?
    
    
    ///
    /// Initializes a RouterResponse instance
    ///
    /// - Parameter response: the server response
    ///
    /// - Returns: a ServerResponse instance
    ///
    init(response: ServerResponse) {
        
        self.response = response
        status(HttpStatusCode.NOT_FOUND)
        
    }
    
    ///
    /// Ends the response
    ///
    /// - Throws: ???
    /// - Returns: a RouterResponse instance
    ///
    public func end() throws -> RouterResponse {
        
        if  let data = buffer.data  {
            let contentLength = getHeader("Content-Length")
            if  contentLength == nil  {
                setHeader("Content-Length", value: String(buffer.count))
            }
            try response.writeData(data)
        }
        invokedEnd = true
        try response.end()
        return self
    }
    
    ///
    /// Ends the response and sends a string
    ///
    /// - Parameter str: the String before the response ends
    ///
    /// - Throws: ???
    /// - Returns: a RouterResponse instance
    ///
    public func end(str: String) throws -> RouterResponse {
        
        send(str)
        try end()
        return self
        
    }
    
    ///
    /// Ends the response and sends data
    ///
    /// - Parameter data: the data to send before the response ends
    ///
    /// - Throws: ???
    /// - Returns: a RouterResponse instance
    ///
    public func end(data: NSData) throws -> RouterResponse {
        
        sendData(data)
        try end()
        return self
        
    }
    
    ///
    /// Sends a string
    ///
    /// - Parameter str: the string to send
    ///
    /// - Returns: a RouterResponse instance
    ///
    public func send(str: String) -> RouterResponse {
        
        if  let data = StringUtils.toUtf8String(str)  {
            buffer.appendData(data)
        }
        return self
        
    }

    ///
    /// Sends data
    ///
    /// - Parameter data: the data to send
    ///
    /// - Returns: a RouterResponse instance
    ///
    public func sendData(data: NSData) -> RouterResponse {
        
        buffer.appendData(data)
        return self
        
    }

    ///
    /// Sends a file
    ///
    /// - Parameter fileName: the name of the file to send.
    ///
    /// - Returns: a RouterResponse instance
    ///
    /// Note: Sets the Content-Type header based on the "extension" of the file
    ///       If the fileName is relative, it is relative to the current directory
    ///
    public func sendFile(fileName: String) throws -> RouterResponse {
        let data = try NSData(contentsOfFile: fileName, options: [])

        let lastPathElemRange: Range<String.Index>
        if  let lastSlash = fileName.rangeOfString("/", options: NSStringCompareOptions.BackwardsSearch)  {
            lastPathElemRange = Range(start: lastSlash.startIndex.successor(), end: fileName.characters.endIndex)
        }
        else {
            lastPathElemRange = Range(start: fileName.characters.startIndex, end: fileName.characters.endIndex)
        }

        let extRange: Range<String.Index>
        if  let lastDot = fileName.rangeOfString(".", range: lastPathElemRange)  {
            extRange = Range(start: lastDot.startIndex.successor(), end: fileName.characters.endIndex)
        }
        else {
            // No "extension", use the entire last path element as the "extension"
            extRange = lastPathElemRange
        }

        let contentType =  ContentType.contentTypeForExtension(fileName.substringWithRange(extRange))
        if  let contentType = contentType  {
            setHeader("Content-Type", value: contentType)
        }

        buffer.appendData(data)

        return self
    }
    
    ///
    /// Sends JSON
    ///
    /// - Parameter json: the JSON object to send
    ///
    /// - Returns: a RouterResponse instance
    ///
    public func sendJson(json: JSON) -> RouterResponse {
        
        let jsonStr = json.description
        setHeader("Content-Type", value: ContentType.contentTypeForExtension("json")!)
        send(jsonStr)
        return self
        
    }
    
    ///
    /// Set the status code
    ///
    /// - Parameter status: the status code integer
    ///
    /// - Returns: a RouterResponse instance
    ///
    public func status(status: Int) -> RouterResponse {
        response.status = status
        return self
    }
    
    ///
    /// Set the status code
    ///
    /// - Parameter status: the status code object
    ///
    /// - Returns: a RouterResponse instance
    ///
    public func status(status: HttpStatusCode) -> RouterResponse {
        response.statusCode = status
        return self
    }
    
    ///
    /// Sends the status code
    ///
    /// - Parameter status: the status code integer
    ///
    /// - Throws: ???
    /// - Returns: a RouterResponse instance
    ///
    public func sendStatus(status: Int) throws -> RouterResponse {
        
        self.status(status)
        if  let statusText = Http.statusCodes[status] {
            send(statusText)
        }
        else {
            send(String(status))
        }
        return self

    }
    
    ///
    /// Sends the status code
    ///
    /// - Parameter status: the status code object
    ///
    /// - Throws: ???
    /// - Returns: a RouterResponse instance
    ///
    public func sendStatus(status: HttpStatusCode) throws -> RouterResponse {
        
        self.status(status)
        send(Http.statusCodes[status.rawValue]!)
        return self

    }
    
    ///
    /// Gets the header
    /// 
    /// - Parameter key: the key
    /// 
    /// - Returns: the value for the key
    ///
    public func getHeader(key: String) -> String? {
        
        return response.getHeader(key)
        
    }
    
    ///
    /// Gets the header that contains multiple values
    ///
    /// - Parameter key: the key
    ///
    /// - Returns: the value for the key as a list
    ///
    public func getHeaders(key: String) -> [String]? {
        
        return response.getHeaders(key)
        
    }
    
    ///
    /// Set the header value
    ///
    /// - Parameter key: the key
    /// - Parameter value: the value
    ///
    /// - Returns: the value for the key as a list
    ///
    public func setHeader(key: String, value: String) {
        
        response.setHeader(key, value: value)
        
    }
    
    public func setHeader(key: String, value: [String]) {
        
        response.setHeader(key, value: value)
        
    }
    
    ///
    /// Remove the header by key
    /// 
    /// - Parameter key: the key
    ///
    public func removeHeader(key: String) {
        
        response.removeHeader(key)
        
    }
    
    ///
    /// Redirect to path
    ///
    /// - Parameter: the path for the redirect 
    ///
    /// - Returns: a RouterResponse instance
    ///
    public func redirect(path: String) throws -> RouterResponse {
        return try redirect(.MOVED_TEMPORARILY, path: path)
    }
    
    ///
    /// Redirect to path with status code
    ///
    /// - Parameter: the status code for the redirect
    /// - Parameter: the path for the redirect
    ///
    /// - Returns: a RouterResponse instance
    ///
    public func redirect(status: HttpStatusCode, path: String) throws -> RouterResponse {
        
        try redirect(status.rawValue, path: path)
        return self
        
    }

    ///
    /// Redirect to path with status code
    ///
    /// - Parameter: the status code for the redirect
    /// - Parameter: the path for the redirect
    ///
    /// - Returns: a RouterResponse instance
    ///
    public func redirect(status: Int, path: String) throws -> RouterResponse {
        
        try self.status(status).location(path).end()
        return self
        
    }
    
    ///
    /// Sets the location path
    ///
    /// - Parameter path: the path 
    ///
    /// - Returns: a RouterResponse instance
    ///
    public func location(path: String) -> RouterResponse {
        
        var p = path
        if  p == "back" {
            let referrer = getHeader("referrer")
            if  let r = referrer {
                p = r
            }
            else {
                p = "/"
            }
        }
        setHeader("Location", value: p)
        return self
        
    }
}
