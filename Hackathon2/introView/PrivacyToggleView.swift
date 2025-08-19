import SwiftUI

struct PrivacyToggleView: View {
    @State private var shareConversation = true
    @State private var navigateToContentView = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack {
                Text("Helps us build a more perceptive\nAI by sharing your conversations\nwith us.")
                    .foregroundColor(WarmTheme.primaryText)
                    .font(.body)
                Spacer()
                Toggle("", isOn: $shareConversation)
                    .labelsHidden()
                    .tint(WarmTheme.accent)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("You will remain anonymous.")
                Text("Your conversations will be used to help Aura")
                Text("Help make Aura more empathetic to other users.")
            }
            .foregroundColor(WarmTheme.secondaryText)
            .font(.body)
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                navigateToContentView = true
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(WarmTheme.accent)
                    .cornerRadius(16)
                    .shadow(color: WarmTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
            .navigationDestination(isPresented: $navigateToContentView) { ContentView() }
            .navigationBarBackButtonHidden(true)
        }
        .background(Color.white)
    }
}

struct PrivacyToggleView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyToggleView()
    }
}
