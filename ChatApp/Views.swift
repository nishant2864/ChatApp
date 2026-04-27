import SwiftUI
import PhotosUI

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: 4) {
            HStack {
                if message.isFromMe { Spacer() }
                
                VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: 4) {
                    if let data = message.attachmentData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 250)
                            .cornerRadius(18)
                            .padding(2)
                    }
                    
                    if !message.text.isEmpty {
                        Text(message.text)
                            .font(.system(size: 16))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(message.isFromMe ? Color.blue : Color(uiColor: .systemGray6))
                            .foregroundColor(message.isFromMe ? .white : .primary)
                            .clipShape(BubbleShape(isMe: message.isFromMe))
                    }
                }
                
                if !message.isFromMe { Spacer() }
            }
            
            HStack {
                if message.isFromMe { Spacer() }
                Text(message.timestamp, style: .time)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                if !message.isFromMe { Spacer() }
            }
        }
        .padding(.horizontal, 8)
    }
}

struct BubbleShape: Shape {
    let isMe: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, 
                               byRoundingCorners: [.topLeft, .topRight, isMe ? .bottomLeft : .bottomRight], 
                               cornerRadii: CGSize(width: 18, height: 18))
        return Path(path.cgPath)
    }
}

struct ContactRow: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: contact.name, systemName: contact.avatarName)
                .frame(width: 54, height: 54)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contact.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(contact.lastMessageTime)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Text(contact.lastMessage)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AvatarView: View {
    let name: String
    let systemName: String
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            
           
                Text(String(name.prefix(1)).uppercased())
                    .font(.title3.bold())
                    .foregroundColor(.white)
        }
        .clipShape(Circle())
    }
}

struct ChatDetailView: View {
    let contact: Contact
    @ObservedObject var viewModel: ChatViewModel
    @State private var messageText = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(contact.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
                .onChange(of: contact.messages.count) {
                    scrollToBottom(proxy: proxy)
                }
                .onAppear {
                    scrollToBottom(proxy: proxy, animated: false)
                }
            }
            
            // Attachment Preview
            if let data = selectedImageData, let uiImage = UIImage(data: data) {
                HStack {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .cornerRadius(12)
                        
                        Button(action: { selectedImageData = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .gray)
                                .font(.title3)
                        }
                        .offset(x: 5, y: -5)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Input Bar
            HStack(alignment: .bottom, spacing: 12) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            withAnimation {
                                selectedImageData = data
                            }
                        }
                    }
                }
                
                TextField("Message", text: $messageText, axis: .vertical)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(20)
                    .lineLimit(1...5)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(canSend ? .blue : .secondary.opacity(0.5))
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    AvatarView(name: contact.name, systemName: contact.avatarName)
                        .frame(width: 32, height: 32)
                    Text(contact.name)
                        .font(.headline)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 15) {
                    Image(systemName: "video")
                    Image(systemName: "phone")
                }
                .foregroundColor(.black)
            }
        }
        .background(Color(uiColor: .systemBackground))
    }
    
    var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImageData != nil
    }
    
    func sendMessage() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        viewModel.sendMessage(to: contact.id, text: messageText, attachment: selectedImageData)
        withAnimation {
            messageText = ""
            selectedImageData = nil
            selectedItem = nil
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        if let lastId = contact.messages.last?.id {
            if animated {
                withAnimation {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}
