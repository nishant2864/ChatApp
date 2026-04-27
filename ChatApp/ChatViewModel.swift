import Foundation
import SwiftUI
import Combine

class ChatViewModel: ObservableObject {
    @Published var contacts: [Contact] = [] {
        didSet {
            saveContacts()
        }
    }
    
    init() {
        loadContacts()
        if contacts.isEmpty {
            createMockData()
        }
    }
    
    private func saveContacts() {
        if let encoded = try? JSONEncoder().encode(contacts) {
            UserDefaults.standard.set(encoded, forKey: "chat_contacts")
        }
    }
    
    private func loadContacts() {
        if let data = UserDefaults.standard.data(forKey: "chat_contacts"),
           let decoded = try? JSONDecoder().decode([Contact].self, from: data) {
            self.contacts = decoded
        }
    }
    
    func sendMessage(to contactId: UUID, text: String, attachment: Data? = nil) {
        if let index = contacts.firstIndex(where: { $0.id == contactId }) {
            let newMessage = Message(text: text, isFromMe: true, timestamp: Date(), attachmentData: attachment)
            contacts[index].messages.append(newMessage)
            
            // Simulate receiving a reply
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                let reply = Message(text: "Got it! Thanks for the update.", isFromMe: false, timestamp: Date())
                self.contacts[index].messages.append(reply)
            }
        }
    }
    
    func addContact(name: String) {
        let newContact = Contact(name: name, avatarName: "person.circle.fill", messages: [])
        contacts.insert(newContact, at: 0)
    }
    
    private func createMockData() {
        contacts = [
            Contact(name: "Elon Musk", avatarName: "rocket", messages: [
                Message(text: "Let's build a colony on Mars!", isFromMe: false, timestamp: Date().addingTimeInterval(-86400)),
                Message(text: "Sure, let me check my schedule.", isFromMe: true, timestamp: Date().addingTimeInterval(-86000))
            ]),
            Contact(name: "Bill Gates", avatarName: "laptopcomputer", messages: [
                Message(text: "The new Windows is looking great.", isFromMe: false, timestamp: Date().addingTimeInterval(-3600))
            ]),
            Contact(name: "Design Team", avatarName: "paintbrush.fill", messages: [
                Message(text: "Attached the new UI mockups.", isFromMe: false, timestamp: Date().addingTimeInterval(-1800))
            ])
        ]
    }
}
