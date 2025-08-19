import SwiftUI

struct VoiceOption: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let isSelected: Bool
}

struct VoiceSelectionView: View {
    @State private var options: [VoiceOption] = [
        VoiceOption(name: "Voice 1", description: "Warm and friendly", isSelected: false),
        VoiceOption(name: "Voice 2", description: "Calm and professional", isSelected: false),
        VoiceOption(name: "Voice 3", description: "Energetic and lively", isSelected: false)
    ]
    @State private var selectedIndex: Int = -1
    @State private var navigateToPrivacy = false
    
    // Unified spacing so headers align with the start of card content
    private let outerPadding: CGFloat = 40
    private let cardInnerPadding: CGFloat = 16
    // Stretch buttons vertically by ~20%
    private let optionVerticalPadding: CGFloat = 20 // was 12
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 标题和副标题（上移并保持左对齐）
                VStack(alignment: .leading, spacing: 8) {
                    Text("Which voice do you prefer?")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(WarmTheme.accentText)
                        .padding(.bottom, 6.0)
                    Text("You can always change this in the settings.")
                        .font(.subheadline)
                        .foregroundColor(WarmTheme.secondaryText)
                }
                .padding(.leading, 20)
                .padding(.trailing, outerPadding)
                .padding(.top, 22.0)
                .padding(.bottom, 37.0)
                
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
                                    .padding(.bottom, 2.0)
                                Text(options[idx].description)
                                    .font(.caption)
                                    .foregroundColor(selectedIndex == idx ? WarmTheme.cream.opacity(0.9) : WarmTheme.secondaryText)
                            }
                            Spacer()
                            Image(systemName: selectedIndex == idx ? "play.circle.fill" : "play.circle")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(selectedIndex == idx ? WarmTheme.cream : WarmTheme.accent)
                        }
                        .padding(.vertical, optionVerticalPadding)
                        .padding(.horizontal, cardInnerPadding)
                        .background(selectedIndex == idx ? WarmTheme.accent : WarmTheme.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedIndex == idx ? Color.clear : WarmTheme.border, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, outerPadding)
                    .padding(.bottom, 10)
                }
                
                Spacer(minLength: 0)
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
                .padding(.horizontal, outerPadding)
                .padding(.bottom, 16)
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
