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
    private let storage: StreamStorage = .init()
    
    public init () {}
    
    public func smtpStream(_ input: EmailServerAPI.Operations.SmtpStream.Input) async throws -> EmailServerAPI.Operations.SmtpStream.Output {
        let eventStream = await self.storage.makeStream(input: input)
        
        let responseBody = Operations.SmtpStream.Output.Ok.Body.applicationJsonl(
            .init(eventStream.asEncodedJSONLines(), length: .unknown, iterationBehavior: .single)
        )
        
        return .ok(.init(body: responseBody))
    }
    
    public func imapStream(_ input: Operations.ImapStream.Input) async throws -> Operations.ImapStream.Output {
        return .internalServerError
    }
}

