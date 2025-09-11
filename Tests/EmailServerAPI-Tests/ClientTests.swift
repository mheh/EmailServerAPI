//
//  ClientTests.swift
//  email-server-api
//
//  Created by Milo Hehmsoth on 9/10/25.
//

import Testing
import EmailServerAPI
import OpenAPIAsyncHTTPClient

@Suite("Client tests")
struct ClientTests {
    
    @Test("Client connect")
    func clientConnect() async throws {
        let client = Client(serverURL: .init(string: "http://127.0.0.1:8080")!, transport: AsyncHTTPClientTransport())
        
        // form the client output stream
        let (outStream, continuation) = AsyncStream<EmailServerAPI.Components.Schemas.SMTPServerStreamInput>.makeStream()
        
        let requestBody: Operations.SmtpStream.Input.Body = .applicationJsonl(
            .init(outStream.asEncodedJSONLines(), length: .unknown, iterationBehavior: .single)
        )
        
        let response = try await client.smtpStream(
            query: .init(smtpHost: "", smtpHostPort: 465),
            headers: .init(connection: "keep-alive"),
            body: requestBody)
        let serverStream = try response.ok.body.applicationJsonl.asDecodedJSONLines(of: String.self)
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Listen for upcoming messages
            group.addTask {
                for try await message in serverStream {
                    try Task.checkCancellation()
                    print("Got greeting: \(message)")
                }
            }
        
            // dummy messages
            group.addTask {
                for _ in 0...4 {
                    print("Sending a dummy message...")
//                    try await Task.sleep(nanoseconds: 1 * 1_000_000)
                    let yielding = EmailServerAPI.Components.Schemas.SMTPServerStreamInput.InputPayload.SMTPLogin(.init(username: "", password: ""))
                    continuation.yield(.init(input: yielding))
                    print("Sent a dummy message")
                }
                try Task.checkCancellation()
            }
            
            // Send messages
            group.addTask {
                try Task.checkCancellation()
                for try await output in outStream {
                    print("Sending output: \(output)")
                    continuation.yield(output)
                }
//                try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                continuation.finish()
            }
            return try await group.waitForAll()
        }
        
        
    }
}
