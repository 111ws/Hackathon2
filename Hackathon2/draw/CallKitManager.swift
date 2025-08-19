//
//  CallKitManager.swift
//  Hackathon2
//
//  Created by 陆氏干饭王 on 03-08-2025.
//


//
//  contentViewHandle.swift
//  Hackathon
//
//  Created by 陆氏干饭王 on 02-08-2025.
//
import SwiftUI
import AVFoundation
import CallKit
import PushKit



// CallKit通话管理器
class CallKitManager: NSObject, CXProviderDelegate, PKPushRegistryDelegate {
    static let shared = CallKitManager()
    
    private var provider: CXProvider!
    private var callController: CXCallController!
    private var currentCallUUID: UUID?
    private var pushRegistry: PKPushRegistry?
    
    override init() {
        super.init()
        setupCallKit()
        setupPushKit()
    }
    
    private func setupCallKit() {
        let configuration = CXProviderConfiguration()
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportsVideo = false
        configuration.supportedHandleTypes = [.phoneNumber]
        // MARK: - Ringing configutation
        configuration.iconTemplateImageData = UIImage(systemName: "phone.fill")?.pngData()
        configuration.ringtoneSound = "Ringtone.caf"
        
        provider = CXProvider(configuration: configuration)
        provider.setDelegate(self, queue: nil)
        callController = CXCallController()
    }
    
    private func setupPushKit() {
        pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        pushRegistry?.delegate = self
        pushRegistry?.desiredPushTypes = [.voIP]
    }
    
    // MARK: - CXProviderDelegate
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
    
        // 立即配置音频会话
        configureAudioSession()
        action.fulfill()
        
        // 关键：立即通知应用切换到通话界面
        DispatchQueue.main.async {
            // 发送通知给ContentView，让它立即显示通话界面
            NotificationCenter.default.post(name: .callAnswered, object: nil)
            
            // 可选：如果需要，可以结束CallKit的系统通话界面
            // 让应用完全接管通话体验
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        // 用户挂断电话
        action.fulfill()
        currentCallUUID = nil
        
        // 通知ContentView更新状态
        NotificationCenter.default.post(name: .callEnded, object: nil)
    }
    
    func providerDidReset(_ provider: CXProvider) {
        currentCallUUID = nil
    }
    
    // MARK: - 来电处理
    func reportIncomingCall(from contact: String, delay: TimeInterval = 0) {
        // 检查是否已有活跃通话
        guard currentCallUUID == nil else {
            print("已有活跃通话，忽略新的来电请求")
            return
        }
        
        let uuid = UUID()
        currentCallUUID = uuid
        
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .emailAddress, value: contact)
        update.hasVideo = false
        update.localizedCallerName = contact
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.provider.reportNewIncomingCall(with: uuid, update: update) { error in
                if let error = error {
                    print("报告来电失败: \(error)")
                } else {
                    print("Successfully reported incoming call")
                }
            }
        }
    }
    
    func endCall() {
        guard let callUUID = currentCallUUID else { return }
        
        let endCallAction = CXEndCallAction(call: callUUID)
        let transaction = CXTransaction(action: endCallAction)
        
        callController.request(transaction) { error in
            if let error = error {
                print("结束通话失败: \(error)")
            } else {
                print("成功结束通话")
            }
        }
    }
    
    // MARK: - 音频配置
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Audio session configuration failed: \(error)")
        }
    }
    
    // MARK: - PKPushRegistryDelegate
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        // 处理VoIP推送凭据
        let deviceToken = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        print("VoIP push token: \(deviceToken)")
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        // 检查是否已有活跃通话
        if currentCallUUID == nil {
            // 只有在没有活跃通话时才报告新来电
            reportIncomingCall(from: "未知联系人")
        }
        completion()
    }
}

// 通知扩展
extension Notification.Name {
    static let callAnswered = Notification.Name("callAnswered")
    static let callEnded = Notification.Name("callEnded")
}

// 通话管理器（整合CallKit）
class CallManager: ObservableObject {
    @Published var callState: CallState = .idle
    @Published var callDuration: TimeInterval = 0
    @Published var contactName: String = "Aura"
    
    private var timer: Timer?
    private let callKitManager = CallKitManager.shared
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleCallAnswered), name: .callAnswered, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleCallEnded), name: .callEnded, object: nil)
    }
    
    // 在 CallManager 中修改接听方法
    @objc private func handleCallAnswered() {
        DispatchQueue.main.async {
            // 立即切换到已连接状态，显示应用内通话界面
            self.callState = .connected
            self.startTimer()
            
            // 确保应用在前台显示
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.windows.first?.makeKeyAndVisible()
            }
        }
    }
    
    // 修改 startCall 方法，移除接听延迟
    func startCall() {
        contactName = "Aura"
        // 直接报告来电，不设置延迟
        callKitManager.reportIncomingCall(from: contactName)
    }
    
    func answerCall() {
        // CallKit会自动处理接听
    }
    
    func endCall() {
        callKitManager.endCall()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.callDuration += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // 在 CallManager 类中添加 handleCallEnded 方法
    @objc private func handleCallEnded() {
        DispatchQueue.main.async {
            self.callState = .ended
            self.stopTimer()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.callState = .idle
                self.callDuration = 0
            }
        }
    }
}
