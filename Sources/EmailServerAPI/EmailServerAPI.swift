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

public actor ClientStream {
    public typealias StreamOutput = AsyncStream<EmailServerAPI.Components.Schemas.SMTPServerStreamInput>
    
    let output: StreamOutput
    let continuation: StreamOutput.Continuation
    
    public init(output: StreamOutput, continuation: StreamOutput.Continuation) async throws {
        self.output = output
        self.continuation = continuation
        try await Self.createTaskGroup(output: self.output, continuation: continuation)
    }
    
    public func handle(_ incoming: EmailServerAPI.Components.Schemas.SMTPServerStreamInput) async {
        print("handling message: \(incoming)")
    }
    
    public func send(_ outgoing: EmailServerAPI.Components.Schemas.SMTPServerStreamInput) {
        print("sending message: \(outgoing)")
    }
    
    static func createTaskGroup(output: StreamOutput, continuation: StreamOutput.Continuation) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                for try await message in output {
                    switch message.input {
                    case .SimpleSMTPEmail(let email):
                        print("Received \(email)")
                    case .SMTPLogin(let login):
                        print("Received \(login)")
                    case .SMTPLogout(let logout):
                        print("Received \(logout)")
                    case .StreamKeepAlive(let keepAlive):
                        print("Recieved \(keepAlive)")
                    }
                    continuation.yield(message)
                }
            }
            
            group.addTask {
                for _ in 0...100 {
                    try await Task.sleep(for: .seconds(2))
                    let keepAlive: Components.Schemas.SMTPServerStreamInput = .init(input: .StreamKeepAlive(.init(keepAlive: true)))
                    continuation.yield(keepAlive)
                }
            }
            
            return try await group.waitForAll()
        }
    }
}
