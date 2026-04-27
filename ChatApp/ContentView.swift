import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ChatViewModel()
    @State private var showingAddContact = false
    @State private var newContactName = ""
    @State private var searchText = ""
    
    var body: some View {
            NavigationStack {
                ZStack(alignment: .bottom) {
                    List {
                        ForEach(filteredContacts) { contact in
                            NavigationLink(destination: ChatDetailView(contact: contact, viewModel: viewModel)) {
                                ContactRow(contact: contact)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 8))
                            .listRowSeparator(.hidden) // Remove dividers
                        }
                    }
                    .listStyle(.plain)
                    .navigationTitle("Chats")
                    
                    VStack(spacing: 0) {
                        // Floating Action Button
                        HStack {
                            Spacer()
                            Button(action: { 
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                showingAddContact = true 
                            }) {
                                Image(systemName: "plus")
                                    .font(.title2.bold())
                                    .padding()
                                    .background(Color.blue.opacity(0.7))
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 10)
                        }
                        
                        // Bottom Search Bar
                        HStack {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                TextField("Search", text: $searchText)
                            }
                            .padding(10)
                            .background(Color(uiColor: .systemGray6))
                            .cornerRadius(50)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
                .alert("New Chat", isPresented: $showingAddContact) {
                    TextField("Contact Name", text: $newContactName)
                    Button("Create", action: {
                        if !newContactName.isEmpty {
                            viewModel.addContact(name: newContactName)
                            newContactName = ""
                        }
                    })
                    Button("Cancel", role: .cancel) { }
                }
            }
    }
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return viewModel.contacts
        } else {
            return viewModel.contacts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

#Preview {
    ContentView()
}
