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
import BlueSocket

import Foundation

// MARK: RouterRequest

public class RouterRequest: BlueSocketReader {

    ///
    /// The server request
    ///
    let serverRequest: ServerRequest
    
    ///
    /// The parsed url
    ///
    let parsedUrl: UrlParser
    
    ///
    /// The router as a String
    ///
    public internal(set) var route: String?
    
    ///
    /// The original url as a string
    ///
    public var originalUrl: String {
        return serverRequest.urlString
    }
    
    ///
    /// The URL
    ///
    public var url: String
    
    ///
    /// List of HTTP headers
    ///
    public var headers: [String:String] { return serverRequest.headers }
    
    ///
    /// List of URL parameters
    ///
    public var params: [String:String] = [:]
    
    ///
    /// List of query parameters
    ///
    public var queryParams: [String:String] { return parsedUrl.queryParams }
    
    ///
    /// User info
    ///
    public var userInfo: [String: AnyObject] = [:]

    /// 
    /// Body of the message
    ///
    public internal(set) var body: ParsedBody? = nil
    
    ///
    /// Initializes a RouterRequest instance
    ///
    /// - Parameter request: the server request
    ///
    /// - Returns: a RouterRequest instance
    ///
    init(request: ServerRequest) {
        serverRequest = request
        parsedUrl = UrlParser(url: serverRequest.url, isConnect: false)
        url = String(serverRequest.urlString)
    }
    
    ///
    /// Read data
    ///
    /// - Parameter data: the data
    ///
    /// - Throws: ???
    /// - Returns: the number of bytes read
    ///
    public func readData(data: NSMutableData) throws -> Int {
        return try serverRequest.readData(data)
    }
    
    ///
    /// Read string
    ///
    /// - Throws: ???
    /// - Returns: the String
    ///
    public func readString() throws -> String? {
        return try serverRequest.readString()
    }
    
}
