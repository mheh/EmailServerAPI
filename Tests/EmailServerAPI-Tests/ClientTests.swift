//
//  ClientTests.swift
//  email-server-api
//
//  Created by Milo Hehmsoth on 9/10/25.
//

import Testing
import EmailServerAPI
import OpenAPIAsyncHTTPClient
import OpenAPIRuntime
import Foundation
import HTTPTypes

@Suite("Client tests")
struct ClientTests {
    
    @Test("Client connect")
    func clientConnect() async throws {
        let client = Client(
            serverURL: .init(string: "http://127.0.0.1:8080")!,
            transport: AsyncHTTPClientTransport(),
            middlewares: [LoggingMiddleware()]
        )
        
        let clientStream = try await SMTPClientStream(smtpHost: "phoenix-repair-pos.com", smtpHostPort: 465, using: client)
        for try await message in await clientStream.inbound {
            print(message.input)
        }
    }
}

struct LoggingMiddleware: ClientMiddleware {
    func intercept(
        _ request: HTTPTypes.HTTPRequest, body: OpenAPIRuntime.HTTPBody?, baseURL: URL, operationID: String,
        next: @Sendable (HTTPTypes.HTTPRequest, OpenAPIRuntime.HTTPBody?, URL) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?)
    ) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?) {
        
        print(request.headerFields)
        print(request.path ?? "none")
        let copy = body
        
        if let body {
            switch body.length {
            case .known(let length):
                let bodyData = try await Data(collecting: body, upTo: Int(length))
                if let string = String(data: bodyData, encoding: .utf8) {
                    print(string)
                }
            case .unknown:
                break
            }
        }
        
        return try await next(request, copy, baseURL)
    }
}
