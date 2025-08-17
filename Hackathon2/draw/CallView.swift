////
////  CallView.swift
////  Hackathon2
////
////  Created by 陆氏干饭王 on 03-08-2025.
////
//
//import SwiftUI
//import CallKit
//import PushKit
//import Speech
//import AVFoundation
//
//struct CallView: View {
//    @ObservedObject var callManager: CallManager
//    @State   var isVideoEnabled = true
//    @State   var isFrontCamera = true
//    
//    // 现有的语音捕获相关状态 - 改为internal访问级别
//    @State var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
//    @State var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
//    @State var recognitionTask: SFSpeechRecognitionTask?
//    @State var audioEngine = AVAudioEngine()
//    @State var currentSpeechText = ""
//    @State var speechHistory: [String] = []
//    @State var isSpeaking = false
//    @State var speechTimer: Timer?
//    @State var isMuted = false
//    
//    // 需要添加的新属性（从StandaloneCallView移植）- 改为internal访问级别
//    @State var previousTranscription: String = ""
//    @State var audioPlayer: AVAudioPlayer?
//    @State var isPlayingResponse = false
//    @State var debugMessages: [String] = []
//    @State var showDebugLog = false
//    @State var audioDownloadProgress: Float = 0.0
//    @State var currentAudioDuration: TimeInterval = 0
//    @State var audioPlaybackProgress: Float = 0.0
//    @State var playbackTimer: Timer?
//    
//    // 用户ID常量 - 改为internal访问级别
//    let userId = "user_001"
//    
//    var body: some View {
//        ZStack {
//            // 背景
//            if callManager.callState == .connected && isVideoEnabled {
//                // 视频通话背景
//                remoteView()
//                    .ignoresSafeArea()
//            } else {
//                // 音频通话背景
//                LinearGradient(
//                    gradient: Gradient(colors: [
//                        Color(red: 0.98, green: 0.75, blue: 0.65),
//                        Color(red: 0.99, green: 0.85, blue: 0.55)
//                    ]),
//                    startPoint: .topLeading,
//                    endPoint: .bottomTrailing
//                )
//                .ignoresSafeArea()
//            }
//            
//            VStack(spacing: 40) {
//                Spacer()
//                
//                if callManager.callState != .connected || !isVideoEnabled {
//                    // 联系人头像和动画
//                    Circle()
//                        .fill(Color.clear)
//                        .frame(width: 150, height: 150)
//                        .overlay(
//                            AdvancedGradientRippleAnimation(
//                                color: isSpeaking ? .green : .white,
//                                maxSize: isSpeaking ? 200 : 180,
//                                centerColor: isSpeaking ? Color.green : Color.white,
//                                edgeColor: .clear
//                            )
//                            .frame(width: 300, height: 300)
//                            .animation(.easeInOut(duration: 0.3), value: isSpeaking)
//                        )
//                }
//                
//                // 联系人姓名
//                Text(callManager.contactName)
//                    .font(.largeTitle)
//                    .fontWeight(.medium)
//                    .foregroundColor(.white)
//                    .shadow(color: .black.opacity(0.5), radius: 2)
//                
//                // 通话状态文本
//                Text(statusText)
//                    .font(.title3)
//                    .foregroundColor(.white.opacity(0.8))
//                    .shadow(color: .black.opacity(0.5), radius: 2)
//                
//                // 实时语音显示
//                if callManager.callState == .connected && !currentSpeechText.isEmpty {
//                    VStack(spacing: 8) {
//                        Text("你正在说：")
//                            .font(.caption)
//                            .foregroundColor(.white.opacity(0.7))
//                        
//                        Text(currentSpeechText)
//                            .font(.body)
//                            .foregroundColor(.white)
//                            .padding(12)
//                            .background(Color.black.opacity(0.3))
//                            .cornerRadius(8)
//                            .transition(.opacity)
//                    }
//                    .animation(.easeInOut, value: currentSpeechText)
//                }
//                
//                Spacer()
//                
//                // 通话控制按钮
//                HStack(spacing: 40) {
//                    if callManager.callState == .ringing {
//                        // 接听按钮
//                        Button(action: {
//                            callManager.answerCall()
//                        }) {
//                            Circle()
//                                .fill(Color.green)
//                                .frame(width: 70, height: 70)
//                                .overlay(
//                                    Image(systemName: "phone.fill")
//                                        .font(.system(size: 30))
//                                        .foregroundColor(.white)
//                                )
//                        }
//                    }
//                    
//                    if callManager.callState == .connected {
//                        
//                        // 视频开关按钮
//                        Button(action: {
//                            isVideoEnabled.toggle()
//                        }) {
//                            Circle()
//                                .fill(isVideoEnabled ? Color.blue : Color.gray.opacity(0.3))
//                                .frame(width: 65, height: 65)
//                                .overlay(
//                                    Image(systemName: isVideoEnabled ? "video.fill" : "video.slash.fill")
//                                        .font(.system(size: 24))
//                                        .foregroundColor(.white)
//                                )
//                        }
//                        
//                        // 摄像头切换按钮（仅在视频开启时显示）
//                        if isVideoEnabled {
//                            Button(action: {
//                                isFrontCamera.toggle()
//                            }) {
//                                Circle()
//                                    .fill(Color.gray.opacity(0.3))
//                                    .frame(width: 65, height: 65)
//                                    .overlay(
//                                        Image(systemName: "camera.rotate.fill")
//                                            .font(.system(size: 24))
//                                            .foregroundColor(.white)
//                                    )
//                            }
//                        }
//                        
//                        // 扬声器按钮
//                        Button(action: {
//                            // 扬声器功能实现
//                        }) {
//                            Circle()
//                                .fill(Color.gray.opacity(0.3))
//                                .frame(width: 65, height: 65)
//                                .overlay(
//                                    Image(systemName: "speaker.wave.2.fill")
//                                        .font(.system(size: 24))
//                                        .foregroundColor(.white)
//                                )
//                        }
//                    }
//                    
//                    // 挂断按钮
//                    Button(action: {
//                        callManager.endCall()
//                    }) {
//                        Circle()
//                            .fill(Color.red)
//                            .frame(width: 70, height: 70)
//                            .overlay(
//                                Image(systemName: "phone.down.fill")
//                                    .font(.system(size: 30))
//                                    .foregroundColor(.white)
//                            )
//                    }
//                }
//                .padding(.bottom, 50)
//            }
//            .padding()
//            
//            // 语音历史记录（可选显示）
//            if callManager.callState == .connected && !speechHistory.isEmpty {
//                VStack {
//                    HStack {
//                        Spacer()
//                        Button(action: {
//                            // 显示语音历史
//                        }) {
//                            Image(systemName: "text.bubble")
//                                .foregroundColor(.white.opacity(0.7))
//                                .padding(8)
//                                .background(Color.black.opacity(0.3))
//                                .cornerRadius(8)
//                        }
//                    }
//                    .padding(.horizontal, 20)
//                    .padding(.top, 60)
//                    Spacer()
//                }
//            }
//            
//            // 本地视频预览窗口
//            if callManager.callState == .connected && isVideoEnabled {
//                HStack {
//                    SimpleCameraView()
//                        .frame(width: 120, height: 160)
//                        .background(Color.black.opacity(0.1))
//                        .cornerRadius(12)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 12)
//                                .stroke(Color.white, lineWidth: 0.6)
//                        )
//                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
//                        .padding(.horizontal,-190)
//                        .padding(.top, -330)
//                }
//                .zIndex(1000) // 确保小窗口在最上层
//            }
//        }
//        .onAppear {
//            requestSpeechAuthorization()
//        }
//        .onChange(of: callManager.callState) { newState in
//            handleCallStateChange(newState)
//        }
//    }
//    
//    // 处理通话状态变化
//      func handleCallStateChange(_ newState: CallState) {
//        print("📞 通话状态变化: \(callManager.callState) -> \(newState)")
//        switch newState {
//        case .connected:
//            print("✅ 通话已连接，准备启动语音识别")
//            // 延迟启动语音识别，确保CallKit通话完全建立
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                print("🎤 延迟启动语音识别")
//                self.startContinuousSpeechRecognition()
//            }
//        case .ended, .idle:
//            print("📞 通话结束，停止语音识别")
//            stopSpeechRecognition()
//        default:
//            print("📞 其他状态变化: \(newState)")
//            break
//        }
//    }
//    
//    // 请求语音识别权限
//      func requestSpeechAuthorization() {
//        print("🎤 开始请求语音识别权限")
//        SFSpeechRecognizer.requestAuthorization { authStatus in
//            DispatchQueue.main.async {
//                switch authStatus {
//                case .authorized:
//                    print("✅ 语音识别已授权")
//                case .denied:
//                    print("❌ 语音识别被拒绝")
//                case .restricted:
//                    print("⚠️ 语音识别受限")
//                case .notDetermined:
//                    print("❓ 语音识别权限未确定")
//                @unknown default:
//                    print("❓ 语音识别未知状态")
//                }
//            }
//        }
//    }
//    
//    // 开始持续语音识别
//      func startContinuousSpeechRecognition() {
//        print("🎤 准备开始持续语音识别")
//        print("🔍 检查条件 - isMuted: \(isMuted), speechRecognizer可用: \(speechRecognizer?.isAvailable ?? false), 授权状态: \(SFSpeechRecognizer.authorizationStatus().rawValue)")
//        
//        guard !isMuted,
//              speechRecognizer?.isAvailable == true,
//              SFSpeechRecognizer.authorizationStatus() == .authorized else {
//            print("❌ 语音识别启动条件不满足")
//            return
//         }
//        
//       // 停止之前的任务
//        print("🛑 停止之前的语音识别任务")
//        stopSpeechRecognition()
//        
//        // 配置音频会话
//        print("🔧 配置音频会话")
//        let audioSession = AVAudioSession.sharedInstance()
//        do {
//            // 先尝试停用当前会话
//            try audioSession.setActive(false)
//            print("🔧 音频会话已停用")
//            
//            
//            // 重新配置音频会话，使用更兼容CallKit的设置
//            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .mixWithOthers])
//            print("🔧 音频会话类别配置完成")
//            
//            // 延迟激活音频会话
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                do {
//                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//                    print("✅ 音频会话激活成功")
//                    
//                    // 在音频会话成功激活后继续配置音频引擎
//                    self.configureAudioEngine()
//                } catch {
//                    print("❌ 延迟音频会话激活失败: \(error.localizedDescription)")
//                    print("🔍 错误详情: \(error)")
//                }
//            }
//        } catch {
//            print("❌ 音频会话配置失败: \(error.localizedDescription)")
//            print("🔍 错误详情: \(error)")
//            return
//        }
//        
//        // 创建识别请求
//        print("📝 创建语音识别请求")
//        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
//        guard let recognitionRequest = recognitionRequest else {
//            print("❌ 无法创建语音识别请求")
//            return
//        }
//        
//        recognitionRequest.shouldReportPartialResults = true
//        recognitionRequest.requiresOnDeviceRecognition = false
//        print("✅ 语音识别请求配置完成")
//        
//        // 配置音频引擎
//        print("🎵 配置音频引擎")
//        let inputNode = audioEngine.inputNode
//        let recordingFormat = inputNode.outputFormat(forBus: 0)
//        print("📊 录音格式: \(recordingFormat)")
//        
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
//            recognitionRequest.append(buffer)
//        }
//        
//        audioEngine.prepare()
//        print("🔧 音频引擎准备完成")
//        
//        do {
//            try audioEngine.start()
//            print("✅ 音频引擎启动成功")
//        } catch {
//            print("❌ 音频引擎启动失败: \(error.localizedDescription)")
//            return
//        }
//        
//        // 开始识别
//        print("🚀 开始语音识别任务")
//        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
//            DispatchQueue.main.async {
//                if let result = result {
//                    let newText = result.bestTranscription.formattedString
//                    print("🗣️ 识别到语音: \"\(newText)\"")
//                    print("📊 识别状态 - isFinal: \(result.isFinal), confidence: \(result.bestTranscription.segments.last?.confidence ?? 0)")
//                    
//                    self.currentSpeechText = newText
//                    
//                    // 检测是否在说话
//                    self.isSpeaking = !newText.isEmpty
//                    print("🎤 说话状态: \(self.isSpeaking)")
//                    
//                    // 重置定时器
//                    self.speechTimer?.invalidate()
//                    print("⏰ 设置2秒延迟定时器")
//                    self.speechTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
//                        // 2秒没有新的语音输入，保存到历史并清空当前文本
//                        if !self.currentSpeechText.isEmpty {
//                            print("💾 保存语音到历史: \"\(self.currentSpeechText)\"")
//                            self.speechHistory.append(self.currentSpeechText)
//                            self.currentSpeechText = ""
//                            self.isSpeaking = false
//                            print("🔄 清空当前语音文本，停止说话状态")
//                        }
//                    }
//                    
//                    if result.isFinal {
//                        print("✅ 语音识别完成，准备重新开始")
//                        // 识别完成，重新开始
//                        self.restartSpeechRecognition()
//                    }
//                }
//                
//                if let error = error {
//                    print("❌ 语音识别错误: \(error.localizedDescription)")
//                    print("🔄 准备重新启动语音识别")
//                    self.restartSpeechRecognition()
//                }
//            }
//        }
//    }
//    // ... existing code ...
//    private func configureAudioEngine() {
//        print("🎵 开始配置音频引擎")
//        
//        // 创建识别请求
//        print("📝 创建语音识别请求")
//        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
//        guard let recognitionRequest = recognitionRequest else {
//            print("❌ 无法创建语音识别请求")
//            return
//        }
//        
//        recognitionRequest.shouldReportPartialResults = true
//        recognitionRequest.requiresOnDeviceRecognition = false
//        print("✅ 语音识别请求配置完成")
//        
//        // 配置音频引擎
//        let inputNode = audioEngine.inputNode
//        let recordingFormat = inputNode.outputFormat(forBus: 0)
//        print("📊 录音格式: \(recordingFormat)")
//        
//        // 移除之前的tap
//        inputNode.removeTap(onBus: 0)
//        
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
//            recognitionRequest.append(buffer)
//        }
//        
//        audioEngine.prepare()
//        print("🔧 音频引擎准备完成")
//        
//        do {
//            try audioEngine.start()
//            print("✅ 音频引擎启动成功")
//            
//            // 启动语音识别任务
//            // 启动语音识别任务
//            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
//                DispatchQueue.main.async {
//                    if let result = result {
//                        let newText = result.bestTranscription.formattedString
//                        print("🗣️ 识别到语音: \"\(newText)\"")
//                        print("📊 识别状态 - isFinal: \(result.isFinal), confidence: \(result.bestTranscription.segments.last?.confidence ?? 0)")
//                        
//                        self.currentSpeechText = newText
//                        
//                        // 检测是否在说话
//                        self.isSpeaking = !newText.isEmpty
//                        print("🎤 说话状态: \(self.isSpeaking)")
//                        
//                        // 重置定时器
//                        self.speechTimer?.invalidate()
//                        print("⏰ 设置2秒延迟定时器")
//                        self.speechTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
//                            if !self.currentSpeechText.isEmpty {
//                                print("💾 保存语音到历史: \"\(self.currentSpeechText)\"")
//                                self.speechHistory.append(self.currentSpeechText)
//                                self.currentSpeechText = ""
//                                self.isSpeaking = false
//                                print("🔄 清空当前语音文本，停止说话状态")
//                            }
//                        }
//                        
//                        if result.isFinal {
//                            print("✅ 语音识别完成，准备重新开始")
//                            self.restartSpeechRecognition()
//                        }
//                    }
//                    
//                    if let error = error {
//                        print("❌ 语音识别错误: \(error.localizedDescription)")
//                        print("🔄 准备重新启动语音识别")
//                        self.restartSpeechRecognition()
//                    }
//                }
//            }
//        } catch {
//            print("❌ 音频引擎启动失败: \(error.localizedDescription)")
//            print("🔍 错误详情: \(error)")
//        }
//    }
//    // ... existing code ...
//    // 重新开始语音识别
//      func restartSpeechRecognition() {
//        print("🔄 准备重新启动语音识别（0.5秒后）")
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            print("🔍 检查重启条件 - callState: \(self.callManager.callState), isMuted: \(self.isMuted)")
//            if self.callManager.callState == .connected && !self.isMuted {
//                print("✅ 条件满足，重新启动语音识别")
//                self.startContinuousSpeechRecognition()
//            } else {
//                print("❌ 条件不满足，跳过重启")
//            }
//        }
//    }
//    
//    // 停止语音识别
//      func stopSpeechRecognition() {
//        print("🛑 开始停止语音识别")
//        speechTimer?.invalidate()
//        print("⏰ 定时器已取消")
//        
//        if audioEngine.isRunning {
//            audioEngine.stop()
//            print("🎵 音频引擎已停止")
//        }
//        
//        audioEngine.inputNode.removeTap(onBus: 0)
//        print("🔌 音频输入节点tap已移除")
//        
//        recognitionRequest?.endAudio()
//        print("📝 识别请求已结束")
//        
//        recognitionTask?.cancel()
//        print("❌ 识别任务已取消")
//        
//        recognitionRequest = nil
//        recognitionTask = nil
//        currentSpeechText = ""
//        isSpeaking = false
//        print("🧹 语音识别相关状态已清理")
//    }
//    
//    
//    // 切换静音状态
//      func toggleMute() {
//        print("🔇 切换静音状态: \(isMuted) -> \(!isMuted)")
//        isMuted.toggle()
//        
//        if isMuted {
//            print("🔇 已静音，停止语音识别")
//            stopSpeechRecognition()
//        } else if callManager.callState == .connected {
//            print("🔊 取消静音，重新启动语音识别")
//            startContinuousSpeechRecognition()
//        }
//    }
//    
//      var statusText: String {
//        switch callManager.callState {
//        case .idle:
//            return "Everything is okay😁"
//        case .ringing:
//            return "You look lonely , I can fix that..."
//        case .connected:
//            if isMuted {
//                return "已静音 - \(callManager.formatDuration(callManager.callDuration))"
//            } else {
//                return callManager.formatDuration(callManager.callDuration)
//            }
//        case .ended:
//            return "通话结束"
//        }
//    }
//}
//
//// 远程视频视图
//struct RemoteVideoView: UIViewRepresentable {
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//    
//    func makeUIView(context: Context) -> UIView {
//        let containerView = UIView()
//        containerView.backgroundColor = UIColor.clear
//        
//        let hostingController = UIHostingController(rootView: remoteView())
//        hostingController.view.backgroundColor = UIColor.clear
//        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
//        
//        containerView.addSubview(hostingController.view)
//        
//        NSLayoutConstraint.activate([
//            hostingController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
//            hostingController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
//            hostingController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
//            hostingController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
//        ])
//        
//        context.coordinator.hostingController = hostingController
//        
//        return containerView
//    }
//    
//    func updateUIView(_ uiView: UIView, context: Context) {
//        // 更新视图
//    }
//    
//    class Coordinator {
//        var hostingController: UIHostingController<remoteView>?
//    }
//}
//
//// 本地视频预览
//struct LocalVideoPreview: UIViewRepresentable {
//    @Binding var isFrontCamera: Bool
//    
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView()
//        view.backgroundColor = UIColor.black
//        view.layer.cornerRadius = 12
//        view.clipsToBounds = true
//        
//        // 这里可以添加 AVCaptureVideoPreviewLayer
//        // 用于显示本地摄像头画面
//        
//        return view
//    }
//    
//    func updateUIView(_ uiView: UIView, context: Context) {
//        // 根据 isFrontCamera 切换摄像头
//    }
//}
//
//#Preview {
//    CallView(callManager: CallManager())
//}
