//
//  CallView.swift
//  Hackathon2
//
//  Created by 陆氏干饭王 on 03-08-2025.
//


import SwiftUI
import AVFoundation
import CallKit
import PushKit

// 录音管理器
class AudioRecordingManager: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var volumeTimer: Timer?
    private var silenceTimer: Timer?
    private var isMonitoring = false
    
    @Published var isRecording = false
    @Published var currentVolume: Float = 0.0
    
    // 音量阈值和静音检测时间
    private let volumeThreshold: Float = 1// 音量阈值，大于此值认为在说话
    private let silenceDetectionTime: TimeInterval = 3.0 // 3秒静音后停止录音
    
    override init() {
        super.init()
        print("[录音调试] AudioRecordingManager 初始化")
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        print("[录音调试] 开始设置音频会话")
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            print("[录音调试] 音频会话设置成功")
            
            // 请求录音权限
            audioSession.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    print("[录音调试] 录音权限请求结果: \(granted ? "已授权" : "被拒绝")")
                    if granted {
                        self.startVolumeMonitoring()
                    }
                }
            }
        } catch {
            print("[录音调试] 音频会话设置失败: \(error.localizedDescription)")
        }
    }
    
    // 开始音量监测
    func startVolumeMonitoring() {
        guard !isMonitoring else { return }
        
        print("[录音调试] 开始音量监测")
        isMonitoring = true
        
        // 创建一个持续录音的录音器用于音量监测
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let monitoringURL = documentsPath.appendingPathComponent("volume_monitor.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        
        do {
            // 使用一个专门的监测录音器
            let monitorRecorder = try AVAudioRecorder(url: monitoringURL, settings: settings)
            monitorRecorder.isMeteringEnabled = true
            monitorRecorder.prepareToRecord()
            
            // 开始录音以监测音量
            if monitorRecorder.record() {
                print("[录音调试] 音量监测录音器启动成功")
                
                // 定时检测音量
                volumeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    monitorRecorder.updateMeters()
                    let averagePower = monitorRecorder.averagePower(forChannel: 0)
                    let peakPower = monitorRecorder.peakPower(forChannel: 0)
                    let volume = self.convertPowerToVolume(averagePower)
                    
                    print("[录音调试] 原始分贝值: \(averagePower), 峰值: \(peakPower), 转换后音量: \(volume)")
                    
                    DispatchQueue.main.async {
                        self.currentVolume = volume
                        self.handleVolumeChange(volume)
                    }
                }
            } else {
                print("[录音调试] 音量监测录音器启动失败")
            }
            
        } catch {
            print("[录音调试] 音量监测设置失败: \(error.localizedDescription)")
        }
    }
    
    // 停止音量监测
    func stopVolumeMonitoring() {
        print("[录音调试] 停止音量监测")
        isMonitoring = false
        volumeTimer?.invalidate()
        volumeTimer = nil
        silenceTimer?.invalidate()
        silenceTimer = nil
    }
    
    // 处理音量变化
    private func handleVolumeChange(_ volume: Float) {
        print("[录音调试] 当前音量: \(String(format: "%.4f", volume)), 阈值: \(volumeThreshold), 是否录音中: \(isRecording)")
        
        if volume > volumeThreshold {
            // 检测到声音，开始录音
            if !isRecording {
                print("[录音调试] ✅ 检测到声音超过阈值，自动开始录音")
                startRecording()
            } else {
                print("[录音调试] 🔄 继续录音中，音量: \(String(format: "%.4f", volume))")
            }
            
            // 取消静音定时器
            if silenceTimer != nil {
                print("[录音调试] 🔄 取消静音定时器")
                silenceTimer?.invalidate()
                silenceTimer = nil
            }
            
        } else {
            // 检测到静音
            if isRecording && silenceTimer == nil {
                print("[录音调试] 🔇 检测到静音，开始3秒倒计时")
                
                // 开始3秒静音倒计时
                silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceDetectionTime, repeats: false) { _ in
                    DispatchQueue.main.async {
                        print("[录音调试] ⏰ 静音3秒，自动停止录音")
                        self.stopRecording()
                    }
                }
            }
        }
    }
    
    // 将分贝值转换为音量值
    private func convertPowerToVolume(_ power: Float) -> Float {
        // 调整分贝范围，使其更敏感
        let minDb: Float = -60.0  // 提高最小分贝值
        let maxDb: Float = 0.0
        
        if power < minDb {
            return 0.0
        } else if power >= maxDb {
            return 1.0
        } else {
            let normalizedValue = (power - minDb) / (maxDb - minDb)
            // 使用平方根函数使低音量更敏感
            return sqrt(normalizedValue)
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        print("[录音调试] 尝试开始录音")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = DateFormatter().string(from: Date())
        recordingURL = documentsPath.appendingPathComponent("recording_\(timestamp).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            
            let success = audioRecorder?.record() ?? false
            if success {
                DispatchQueue.main.async {
                    self.isRecording = true
                    print("[录音调试] 录音开始成功，文件路径: \(self.recordingURL?.path ?? "未知")")
                }
            } else {
                print("[录音调试] 录音开始失败")
            }
        } catch {
            print("[录音调试] 录音设置失败: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        print("[录音调试] 停止录音")
        audioRecorder?.stop()
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        // 取消静音定时器
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        // 上传录音文件
        if let url = recordingURL {
            uploadRecording(url: url)
        }
    }
    
    private func uploadRecording(url: URL) {
        print("[录音调试] 开始上传录音文件: \(url.path)")
        
        guard let audioData = try? Data(contentsOf: url) else {
            print("[录音调试] 读取录音文件失败")
            return
        }
        
        print("[录音调试] 录音文件大小: \(audioData.count) 字节")
        
        guard let uploadURL = URL(string: "https://emohunter-api-6106408799.us-central1.run.app/speech_to_text") else {
            print("[录音调试] API URL 无效")
            return
        }
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[录音调试] 上传失败: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("[录音调试] 上传响应状态码: \(httpResponse.statusCode)")
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("[录音调试] 服务器响应: \(responseString)")
                    }
                }
            }
        }.resume()
    }
    
    deinit {
        stopVolumeMonitoring()
        if isRecording {
            stopRecording()
        }
    }
}

extension AudioRecordingManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("[录音调试] 录音完成，成功: \(flag)")
        if flag {
            print("[录音调试] 录音文件保存成功")
        } else {
            print("[录音调试] 录音文件保存失败")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("[录音调试] 录音编码错误: \(error?.localizedDescription ?? "未知错误")")
    }
}

struct CallView: View {
    @ObservedObject var callManager: CallManager
    @StateObject private var audioRecorder = AudioRecordingManager()
    @State private var isVideoEnabled = true
    @State private var isFrontCamera = true
    
    var body: some View {
        ZStack {
            // 背景
            if callManager.callState == .connected && isVideoEnabled {
                // 视频通话背景
                remoteView()
                    .ignoresSafeArea()
            } else {
                // 音频通话背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.98, green: 0.75, blue: 0.65),
                        Color(red: 0.99, green: 0.85, blue: 0.55)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                if callManager.callState != .connected || !isVideoEnabled {
                    // 联系人头像和动画
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 150, height: 150)
                        .overlay(
                            AdvancedGradientRippleAnimation(
                                color: .white,
                                maxSize: 180,
                                centerColor: Color.white,
                                edgeColor: .clear
                            )
                            .frame(width: 300, height: 300)
                        )
                }
                
                // 联系人姓名
                Text(callManager.contactName)
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
                
                // 通话状态文本
                Text(statusText)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.5), radius: 2)
                
              
                Spacer()
                
                // 通话控制按钮
                HStack(spacing: 40) {
                    if callManager.callState == .ringing {
                        // 接听按钮
                        Button(action: {
                            print("[录音调试] 接听按钮被点击")
                            callManager.answerCall()
                        }) {
                            Circle()
                                .fill(Color.green)
                            // 将所有按钮改为统一的 65x65
                            .frame(width: 65, height: 65)
                                .overlay(
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    
                    if callManager.callState == .connected {
                        // 移除录音按钮，保留其他功能按钮
                        
                        // 视频开关按钮
                        Button(action: {
                            print("[录音调试] 视频开关按钮被点击")
                            isVideoEnabled.toggle()
                        }) {
                            Circle()
                                .fill(isVideoEnabled ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 65, height: 65)
                                .overlay(
                                    Image(systemName: isVideoEnabled ? "video.fill" : "video.slash.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        // 摄像头切换按钮（仅在视频开启时显示）
                        if isVideoEnabled {
                            Button(action: {
                                print("[录音调试] 摄像头切换按钮被点击")
                                isFrontCamera.toggle()
                            }) {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                // 将所有按钮改为统一的 65x65
                                .frame(width: 65, height: 65)
                                    .overlay(
                                        Image(systemName: "camera.rotate.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        
                        // 静音按钮
                        Button(action: {
                            print("[录音调试] 静音按钮被点击")
                            // 静音功能实现
                        }) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                            // 将所有按钮改为统一的 65x65
                            .frame(width: 65, height: 65)
                                .overlay(
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    
                    // 挂断按钮
                    Button(action: {
                        print("[录音调试] 挂断按钮被点击")
                        if audioRecorder.isRecording {
                            print("[录音调试] 挂断时停止录音")
                            audioRecorder.stopRecording()
                        }
                        callManager.endCall()
                    }) {
                        Circle()
                            .fill(Color.red)
                        // 将所有按钮改为统一的 65x65
                        .frame(width: 65, height: 65)
                            .overlay(
                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding(.bottom, 50)
            }
            .padding()
            
            // 本地视频预览窗口
            if callManager.callState == .connected && isVideoEnabled {
                HStack {
                    SimpleCameraView()
                        .frame(width: 120, height: 160)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 0.6)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                        .padding(.horizontal,-190)
                        .padding(.top, -330)
                }
                .zIndex(1000) // 确保小窗口在最上层
            }
        }
        .onAppear {
            print("[录音调试] CallView 出现")
        }
        .onDisappear {
            print("[录音调试] CallView 消失")
            audioRecorder.stopVolumeMonitoring()
            if audioRecorder.isRecording {
                print("[录音调试] 视图消失时停止录音")
                audioRecorder.stopRecording()
            }
        }
        .onChange(of: callManager.callState) { newState in
            print("[录音调试] 通话状态变化: \(newState)")
            
            switch newState {
            case .connected:
                // 延迟2秒后开始音量监测，确保通话音频会话稳定
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    print("[录音调试] 通话已连接，延迟开始音量监测")
                    audioRecorder.startVolumeMonitoring()
                }
                
            case .ended:
                print("[录音调试] 通话已结束，停止音量监测和录音")
                audioRecorder.stopVolumeMonitoring()
                if audioRecorder.isRecording {
                    audioRecorder.stopRecording()
                }
                
            default:
                break
            }
        }
    }
    
    private var statusText: String {
        switch callManager.callState {
        case .idle:
            return "Everything is okay😁"
        case .ringing:
            return "You look lonely , I can fix that..."
        case .connected:
            return callManager.formatDuration(callManager.callDuration)
        case .ended:
            return "通话结束"
        }
    }
}

// 远程视频视图
struct RemoteVideoView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let hostingController = UIHostingController(rootView: remoteView())
        context.coordinator.hostingController = hostingController
        
        hostingController.view.backgroundColor = .clear
        hostingController.view.frame = containerView.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        containerView.addSubview(hostingController.view)
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 可以通过coordinator更新视图
    }
    
    class Coordinator {
        var hostingController: UIHostingController<remoteView>?
    }
}

// 改进的本地视频预览
struct LocalVideoPreview: UIViewRepresentable {
    @Binding var isFrontCamera: Bool
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .black
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        
        let hostingController = UIHostingController(rootView: SimpleCameraView())
        hostingController.view.backgroundColor = .clear
        hostingController.view.frame = containerView.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        containerView.addSubview(hostingController.view)
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 确保视图大小正确
        if let hostingView = uiView.subviews.first {
            hostingView.frame = uiView.bounds
        }
    }
}

#Preview {
    CallView(callManager: CallManager())
}
