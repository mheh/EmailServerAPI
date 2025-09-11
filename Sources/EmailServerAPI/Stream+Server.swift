//
//  Server+Stream.swift
//  email-server-api
//
//  Created by Milo Hehmsoth on 9/11/25.
//

import Foundation
import Logging

public actor StreamStorageV2 {
    typealias InboundIn = Components.Schemas.SMTPServerStreamInput
    
}

// MARK: Server Stream Storage
public actor StreamStorage: Sendable {
    private typealias StreamType = AsyncStream<Components.Schemas.SMTPServerStreamInput>
    private var streams: [String: Task<Void, any Error>] = [:]
    
    
    public init() {
        
    }
    
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

