//
//  EmailAPI.swift
//  gmail-openapi
//
//  Created by Milo Hehmsoth on 9/5/25.
//
import Foundation

public enum WebsocketCommands: Codable, Sendable {
    case connectionState(ConnectionState)
    case connect(Connect)
    case connectNewHost(ConnectNewHost)
    case login(Login)
    case disconnect(Disconnect)
    case send(Send)
    
    public func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        return data
    }
    
    public static func decode(data: Data) throws -> Self {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(WebsocketCommands.self, from: data)
        return decoded
    }
    
    public struct ConnectionState: Codable, Sendable {
        var command: String = "connection_state"
        public init() {}
    }
    
    public struct Connect: Codable, Sendable {
        var command: String = "connect"
        public init() {}
    }
    
    public struct ConnectNewHost: Codable, Sendable {
        var command: String = "reconnect"
        public var host: String
        public var port: Int
        public init(host: String, port: Int) {
            self.host = host
            self.port = port
        }
    }
    
    public struct Login: Codable, Sendable {
        var command: String = "login"
        public var username: String
        public var password: String
        public init(username: String, password: String) {
            self.username = username
            self.password = password
        }
    }
    
    public struct Disconnect: Codable, Sendable {
        var command: String = "disconnect"
        public init() {}
    }
    
    public struct Send: Codable, Sendable {
        var command: String = "send"
        public var sender: EmailAddress
        public var recipients: [EmailAddress]
        public var ccRecipients: [EmailAddress]
        public var bccRecipients: [EmailAddress]
        public var subject: String
        public var textBody: String
        public var htmlBody: String?
        
        public init(
            sender: EmailAddress,
            recipients: [EmailAddress],
            ccRecipients: [EmailAddress],
            bccRecipients: [EmailAddress],
            subject: String,
            textBody: String,
            htmlBody: String? = nil
        ) {
            self.sender = sender
            self.recipients = recipients
            self.ccRecipients = ccRecipients
            self.bccRecipients = bccRecipients
            self.subject = subject
            self.textBody = textBody
            self.htmlBody = htmlBody
        }
        
        public struct EmailAddress: Codable, Sendable {
            public var name: String?
            public var address: String
            public init(name: String? = nil, address: String) {
                self.name = name
                self.address = address
            }
        }
    }
}
