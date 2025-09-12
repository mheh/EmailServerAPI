//
//  EmailAPI.swift
//  gmail-openapi
//
//  Created by Milo Hehmsoth on 9/5/25.
//

import Foundation
import OpenAPIRuntime
import HTTPTypes

// MARK: Shared Handler
public struct Handler: APIProtocol {
    private let storage: SMTPStreamStorage = .init()
    
    public init () {}
    
    public func smtpStream(_ input: EmailServerAPI.Operations.SmtpStream.Input) async throws -> EmailServerAPI.Operations.SmtpStream.Output {
        do {
            let eventStream = try await self.storage.make(input: input, id: UUID())
            
            let responseBody = Operations.SmtpStream.Output.Ok.Body.applicationJsonl(
                .init(eventStream.stream.asEncodedJSONLines(), length: .unknown, iterationBehavior: .single)
            )
            
            return .ok(.init(body: responseBody))
        } catch {
            print(error)
            return .internalServerError
        }
    }
    
    public func smtpLogin(_ input: Operations.SmtpLogin.Input) async throws -> Operations.SmtpLogin.Output {
        guard let uuid = UUID.init(uuidString: input.path.smtpConnectionId) else {
            throw BodyError.badPathId(id: input.path.smtpConnectionId)
        }
        guard case .json(let body) = input.body else { throw BodyError.cannotDecodeBody }
        let streamState = try await self.storage.login(id: uuid, username: body.username, password: body.password)
        return .ok(.init(body: .json(streamState)))
    }
    
    public func smtpLogout(_ input: Operations.SmtpLogout.Input) async throws -> Operations.SmtpLogout.Output {
        guard let uuid = UUID.init(uuidString: input.path.smtpConnectionId) else {
            throw BodyError.badPathId(id: input.path.smtpConnectionId)
        }
        let streamState = try await self.storage.logout(id: uuid)
        return .ok(.init(body: .json(streamState)))
    }
    
    public func imapStream(_ input: Operations.ImapStream.Input) async throws -> Operations.ImapStream.Output {
        return .internalServerError
    }
}

extension Handler {
    enum BodyError: Error {
        case badPathId(id: String)
        case cannotDecodeBody
    }
}
