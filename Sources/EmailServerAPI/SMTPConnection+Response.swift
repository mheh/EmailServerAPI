//
//  SMTPConnection+Response.swift
//  email-server-api
//
//  Created by Milo Hehmsoth on 9/14/25.
//

import Foundation

public enum WebsocketResponses: Codable {
    case state(ConnectionState)
    
    public func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        return data
    }
    
    public struct ConnectionState: Codable, Sendable {
        public var id: UUID
        public var host: String
        public var port: Int
        
        public var isRunningCommand: Bool
        public var isConnected: Bool
        public var isLoggedIn: Bool
        
        public var lastCommandActivity: Date?
        public var lastCommandSucceeded: Bool?
        public var lastCommandSucceededDate: Date?
        public var lastCommandFailedDate: Date?
        
        public init(
            id: UUID,
            host: String,
            port: Int,
            isRunningCommand: Bool,
            isConnected: Bool,
            isLoggedIn: Bool,
            lastCommandActivity: Date?,
            lastCommandSucceeded: Bool?,
            lastCommandSucceededDate: Date?,
            lastCommandFailedDate: Date?
        ) {
            self.id = id
            self.host = host
            self.port = port
            self.isRunningCommand = isRunningCommand
            self.isConnected = isConnected
            self.isLoggedIn = isLoggedIn
            self.lastCommandActivity = lastCommandActivity
            self.lastCommandSucceeded = lastCommandSucceeded
            self.lastCommandSucceededDate = lastCommandSucceededDate
            self.lastCommandFailedDate = lastCommandFailedDate
        }
    }
}
