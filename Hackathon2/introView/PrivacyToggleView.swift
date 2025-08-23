import SwiftUI
import HealthKit

struct PrivacyToggleView: View {
    @State private var shareConversation = true
    @State private var navigateToContentView = false
    @State private var showHealthPermissionAlert = false
    
    private let healthStore = HKHealthStore()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: UIScreen.main.bounds.height * 0.07)
            
            // 标题部分
            Text("Our commitment to you")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(WarmTheme.primaryText)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            Text("Your mental health is personal and private.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(WarmTheme.secondaryText)
                .padding(.horizontal)
                .padding(.bottom, 32)
            
            // 灰色背景卡片
            VStack(alignment: .leading, spacing: 24) {
                // 标题和开关
                VStack(alignment: .leading, spacing: 16) {
                    Text("Help us improve your experience by sharing your conversations")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(WarmTheme.primaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Toggle("", isOn: $shareConversation)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: Color(red: 260/255, green: 184/255, blue: 142/255)))
                }
                .padding(.bottom, 8)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // 隐私说明列表
                VStack(alignment: .leading, spacing: 16) {
                    PrivacyItem(text: "You will remain anonymous.")
                    PrivacyItem(text: "Your conversations will be used to help make Ash better for everyone.")
                    PrivacyItem(text: "Your conversation data will be used to track down bugs, and improve the way Ash communicates.")
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
            
            // 底部隐私政策文本
            HStack {
                Spacer()
                Text("By using this app, you agree to our ")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(WarmTheme.secondaryText) +
                Text("Privacy Policy")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(WarmTheme.primaryText)
                Spacer()
            }
            .padding(.bottom, 16)
            
            // 继续按钮
            Button(action: {
                requestHealthPermission()
            }) {
                Text("Continue")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white.opacity(1))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(
                                            RoundedRectangle(cornerRadius: 25)
                                                .fill(Color(red: 260/255, green: 184/255, blue: 142/255))
                                        )
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
            .navigationDestination(isPresented: $navigateToContentView) { /*ContentView()*/ HomeCalendarQuickView() }
            .navigationBarBackButtonHidden(true)
        }
        .background(
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)
        )
        .alert("Health Access", isPresented: $showHealthPermissionAlert) {
            Button("Don't Allow") {
                navigateToContentView = true
            }
            Button("Allow") {
                //requestHealthKitPermission()
                navigateToContentView = true
            }
        }
        message: {
            Text("\"Aura\" would like to access and update your Health data.")
        }
    }
    
    private func requestHealthPermission() {
        if HKHealthStore.isHealthDataAvailable() {
            showHealthPermissionAlert = true
        } else {
            navigateToContentView = true
        }
    }
    
    private func requestHealthKitPermission() {
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!,
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.quantityType(forIdentifier: .cyclingPower)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
            HKObjectType.quantityType(forIdentifier: .runningPower)!,
            HKObjectType.quantityType(forIdentifier: .runningStrideLength)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.workoutType()
        ]
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!,
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.quantityType(forIdentifier: .cyclingPower)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
            HKObjectType.quantityType(forIdentifier: .runningPower)!,
            HKObjectType.quantityType(forIdentifier: .runningStrideLength)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                navigateToContentView = true
            }
        }
    }
}

// 隐私项组件
struct PrivacyItem: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle")
                .foregroundColor(Color.gray)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(WarmTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct PrivacyToggleView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyToggleView()
    }
}
