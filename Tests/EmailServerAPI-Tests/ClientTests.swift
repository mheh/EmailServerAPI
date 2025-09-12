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
        
        // form the client output stream
        let (outStream, continuation) = AsyncStream<EmailServerAPI.Components.Schemas.SMTPServerStreamInput>.makeStream()
        
        let requestBody: Operations.SmtpStream.Input.Body = .applicationJsonl(
            .init(outStream.asEncodedJSONLines(), length: .unknown, iterationBehavior: .single)
        )
        
        do {
            let req = try await client.smtpStream(
                query: .init(smtpHost: "phoenix-repair-pos.com", smtpHostPort: 465),
                body: requestBody)
            
            let response = try req.ok.body.applicationJsonl.asDecodedJSONLines(of: EmailServerAPI.Components.Schemas.SMTPServerStreamInput.self)
            let streamer = try await ClientStream(output: outStream, continuation: continuation)
            for try await message in response {
                await streamer.handle(message)
            }
        } catch {
            print(error)
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
