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
    /// Stream responses to the client
    public typealias Outbound = Components.Schemas.SMTPServerStream
    public typealias OutboundStream = AsyncStream<Outbound>
    
    private var streams: [UUID: ActiveStream]
    
    var logger: Logger
    
    init(logger: Logger = .init(label: "SMTP Stream Storage")) {
        self.logger = logger
        self.logger.logLevel = .trace
        self.streams = [:]
    }
    
    func send(id: UUID, email: Components.Schemas.SimpleSMTPEmail) async throws {
        guard let found = self.find(id: id) else { throw SMTPStreamError.notFound(id: id) }
        guard await found.isLoggedIn else { throw SMTPStreamError.isNotLoggedIn }
        do {
            try await found.server.sendEmail(.init(
                sender: .init(name: email.sender.name, address: email.sender.address),
                recipients: email.recepients.map { .init(name: $0.name, address: $0.address)},
                ccRecipients: email.ccRecepients.map { .init(name: $0.name, address: $0.address)},
                bccRecipients: email.bccRecepients.map { .init(name: $0.name, address: $0.address)},
                subject: email.subject,
                textBody: email.textBody,
                htmlBody: email.htmlBody,
                attachments: nil))
        } catch {
            found.continuation.yield(.init(serverMessage: .SMTPServerStreamConnectionClose(true)))
            throw SMTPStreamError.unexpected(error: error)
        }
    }
    
    
    public func login(id: UUID, username: String, password: String) async throws -> Components.Schemas.SMTPServerStreamConnectionIDState {
        guard let found = self.find(id: id) else { throw SMTPStreamError.notFound(id: id) }
        guard await !found.isLoggedIn else { throw SMTPStreamError.isLoggedIn }
        
        // try to login
        do {
            try await found.server.login(username: username, password: password)
            await found.isLoggedIn(true)
        } catch {
            self.logger.error("Error during login \(error.localizedDescription)")
            return .init(id: id.uuidString, _type: .open)
        }
        
        // remove from local state
        let newId = UUID()
        self.streams.removeValue(forKey: id)
        self.streams[newId] = found
        
        // send an update over the stream
        let streamState: Components.Schemas.SMTPServerStreamConnectionIDState = .init(id: newId.uuidString, _type: .inuse)
        found.continuation.yield(.init(
            serverMessage: .SMTPServerStreamConnectionIDState(
                streamState)))
        return streamState
    }
    
    
    public func logout(id: UUID) async throws -> Components.Schemas.SMTPServerStreamConnectionIDState {
        guard let found = self.find(id: id) else { throw SMTPStreamError.notFound(id: id) }
        guard await found.isLoggedIn else { throw SMTPStreamError.isNotLoggedIn }
     
        do {
            try await found.server.disconnect()
            await found.isLoggedIn(false)
        } catch {
            self.logger.error("Error during disconnect \(error)")
            return .init(id: id.uuidString, _type: .inuse)
        }
        do {
            try await found.server.connect()
        } catch {
            self.logger.error("Error during reconnect \(error)")
            return .init(id: id.uuidString, _type: .open)
        }
        
        // remove from state and reinsert at new id
        let newId = UUID()
        self.streams.removeValue(forKey: id)
        self.streams[newId] = found
        
        let streamState: Components.Schemas.SMTPServerStreamConnectionIDState = .init(id: newId.uuidString, _type: .open)
        
        found.continuation.yield(.init(
            serverMessage: .SMTPServerStreamConnectionIDState(
                streamState)))
        
        return streamState
    }
    
    /// The stream `continuation` was `.finished`
    private func finished(id: UUID) {
        guard let found = self.find(id: id) else { return }
        self.streams.removeValue(forKey: id)
        if !found.task.isCancelled { found.task.cancel() }
        self.logger.debug("Finished", metadata: ["id": "\(id.uuidString)"])
    }
    
    /// The stream `continuation` was `.cancelled`
    private func cancel(id: UUID) {
        guard let found = self.find(id: id) else { return }
        self.streams.removeValue(forKey: id)
        found.task.cancel()
        self.logger.debug("Cancelled", metadata: ["id": "\(id.uuidString)"])
    }
    
    private func find(id: UUID) -> ActiveStream? {
        guard let found = self.streams[id] else { return nil }
        return found
    }
    
    public func make(input: Operations.SmtpStream.Input, id: UUID = UUID()) async throws -> ActiveStream {
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
        
        let task = Task {
            for try await message in outbound {
                switch message.serverMessage {
                case .SMTPServerStreamConnectionClose(_):
                    break
                default:
                    continue
                }
                break
            }
            outboundContinuation.finish()
        }
        
        let activeStream = ActiveStream(
            stream: outbound,
            continuation: outboundContinuation,
            server: smtpServer,
            task: task
        )
        self.streams[id] = activeStream
        return activeStream
    }
    
    public actor ActiveStream: Sendable {
        public let stream: OutboundStream
        public let continuation: OutboundStream.Continuation
        public let server: SMTPServer
        let task: Task<Void, any Error>
        public var isLoggedIn: Bool = false
        
        public func isLoggedIn(_ bool: Bool) {
            self.isLoggedIn = bool
        }
        
        public init(stream: OutboundStream, continuation: OutboundStream.Continuation, server: SMTPServer, task: Task<Void, any Error>) {
            self.stream = stream
            self.continuation = continuation
            self.server = server
            self.task = task
        }
    }
    
    enum SMTPStreamError: Error {
        case notFound(id: UUID)
        case isLoggedIn
        case isNotLoggedIn
        case unexpected(error: any Error)
    }
}

