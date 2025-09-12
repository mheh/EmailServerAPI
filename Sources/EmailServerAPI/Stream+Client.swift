//
//  Client+Stream.swift
//  email-server-api
//
//  Created by Milo Hehmsoth on 9/11/25.
//

import Foundation
import OpenAPIRuntime
import Logging

// MARK: Client Streaming
public actor SMTPClientStream {
    /// Stream responses from server about status of a SMTP connection
    public typealias Inbound = Components.Schemas.SMTPServerStream
    public typealias InboundStream = AsyncThrowingMapSequence<JSONLinesDeserializationSequence<HTTPBody>, Inbound>
    
    public let inbound: InboundStream
    public var logger: Logger
    
    public init(
        smtpHost: String, smtpHostPort: Int, using client: Client, logger: Logger = .init(label: "SMTP Client Stream")
    ) async throws {
        // make outbound stream to server
        let inbound = try await Self.make(smtpHost: smtpHost, smtpHostPort: smtpHostPort, client: client)
        self.inbound = inbound
        self.logger = logger
    }
    
    static private func make(
        smtpHost: String, smtpHostPort: Int,
        client: Client
    ) async throws -> InboundStream {
        // fill out http req params and assign outbound stream
        let request: Operations.SmtpStream.Input = .init(
            query: .init(smtpHost: smtpHost, smtpHostPort: smtpHostPort))
        
        // send request, return inbound stream
        let res = try await client.smtpStream(request)
        let inbound = try res.ok.body.applicationJsonl.asDecodedJSONLines(of: Inbound.self)
        return inbound
    }
    
    static func taskGroup(inbound: InboundStream) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                for try await message in inbound {
                    
                }
            }
            
            try await group.waitForAll()
        }
    }
}


public actor ClientStream {
    public typealias StreamOutput = AsyncStream<EmailServerAPI.Components.Schemas.SMTPServerStream>
    
    let output: StreamOutput
    let continuation: StreamOutput.Continuation
    
    public init(output: StreamOutput, continuation: StreamOutput.Continuation) async throws {
        self.output = output
        self.continuation = continuation
        try await Self.createTaskGroup(output: self.output, continuation: continuation)
    }
    
    static func createTaskGroup(output: StreamOutput, continuation: StreamOutput.Continuation) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                for try await message in output {
                    switch message.serverMessage {
                    case .SMTPServerStreamConnectionClose(let connectionClose):
                        print(connectionClose)
                    case .SMTPServerStreamConnectionIDState(let idState):
                        print(idState)
                    }
                }
            }
            
            return try await group.waitForAll()
        }
    }
}
