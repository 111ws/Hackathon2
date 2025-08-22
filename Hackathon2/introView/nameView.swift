import SwiftUI

struct NameView: View {
    @State private var name: String = ""
    @State private var navigateToNext = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 线性渐变背景
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
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // 标题
                    Text("What's your name?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 60)
                    
                    // 输入框
                    TextField("Name", text: $name)
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.9))
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    
                    Spacer()
                    
                    // 继续按钮
                    Button(action: {
                        if !name.isEmpty {
                            navigateToNext = true
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(Color.white)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .disabled(name.isEmpty)
                    .opacity(name.isEmpty ? 0.5 : 1.0)
                    .padding(.bottom, 50)
                }
            }
            .navigationDestination(isPresented: $navigateToNext) {
                PrivacyToggleView()
            }
        }
        .navigationBarBackButtonHidden()
    }
}

struct NameView_Previews: PreviewProvider {
    static var previews: some View {
        NameView()
    }
}

