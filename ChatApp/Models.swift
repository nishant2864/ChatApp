import Foundation
import SwiftUI

struct Message: Identifiable, Codable {
    var id = UUID()
    let text: String
    let isFromMe: Bool
    let timestamp: Date
    var attachmentData: Data?
    
    var isImage: Bool {
        return attachmentData != nil
    }
}

struct Contact: Identifiable, Codable {
    var id = UUID()
    let name: String
    let avatarName: String
    var messages: [Message]
    
    var lastMessage: String {
        messages.last?.text ?? "No messages yet"
    }
    
    var lastMessageTime: String {
        guard let last = messages.last else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: last.timestamp)
    }
}
