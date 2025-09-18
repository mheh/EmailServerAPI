//
//  EmailServerAPI.swift
//  email-server-api
//
//  Created by Milo Hehmsoth on 9/17/25.
//

extension Components.Parameters.SMTPProvider {
    public var host: String {
        switch self {
        case .googleSmtp: "smtp.gmail.com"
        case .googleSmtpRelay: "smtp-relay.gmail.com"
        case .yahoo: "smtp.mail.yahoo.com"
        }
    }
    
    public var port: Int { 465 }
}

// MARK: Google
/*
 https://support.google.com/a/answer/176600?hl=en
 
 Option 1: Send email with SMTP relay (recommended)

 We recommend using the SMTP relay service to send email from devices or apps. The SMTP relay service authenticates messages with IP addresses, so devices and apps can send messages to anyone inside or outside of your organization. This option is the most secure.
 Considerations

 When using the SMTP relay service:

     Each user in your organization can relay messages up to 10,000 recipients per day. Learn more about sending limits for the SMTP relay service.
     Suspicious messages might be filtered or rejected.
     The fully qualified domain name of the SMTP service is smtp-relay.gmail.com.
     Configuration options include:
         Port 25, 465, or 587
         SSL and TLS protocols
         Dynamic IP addresses (authentication might require a static IP address)

 Setup steps

     Set up SMTP relay in Google Workspace by following the steps in Route outgoing SMTP relay messages through Google.
     Set up your devices and apps to connect to the SMTP service smtp-relay.gmail.com on one of these ports: 25, 465, or 587.

 
 Option 2: Send email with the Gmail SMTP server

 If you connect using SSL or TLS, you can send email to anyone inside or outside of your organization using smtp.gmail.com as your SMTP server. This option requires you to authenticate with your Gmail or Google Workspace account and password when you set it up. The device uses those credentials every time it attempts to send email.
 Considerations

 When using the Gmail SMTP server:

     The sending limit is 2,000 messages per day. Learn more about email sending limits.
     Spam filters might reject or filter suspicious messages.
     The fully qualified domain name of the SMTP service is smtp.gmail.com.
     Configuration options include:
         Port 25, 465, or 587
         SSL and TLS protocols
         Dynamic IP addresses

 Setup steps

     On the device or in the app, for server address, enter smtp.gmail.com.
     For Port, enter one of the following numbers:
         For SSL, enter 465.
         For TLS, enter 587.

 
 Option 3: Send email with the restricted Gmail SMTP server

 This option lets your organization send messages to Gmail or Google Workspace users only. This option doesn't require authentication.

 If your device or app doesn't support SSL, you must use the restricted SMTP server aspmx.l.google.com.
 Considerations

 When using the restricted Gmail SMTP server:

     Verify the IP address of your device or app.
     Google Workspace per-user limits apply.
     Spam filters might reject or filter suspicious messages.
     The fully qualified domain name of the SMTP service is aspmx.l.google.com.
     TLS and authentication aren't required.
     Configuration options include:
         Port 25
         Dynamic IP addresses

 Setup steps

     Connect your device or app to the restricted Gmail SMTP server:
         For the server address, enter aspmx.l.google.com.
         For the port, enter 25.
     In your Google Admin console, add the device or app IP address to the allowlist by following the steps in Add IP addresses to allowlists in Gmail.
     Set up SPF for your domain. Make sure your SPF record includes the IP address or domain for the device or app that's sending messages from your domain so messages from these devices aren't rejected. Your SPF record must reference all senders for your domain. For details, go to Set up SPF.
 */

// MARK: - Yahoo
/*
 https://help.yahoo.com/kb/SLN4075.html
 
 Outgoing Mail (SMTP) Server

     Server - smtp.mail.yahoo.com
     Port - 465 or 587
     Requires SSL - Yes
     Requires authentication - Yes
 
 Your login info

     Email address - Your full email address (name@domain.com)
     Password - Generate App Password
     Requires authentication - Yes
 */
