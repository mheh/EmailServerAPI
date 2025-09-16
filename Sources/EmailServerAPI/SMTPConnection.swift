//
//  SMTPConnection.swift
//  email-server-api
//
//  Created by Milo Hehmsoth on 9/14/25.
//

import SwiftMail
import Foundation
import Logging

/// An active SMTP connection
public actor SMTPConnection {
    public let id: UUID
    private var server: SMTPServer
    private var host: String
    private var port: Int
    
    private var isRunningCommand: Bool
    private var isConnected: Bool
    private var isLoggedIn: Bool
    
    private var lastCommandActivity: Date? = nil
    private var lastCommandSucceeded: Bool? = nil
    private var lastCommandSucceededDate: Date? = nil
    private var lastCommandFailedDate: Date? = nil
    
    public var logger: Logger
    
    public init(
        id: UUID,
        host: String,
        port: Int,
        isRunningCommand: Bool = false,
        isConnected: Bool = false,
        isLoggedIn: Bool = false,
        logger: Logger = .init(label: "SMTP Connection")
    ) {
        self.id = id
        self.server = SMTPServer(host: host, port: port)
        self.host = host
        self.port = port
        self.isRunningCommand = isRunningCommand
        self.isConnected = isConnected
        self.isLoggedIn = isLoggedIn
        self.logger = logger
    }
    
    public func state() -> WebsocketResponses.ConnectionState {
        return .init(
            id: self.id,
            host: self.host,
            port: self.port,
            isRunningCommand: self.isRunningCommand,
            isConnected: self.isConnected,
            isLoggedIn: self.isLoggedIn,
            lastCommandActivity: self.lastCommandActivity,
            lastCommandSucceeded: self.lastCommandSucceeded,
            lastCommandSucceededDate: self.lastCommandSucceededDate,
            lastCommandFailedDate: self.lastCommandFailedDate)
    }
    
    public func send(_ email: SwiftMail.Email) async throws {
        try hasState(isRunningCommand: false, isConnected: true, isLoggedIn: true)
        try await whileRunningCommand {
            try await self.server.sendEmail(email)
        }
    }
    
    /// Connect the SMTP server
    public func connect() async throws {
        try hasState(isRunningCommand: false, isConnected: false, isLoggedIn: false)
        
        try await whileRunningCommand {
            try await self.server.connect()
        }
        self.setIsConnected(true)
    }
    
    /// Login the SMTP server to a user account
    public func login(username: String, password: String) async throws {
        try hasState(isRunningCommand: false, isConnected: true, isLoggedIn: false)
        
        try await whileRunningCommand {
            try await self.server.login(username: username, password: password)
        }
        self.setIsLoggedIn(true)
    }
    
    /// Disconnect the SMTP server
    public func disconnect() async throws {
        try hasState(isRunningCommand: false, isConnected: true)
        
        try await whileRunningCommand {
            try await self.server.disconnect()
        }
        
        self.setIsLoggedIn(false)
        self.setIsConnected(false)
    }
    
    private func setIsRunningCommand(_ bool: Bool) { self.isRunningCommand = bool }
    private func setIsConnected(_ bool: Bool) { self.isConnected = bool }
    private func setIsLoggedIn(_ bool: Bool) { self.isLoggedIn = bool }
    
    private func timestampLastCommand() { self.lastCommandActivity = Date() }
    private func setLastCommandSucceeded(_ bool: Bool) { self.lastCommandSucceeded = bool }
    private func timestampLastCommandSuccededDate() { self.lastCommandSucceededDate = Date() }
    private func timestampLastCommandFailedDate() { self.lastCommandFailedDate = Date() }
    
    private func loggerMetadata() -> Logger.Metadata {
        return [
            "id": "\(self.id)",
            "host": "\(self.host)",
            "port": "\(self.port)",
            "self.isRunningCommand": "\(self.isRunningCommand)",
            "self.isConnected": "\(self.isConnected)",
            "self.isLoggedIn": "\(self.isLoggedIn)"
        ]
    }
    
    
    private func whileRunningCommand(
        operation: () async throws -> Void
    ) async throws {
        self.setIsRunningCommand(true)
        self.timestampLastCommand()
        do {
            try await operation()
        } catch {
            self.setIsRunningCommand(false)
            
            self.setLastCommandSucceeded(false)
            self.timestampLastCommandFailedDate()
            self.logger.error("Error encountered while running command: \(error)", metadata: loggerMetadata())
            throw error
        }
        self.setLastCommandSucceeded(true)
        self.timestampLastCommandSuccededDate()
        self.setIsRunningCommand(false)
    }
    
    private func hasState(isRunningCommand: Bool, isConnected: Bool, isLoggedIn: Bool) throws {
        try hasState(isRunningCommand: isRunningCommand)
        try hasState(isConnected: isConnected)
        try hasState(isLoggedIn: isLoggedIn)
    }
    
    private func hasState(isRunningCommand: Bool, isConnected: Bool) throws {
        try hasState(isRunningCommand: isRunningCommand)
        try hasState(isConnected: isConnected)
    }
    
    private func hasState(isRunningCommand: Bool) throws {
        guard self.isRunningCommand == isRunningCommand else {
            self.logger.error("isRunningCommand failed: \(isRunningCommand)", metadata: loggerMetadata())
            throw SMTPConnectionError.badIsRunningCommand(state: self.isRunningCommand, expected: isRunningCommand)
        }
    }
    
    private func hasState(isConnected: Bool) throws {
        guard self.isConnected == isConnected else {
            self.logger.error("isConnected failed: \(isConnected)", metadata: loggerMetadata())
            throw SMTPConnectionError.badIsConnected(state: self.isRunningCommand, expected: isConnected)
        }
    }
    
    private func hasState(isLoggedIn: Bool) throws {
        guard self.isLoggedIn == isLoggedIn else {
            self.logger.error("isLoggedIn failed: \(isLoggedIn)", metadata: loggerMetadata())
            throw SMTPConnectionError.badIsLoggedIn(state: self.isLoggedIn, expected: isLoggedIn)
        }
    }
    
    public enum SMTPConnectionError: Error {
        case badIsRunningCommand(state: Bool, expected: Bool)
        case badIsConnected(state: Bool, expected: Bool)
        case badIsLoggedIn(state: Bool, expected: Bool)
    }
}
