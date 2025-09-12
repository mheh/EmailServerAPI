//
//  Client+Stream.swift
//  email-server-api
//
//  Created by Milo Hehmsoth on 9/11/25.
//

import Foundation
import OpenAPIRuntime

// MARK: Client Streaming
public actor SMTPClientStream {
    /// Stream response from server
    public typealias Inbound = Components.Schemas.SMTPServerStreamInput
    public typealias InboundStream = AsyncThrowingMapSequence<JSONLinesDeserializationSequence<HTTPBody>, Inbound>
    
    /// Stream request to server
    public typealias Outbound  = Components.Schemas.SMTPServerStreamInput
    public typealias OutboundStream = AsyncStream<Outbound>
    
    private let outbound: OutboundStream
    private let continuation: OutboundStream.Continuation
    
    public let inbound: InboundStream
    
    public init(
        smtpHost: String, smtpHostPort: Int, using client: Client
    ) async throws {
        // make outbound stream to server
        let (outbound, continuation) = OutboundStream.makeStream()
        let inbound = try await Self.make(smtpHost: smtpHost, smtpHostPort: smtpHostPort, outbound: outbound, client: client)
        
        self.outbound = outbound
        self.continuation = continuation
        
        self.inbound = inbound
    }
    
    static private func make(
        smtpHost: String, smtpHostPort: Int,
        outbound: OutboundStream,
        client: Client
    ) async throws -> InboundStream {
        // fill out http req params and assign outbound stream
        let request: Operations.SmtpStream.Input = .init(
            query: .init(smtpHost: smtpHost, smtpHostPort: smtpHostPort),
            body: .applicationJsonl(
                .init(outbound.asEncodedJSONLines(), length: .unknown, iterationBehavior: .single)
            ))
        
        // send request, return inbound stream
        let res = try await client.smtpStream(request)
        let inbound = try res.ok.body.applicationJsonl.asDecodedJSONLines(of: Inbound.self)
        return inbound
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
