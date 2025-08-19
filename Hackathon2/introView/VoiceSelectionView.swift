import SwiftUI

struct VoiceOption: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let isSelected: Bool
}

struct VoiceSelectionView: View {
    @State private var options: [VoiceOption] = [
        VoiceOption(name: "Voice 1", description: "Warm and friendly", isSelected: true),
        VoiceOption(name: "Voice 2", description: "Calm and professional", isSelected: false),
        VoiceOption(name: "Voice 3", description: "Energetic and lively", isSelected: false)
    ]
    @State private var selectedIndex: Int = 0
    @State private var navigateToPrivacy = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()
                // 标题和副标题
                VStack(alignment: .leading, spacing: 8) {
                    Text("Which voice do you prefer?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(WarmTheme.accentText)
                    Text("You can always change this in the settings.")
                        .font(.subheadline)
                        .foregroundColor(WarmTheme.secondaryText)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
                
                // 语音选项卡
                ForEach(options.indices, id: \.self) { idx in
                    Button(action: {
                        selectedIndex = idx
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(options[idx].name)
                                    .font(.headline)
                                    .foregroundColor(selectedIndex == idx ? WarmTheme.cream : WarmTheme.primaryText)
                                Text(options[idx].description)
                                    .font(.caption)
                                    .foregroundColor(selectedIndex == idx ? WarmTheme.cream.opacity(0.9) : WarmTheme.secondaryText)
                            }
                            Spacer()
                            Image(systemName: selectedIndex == idx ? "play.circle.fill" : "play.circle")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(selectedIndex == idx ? WarmTheme.cream : WarmTheme.accent)
                        }
                        .padding()
                        .background(selectedIndex == idx ? WarmTheme.accent : WarmTheme.cardBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedIndex == idx ? Color.clear : WarmTheme.border, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                
                Spacer()
                Button(action: {
                    navigateToPrivacy = true
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(WarmTheme.cream)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(WarmTheme.accent)
                        .cornerRadius(16)
                        .shadow(color: WarmTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
                .navigationDestination(isPresented: $navigateToPrivacy) { PrivacyToggleView() }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [WarmTheme.primaryBackground, WarmTheme.secondaryBackground]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
            )
        }
    }
}


struct VoiceSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceSelectionView()
    }
}
