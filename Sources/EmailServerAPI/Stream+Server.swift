//
//  Server+Stream.swift
//  email-server-api
//
//  Created by Milo Hehmsoth on 9/11/25.
//

import SwiftMail
import Foundation
import Logging

/// Active streams connecting a client to an SMTP server
public actor SMTPStreamStorage {
    /// Stream request from the client
    public typealias Inbound = Components.Schemas.SMTPServerStreamInput
    public typealias InboundStream = AsyncStream<Inbound>
    /// Stream response to the client
    public typealias Outbound  = Components.Schemas.SMTPServerStreamInput
    public typealias OutboundStream = AsyncStream<Outbound>
    
    /// Active sessions
    private var streams: [UUID: Task<Void, any Error>]
    
    var logger: Logger
    
    init(streams: [UUID: Task<Void, any Error>] = [:], logger: Logger = .init(label: "SMTP Stream Storage")) {
        self.logger = logger
        self.logger.logLevel = .trace
        self.streams = streams
    }
    
    /// The stream `continuation` was `.finished`
    private func finished(id: UUID) {
        self.logger.debug("Finished", metadata: ["id": "\(id.uuidString)"])
    }
    
    /// The stream `continuation` was `.cancelled`
    private func cancel(id: UUID) {
        self.logger.debug("Cancelled", metadata: ["id": "\(id.uuidString)"])
    }
    
    public func make(input: Operations.SmtpStream.Input, id: UUID = UUID()) async throws -> OutboundStream {
        let hostname = input.query.smtpHost
        let port = input.query.smtpHostPort
        let metadata: Logger.Metadata = ["id": "\(id.uuidString)", "hostname": "\(hostname)", "port": "\(port)"]
        self.logger.debug("Creating stream", metadata: metadata)
        
        let smtpServer = SwiftMail.SMTPServer.init(host: hostname, port: port, numberOfThreads: 1)
        try await smtpServer.connect()
        
        // make an outbound stream. setup what happens when we terminate the stream
        let (outbound, outboundContinuation) = OutboundStream.makeStream()
        outboundContinuation.onTermination = { termination in
            Task { [weak self] in
                switch termination {
                case .cancelled: await self?.cancel(id: id)
                case .finished: await self?.finished(id: id)
                default: await self?.finished(id: id)
                }
            }
        }
        
        //  make an inbound stream of request body
        let body = switch input.body { case .applicationJsonl(let body): body }
        let inboundStream = body.asDecodedJSONLines(of: Components.Schemas.SMTPServerStreamInput.self)
        let task = Task<Void, any Error> {
            for try await op in inboundStream {
                switch op.input {
                case .SMTPLogin(let login):
                    try await smtpServer.login(username: login.username, password: login.password)
                    self.logger.debug("Login", metadata: metadata)
                    
                case .SMTPLogout(_):
                    try await smtpServer.disconnect()
                    try await smtpServer.connect()
                    self.logger.debug("Reconnected", metadata: metadata)
                    
                case .SimpleSMTPEmail(let email):
                    self.logger.debug("Sending email", metadata: metadata)
                    try await smtpServer.sendEmail(.init(
                        sender: .init(name: email.sender.name, address: email.sender.address),
                        recipients: email.recepients.map { .init(name: $0.name, address: $0.address)},
                        ccRecipients: email.ccRecepients.map { .init(name: $0.name, address: $0.address)},
                        bccRecipients: email.bccRecepients.map { .init(name: $0.name, address: $0.address)},
                        subject: email.subject,
                        textBody: email.textBody,
                        htmlBody: email.htmlBody,
                        attachments: []))
                    self.logger.debug("Successfully sent email", metadata: metadata)
                    
                case .StreamKeepAlive(_):
                    self.logger.debug("Received keep-alive", metadata: metadata)
                    print("keep-alive")
                    break
                }
            }
            outboundContinuation.finish()
        }
        
        self.streams[id] = task
        return outbound
    }
}
//
//// MARK: Server Stream Storage
//public actor StreamStorage: Sendable {
//    private typealias StreamType = AsyncStream<Components.Schemas.SMTPServerStreamInput>
//    private var streams: [String: Task<Void, any Error>] = [:]
//    
//    
//    public init() {
//        
//    }
//    
//    private func finishedStream(id: String) {
//        print("Finishing stream \(id)")
//        guard self.streams[id] != nil else { return }
//        self.streams.removeValue(forKey: id)
//        print("Freed up stream \(id)")
//    }
//    private func cancelStream(id: String) {
//        print("Cancelling stream \(id)")
//        guard let task = self.streams[id] else { return }
//        self.streams.removeValue(forKey: id)
//        task.cancel()
//        print("Canceled stream \(id)")
//    }
//    
//    public func makeStream(input: Operations.SmtpStream.Input) -> AsyncStream<Components.Schemas.SMTPServerStreamInput> {
//        let name = input.query.smtpHost
//        let id = UUID().uuidString
//        print("Creating stream \(id) for name: \(name)")
//        let (stream, continuation) = StreamType.makeStream()
//        continuation.onTermination = { termination in
//            Task { [weak self] in
//                switch termination {
//                case .cancelled: await self?.cancelStream(id: id)
//                case .finished: await self?.finishedStream(id: id)
//                @unknown default: await self?.finishedStream(id: id)
//                }
//            }
//        }
//        let inputStream =
//            switch input.body {
//            case .applicationJsonl(let body): body.asDecodedJSONLines(of: Components.Schemas.SMTPServerStreamInput.self)
//            }
//        
//        let task = Task<Void, any Error> {
//            for try await message in inputStream {
//                try Task.checkCancellation()
//                switch message.input {
//                case .SimpleSMTPEmail(let email):
//                    print("Received \(email)")
//                case .SMTPLogin(let login):
//                    print("Received \(login)")
//                case .SMTPLogout(let logout):
//                    print("Received \(logout)")
//                case .StreamKeepAlive(let keepAlive):
//                    print("Recieved \(keepAlive)")
//                    guard keepAlive.keepAlive == true else {
//                        continuation.finish()
//                        break
//                    }
//                    let keepAlive: Components.Schemas.SMTPServerStreamInput = .init(input: .StreamKeepAlive(.init(keepAlive: true)))
//                    continuation.yield(keepAlive)
//                }
//            }
//            continuation.finish()
//        }
//        self.streams[id] = task
//        return stream
//    }
//}
//
