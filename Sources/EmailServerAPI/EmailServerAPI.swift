//
//  EmailAPI.swift
//  gmail-openapi
//
//  Created by Milo Hehmsoth on 9/5/25.
//

import Foundation
import OpenAPIRuntime
import HTTPTypes

/// Insert the username and password as basic auth
public struct BasicAuthMiddleware: ClientMiddleware {
    let base64String: String
    
    public init(base64String: String) {
        self.base64String = base64String
    }
    
    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var headers = request.headerFields
        headers.append(.init(name: .authorization, value: "Basic \(self.base64String)"))
        let newRequest: HTTPRequest = .init(
            method: request.method,
            scheme: request.scheme,
            authority: request.authority,
            path: request.path,
            headerFields: headers)
        return try await next(newRequest, body, baseURL)
    }
}
