//
//  EmailAPI.swift
//  gmail-openapi
//
//  Created by Milo Hehmsoth on 9/5/25.
//

import Foundation
import OpenAPIRuntime
import HTTPTypes

// MARK: Client Streaming

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

// MARK: Server Stream Storage
public actor StreamStorage: Sendable {
    private typealias StreamType = AsyncStream<Components.Schemas.SMTPServerStreamInput>
    private var streams: [String: Task<Void, any Error>] = [:]
    
    public init() {}
    
    private func finishedStream(id: String) {
        print("Finishing stream \(id)")
        guard self.streams[id] != nil else { return }
        self.streams.removeValue(forKey: id)
        print("Freed up stream \(id)")
    }
    private func cancelStream(id: String) {
        print("Cancelling stream \(id)")
        guard let task = self.streams[id] else { return }
        self.streams.removeValue(forKey: id)
        task.cancel()
        print("Canceled stream \(id)")
    }
    
    public func makeStream(input: Operations.SmtpStream.Input) -> AsyncStream<Components.Schemas.SMTPServerStreamInput> {
        let name = input.query.smtpHost
        let id = UUID().uuidString
        print("Creating stream \(id) for name: \(name)")
        let (stream, continuation) = StreamType.makeStream()
        continuation.onTermination = { termination in
            Task { [weak self] in
                switch termination {
                case .cancelled: await self?.cancelStream(id: id)
                case .finished: await self?.finishedStream(id: id)
                @unknown default: await self?.finishedStream(id: id)
                }
            }
        }
        let inputStream =
            switch input.body {
            case .applicationJsonl(let body): body.asDecodedJSONLines(of: Components.Schemas.SMTPServerStreamInput.self)
            }
        let task = Task<Void, any Error> {
            for try await message in inputStream {
                try Task.checkCancellation()
                switch message.input {
                case .SimpleSMTPEmail(let email):
                    print("Received \(email)")
                case .SMTPLogin(let login):
                    print("Received \(login)")
                case .SMTPLogout(let logout):
                    print("Received \(logout)")
                case .StreamKeepAlive(let keepAlive):
                    print("Recieved \(keepAlive)")
                    guard keepAlive.keepAlive == true else {
                        continuation.finish()
                        break
                    }
                    let keepAlive: Components.Schemas.SMTPServerStreamInput = .init(input: .StreamKeepAlive(.init(keepAlive: true)))
                    continuation.yield(keepAlive)
                }
            }
            continuation.finish()
        }
        self.streams[id] = task
        return stream
    }
}

