import SwiftUI

struct VoiceOption: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let isSelected: Bool
}

struct VoiceSelectionView: View {
    @State private var options: [VoiceOption] = [
        VoiceOption(name: "Juniper", description: "", isSelected: false),
        VoiceOption(name: "Breeze", description: "", isSelected: true),
        VoiceOption(name: "Cove", description: "", isSelected: false),
        VoiceOption(name: "Sky", description: "", isSelected: false),
        VoiceOption(name: "Ember", description: "", isSelected: false)
    ]
    @State private var selectedIndex: Int = 1
    @State private var navigateToPrivacy = false
    @State private var showMicrophoneAlert = false
    
    // Unified spacing so headers align with the start of card content
    private let outerPadding: CGFloat = 40
    private let cardInnerPadding: CGFloat = 16
    // Stretch buttons vertically by ~20%
    private let optionVerticalPadding: CGFloat = 20 // was 12
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()
                // 标题和副标题
                Circle()
                    .fill(Color.clear)
                    .frame(width: 150, height: 150)
                    .overlay(
                        AdvancedGradientRippleAnimation(
                            color: Color.white,
                            maxSize: 180,
                            centerColor: Color.white,
                            edgeColor: .clear
                        )

                        // .frame(width: 150, height:150)
                        
                    )
                .padding(.horizontal)
                .padding(.bottom, 32)
                Spacer()
                // 语音选项卡
                ForEach(options.indices, id: \.self) { idx in
                    Button(action: {
                        selectedIndex = idx
                    }) {
                        HStack {
                            Text(options[idx].name)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.35), radius: 1.5, x: 0, y: 1)
                            Spacer()
                            if selectedIndex == idx {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .bold))
                                    .shadow(color: .black.opacity(0.35), radius: 1.5, x: 0, y: 1)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.black.opacity(0.16)) // 更透明且偏暗，提升白字对比
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.22), lineWidth: 1) // 保持轮廓
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                
                Spacer(minLength: 0)
                Button(action: {
                    // 显示麦克风权限弹窗
                    showMicrophoneAlert = true
                }) {
                    Text("Confirm")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(.white.opacity(0.5))
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                
                .navigationDestination(isPresented: $navigateToPrivacy) { AView() }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 1.0, green: 0.72, blue: 0.50),
                        Color(red: 0.84, green: 0.71, blue: 0.62),
                        Color(red: 1.0, green: 0.76, blue: 0.58)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .alert("Microphone Access", isPresented: $showMicrophoneAlert) {
                Button("Don't Allow") {
                    // 用户拒绝权限，可以选择是否继续或停留在当前页面
                    // 这里选择继续到下一页
                    navigateToPrivacy = true
                }
                Button("Allow") {
                    // 用户允许权限，继续到下一页
                    // 这里可以添加实际的麦克风权限请求代码
                    requestMicrophonePermission()
                    navigateToPrivacy = true
                }
            } message: {
                Text("\"Aura\" would like to access the microphone.")
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    private func requestMicrophonePermission() {
        // 这里可以添加实际的麦克风权限请求逻辑
        // 例如使用 AVAudioSession.sharedInstance().requestRecordPermission
    }
}
    

struct VoiceSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceSelectionView()
    }
}
