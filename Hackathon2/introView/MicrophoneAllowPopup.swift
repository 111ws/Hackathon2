import SwiftUI

struct MicrophoneAllowPopup: View {
    @Binding var isPresented: Bool
    var onAllow: (() -> Void)? = nil
    var onDeny: (() -> Void)? = nil

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 标题
                    Text("Microphone Access")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 18)
                        .padding(.horizontal, 16)

                    // 说明
                    Text("“Aura” would like to access the microphone.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                    // 顶部分割线
                    Divider()
                        .background(Color(UIColor.separator))

                    // 按钮区（左右排布 + 中间分割线）
                    HStack(spacing: 0) {
                        Button(action: {
                            isPresented = false
                            onDeny?()
                        }) {
                            Text("Don't Allow")
                                .font(.system(size: 17, weight: .regular))
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(Color(UIColor.systemBlue))

                        Rectangle()
                            .fill(Color(UIColor.separator))
                            .frame(width: 0.5, height: 44)
                            .accessibilityHidden(true)

                        Button(action: {
                            isPresented = false
                            onAllow?()
                        }) {
                            Text("Allow")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(Color(UIColor.systemBlue))
                    }
                }
                .frame(minWidth: 270)
                .background(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 20, y: 6)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.32, dampingFraction: 0.85), value: isPresented)
            }
        }
    }
}
