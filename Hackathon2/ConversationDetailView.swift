import SwiftUI

struct ConversationDetailView: View {
    let conversation: Conversation
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(conversation.title)
                        .font(.title3).bold()
                        .foregroundColor(.white)
                    HStack(spacing: 8) {
                        ForEach(conversation.tags.prefix(6), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.white.opacity(0.12)))
                        }
                    }
                    .padding(.bottom, 4)
                    ForEach(conversation.messages.sorted(by: { $0.timestamp < $1.timestamp }), id: \.timestamp) { msg in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(DateFormatter.HHmm.string(from: msg.timestamp))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                            Text((msg.role.lowercased() == "user" ? "Me: " : "Aura: ") + msg.content)
                                .font(.body)
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                        Divider().background(Color.white.opacity(0.08))
                    }
                }
                .padding(16)
            }
            .background(Color.black.opacity(0.95).ignoresSafeArea())
            .navigationTitle(conversation.startTime.formatted(.dateTime.year().month().day()))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .presentationBackground(.thinMaterial)
    }
}

#Preview {
    let sample = ConversationStore.shared.conversations.first ?? Conversation(
        id: "preview",
        title: "Sample",
        tags: ["#tag"],
        startTime: Date(),
        endTime: Date(),
        messages: [Message(timestamp: Date(), role: "assistant", content: "Hello")]
    )
    return ConversationDetailView(conversation: sample)
}


