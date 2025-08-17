import SwiftUI
import AVFoundation
import Speech

class StandaloneCallView: ObservableObject {
    private var previousTranscription: String = ""
    @Published var isVideoEnabled = true
    @Published var isFrontCamera = true
    @Published var isCallActive = true
    @Published var callDuration: TimeInterval = 0
    @Published var currentSpeechText = ""
    @Published var speechHistory: [String] = []
    @Published var isSpeaking = false
    @Published var isMuted = false
    @Published var audioPlayer: AVAudioPlayer?
    @Published var isPlayingResponse = false
    @Published var debugMessages: [String] = []
    @Published var showDebugLog = false
    @Published var audioDownloadProgress: Float = 0.0
    @Published var currentAudioDuration: TimeInterval = 0
    @Published var audioPlaybackProgress: Float = 0.0
    
    private var timer: Timer?
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var speechTimer: Timer?
    private var playbackTimer: Timer?
    
    let contactName = "Aura"
    private let userId = "user_001"
    private let speechSynthesizer = AVSpeechSynthesizer()
}

struct StandaloneCallViewWrapper: View {
    @StateObject private var viewModel = StandaloneCallView()
    
    var body: some View {
        StandaloneCallContent(viewModel: viewModel)
    }
}

struct StandaloneCallContent: View {
    @ObservedObject var viewModel: StandaloneCallView
    
    var body: some View {
        ZStack {
            if viewModel.isVideoEnabled {
                remoteView()
                    .ignoresSafeArea()
            } else {
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
                
                if !viewModel.isVideoEnabled {
                    // 联系人头像和动画
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 150, height: 150)
                        .overlay(
                            AdvancedGradientRippleAnimation(
                                color: viewModel.isSpeaking ? .green : .white,
                                maxSize: viewModel.isSpeaking ? 200 : 180,
                                centerColor: viewModel.isSpeaking ? Color.green : Color.white,
                                edgeColor: .clear
                            )
                            .frame(width: 300, height: 300)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.isSpeaking)
                        )
                }
                
                // 联系人姓名
                Text(viewModel.contactName)
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
                
//                // 通话状态文本
//                Text(statusText)
//                    .font(.title3)
//                    .foregroundColor(.white.opacity(0.8))
//                    .shadow(color: .black.opacity(0.5), radius: 2)
//                
//                // 实时语音显示
//                if !viewModel.currentSpeechText.isEmpty {
//                    VStack(spacing: 8) {
//                        Text("You are saying:")
//                            .font(.caption)
//                            .foregroundColor(.white.opacity(0.7))
//                        
//                        Text(viewModel.currentSpeechText)
//                            .font(.body)
//                            .foregroundColor(.white)
//                            .padding(12)
//                            .background(Color.black.opacity(0.3))
//                            .cornerRadius(8)
//                            .transition(.opacity)
//                    }
//                    .animation(.easeInOut, value: viewModel.currentSpeechText)
//                }
                
                if viewModel.isPlayingResponse {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.blue)
                        Text("Playing response...")
                            .foregroundColor(.white)
                    }
                    .animation(.easeInOut, value: viewModel.isPlayingResponse)
                }
                
                Spacer()
                
                // 通话控制按钮
                HStack(spacing: 40) {
                    // 视频开关按钮
                    Button(action: {
                        viewModel.isVideoEnabled.toggle()
                    }) {
                        Circle()
                            .fill(viewModel.isVideoEnabled ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 65, height: 65)
                            .overlay(
                                Image(systemName: viewModel.isVideoEnabled ? "video.fill" : "video.slash.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    // 摄像头切换按钮（仅在视频开启时显示）
                    if viewModel.isVideoEnabled {
                        Button(action: {
                            viewModel.isFrontCamera.toggle()
                        }) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 65, height: 65)
                                .overlay(
                                    Image(systemName: "camera.rotate.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    
                    // 扬声器按钮
                    Button(action: {
                        // 扬声器功能实现
                    }) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 65, height: 65)
                            .overlay(
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    // 挂断按钮
                    Button(action: {
                        viewModel.endCall()
                    }) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 70, height: 70)
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
            
            // 语音历史记录（可选显示）
            if !viewModel.speechHistory.isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            // 显示语音历史
                        }) {
                            Image(systemName: "text.bubble")
                                .foregroundColor(.white.opacity(0.7))
                                .padding(8)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    Spacer()
                }
            }
            
            // 本地视频预览窗口
            if viewModel.isVideoEnabled {
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
                        .padding(.horizontal, -190)
                        .padding(.top, -330)
                }
                .zIndex(1000)
            }
            
            // 调试日志
            if viewModel.showDebugLog {
                VStack {
                    Spacer()
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(viewModel.debugMessages, id: \.self) { message in
                                Text(message)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                    }
                    .frame(height: 200)
                    .padding()
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { viewModel.showDebugLog.toggle() }) {
                        Image(systemName: "ladybug.fill")
                            .foregroundColor(.yellow)
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            viewModel.startCallTimer()
            viewModel.requestSpeechAuthorization()
            viewModel.setupAudioSession()
            viewModel.addDebugMessage("App started, initializing audio session")
        }
        .onDisappear {
            viewModel.stopCallTimer()
            viewModel.stopSpeechRecognition()
            viewModel.stopAudioPlayback()
            viewModel.addDebugMessage("App closed, cleaning up resources")
        }
    }
    
    private var statusText: String {
        if viewModel.isMuted {
            return "Muted - \(viewModel.timeString(from: viewModel.callDuration))"
        } else {
            return viewModel.timeString(from: viewModel.callDuration)
        }
    }
}


extension StandaloneCallView {
    func addDebugMessage(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        let debugMessage = "[\(timestamp)] \(message)"
        debugMessages.append(debugMessage)
        print("🔍 \(debugMessage)")
        
        if debugMessages.count > 50 {
            debugMessages.removeFirst()
        }
    }
    
    func startCallTimer() {
        timer?.invalidate()
        callDuration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.callDuration += 1
        }
    }
    
    func stopCallTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.addDebugMessage("Speech recognition authorized")
                    self.startContinuousSpeechRecognition()
                case .denied:
                    self.addDebugMessage("Speech recognition denied")
                case .restricted:
                    self.addDebugMessage("Speech recognition restricted")
                case .notDetermined:
                    self.addDebugMessage("Speech recognition not determined")
                @unknown default:
                    self.addDebugMessage("Speech recognition unknown status")
                }
            }
        }
    }
    
    func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // 优化音频会话配置以更好地支持MP3播放
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker, .duckOthers])
            try audioSession.setActive(true)
            addDebugMessage("✅ Audio session configured for MP3 playback")
        } catch {
            addDebugMessage("❌ Audio session setup failed: \(error.localizedDescription)")
        }
    }
    
    func startContinuousSpeechRecognition() {
        guard !isMuted,
              speechRecognizer?.isAvailable == true,
              SFSpeechRecognizer.authorizationStatus() == .authorized else {
            return
        }
        
        stopSpeechRecognition()
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker, .duckOthers])
            try audioSession.setActive(true)
        } catch {
            addDebugMessage("Audio session configuration failed: \(error.localizedDescription)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        // 在startContinuousSpeechRecognition方法中，替换recognitionTask的处理逻辑
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
        DispatchQueue.main.async {
        if let result = result {
        let transcription = result.bestTranscription.formattedString
        
        // 更新当前语音文本显示
        self.currentSpeechText = transcription
        self.isSpeaking = !result.isFinal
        
        if !transcription.isEmpty && transcription != self.previousTranscription {
        self.previousTranscription = transcription
        
        // 取消之前的定时器
        self.speechTimer?.invalidate()
        
        // 设置新的定时器，延迟发送以确保语音识别完成
        self.speechTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
        if !transcription.isEmpty {
        self.sendSpeechToBackend(message: transcription)
        self.speechHistory.append(transcription)
        self.currentSpeechText = ""
        self.previousTranscription = ""
        }
        }
        }
        
        // 如果是最终结果，立即发送
        if result.isFinal {
        self.speechTimer?.invalidate()
        if !transcription.isEmpty {
        self.sendSpeechToBackend(message: transcription)
        self.speechHistory.append(transcription)
        self.currentSpeechText = ""
        self.previousTranscription = ""
        }
        }
        }
        
        if error != nil {
        self.addDebugMessage("❌ Speech recognition error: \(error?.localizedDescription ?? "Unknown error")")
        self.restartSpeechRecognition()
        }
        }
        }
        
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            self.addDebugMessage("Speech recognition started")
        } catch {
            self.addDebugMessage("Speech recognition startup failed: \(error.localizedDescription)")
        }
    }
    
    func speakText(_ text: String) {
        // 停止当前语音识别，避免冲突
        stopSpeechRecognition()
        
        // 停止当前正在播放的语音
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US") // 或者使用"zh-CN"中文
        utterance.rate = 0.5 // 语速，范围0.0-1.0
        utterance.pitchMultiplier = 1.0 // 音调
        utterance.volume = 1.0 // 音量
        
        // 设置播放状态
        isPlayingResponse = true
        addDebugMessage("🔊 Started speaking AI response")
        
        speechSynthesizer.speak(utterance)
        
        // 监听语音合成完成
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(text.count) * 0.1) {
            self.isPlayingResponse = false
            self.addDebugMessage("� Finished speaking AI response")
            self.restartSpeechRecognition()
        }
    }
    
    func sendSpeechToBackend(message: String) {
        guard !message.isEmpty else { return }
        
        addDebugMessage("📤 Sending speech to backend: \"\(message.prefix(20))...\"")
        
        // 更改为新的API接口
        let url = URL(string: "https://emohunter-api-6106408799.us-central1.run.app/api/v1/voice_conversation")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        let requestBody = [
            "message": message,
            "user_id": userId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            addDebugMessage("✅ Request body serialized successfully")
        } catch {
            addDebugMessage("❌ JSON serialization failed: \(error.localizedDescription)")
            return
        }
        
        let startTime = Date()
        URLSession.shared.dataTask(with: request) { data, response, error in
            let responseTime = Date().timeIntervalSince(startTime)
            
            DispatchQueue.main.async {
                if let error = error {
                    self.addDebugMessage("❌ API request failed (\(String(format: "%.2f", responseTime))s): \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    self.addDebugMessage("✅ API response status code: \(httpResponse.statusCode)")
                }
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    self.addDebugMessage("📥 Received response data: \(responseString.prefix(200))...")
                    
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            // 新API直接返回音频URL，不再使用AVSpeechSynthesizer
                            if let audioUrl = json["audio_url"] as? String {
                                self.addDebugMessage("🎵 Received MP3 audio URL: \(audioUrl)")
                                self.playMP3AudioFromURL(audioUrl)
                            } else if let audioData = json["audio_data"] as? String {
                                // 如果返回base64编码的音频数据
                                self.addDebugMessage("🎵 Received base64 audio data")
                                self.playMP3AudioFromBase64(audioData)
                            } else {
                                self.addDebugMessage("❌ No audio data found in response")
                            }
                        }
                    } catch {
                        self.addDebugMessage("❌ Response parsing failed: \(error.localizedDescription)")
                    }
                }
            }
        }.resume()
    }
    
    func playMP3AudioFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            addDebugMessage("❌ Invalid MP3 audio URL")
            return
        }
        
        stopSpeechRecognition()
        addDebugMessage("🎵 Starting MP3 download from: \(urlString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.addDebugMessage("❌ MP3 audio download failed: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self.addDebugMessage("❌ MP3 audio data is empty")
                    return
                }
                
                self.addDebugMessage("✅ MP3 downloaded successfully (\(data.count) bytes)")
                self.playMP3AudioData(data)
            }
        }.resume()
    }
    
    func playMP3AudioFromBase64(_ base64String: String) {
        guard let data = Data(base64Encoded: base64String) else {
            addDebugMessage("❌ Invalid base64 audio data")
            return
        }
        
        stopSpeechRecognition()
        addDebugMessage("🎵 Playing MP3 from base64 data (\(data.count) bytes)")
        playMP3AudioData(data)
    }
    
    func playMP3AudioData(_ data: Data) {
        do {
            // 停止之前的音频播放
            stopAudioPlayback()
            
            // 创建新的音频播放器
            self.audioPlayer = try AVAudioPlayer(data: data)
            self.audioPlayer?.delegate = AudioPlayerDelegate(parent: self)
            self.audioPlayer?.prepareToPlay()
            
            self.currentAudioDuration = self.audioPlayer?.duration ?? 0
            self.isPlayingResponse = true
            
            // 开始播放
            self.audioPlayer?.play()
            self.startPlaybackProgressTimer()
            
            // Fix the string interpolation syntax error
            self.addDebugMessage("🎵 Started playing MP3 audio (duration: \(String(format: "%.1f", self.currentAudioDuration))s)")
        } catch {
            self.addDebugMessage("❌ MP3 audio playback error: \(error.localizedDescription)")
            self.isPlayingResponse = false
            self.restartSpeechRecognition()
        }
    }
    
    // 注释掉或删除原来的speakText方法，因为不再使用AVSpeechSynthesizer
    /*
    func speakText(_ text: String) {
        // 原来的AVSpeechSynthesizer代码
    }
    */
    
    // 简化requestTTSAudio方法
    func requestTTSAudio(text: String) {
        addDebugMessage("� Text response received, but using MP3 audio instead: \(text)")
        // 不再需要TTS，因为API直接返回MP3音频
    }
    
    func startPlaybackProgressTimer() {
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] _ in
            guard let player = self.audioPlayer else { return }
            
            let currentTime = player.currentTime
            let progress = Float(currentTime / player.duration)
            self.audioPlaybackProgress = progress
        }
    }
    
    func stopSpeechRecognition() {
        speechTimer?.invalidate()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        currentSpeechText = ""
        isSpeaking = false
    }
    
    func restartSpeechRecognition() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.isCallActive && !self.isMuted {
                self.startContinuousSpeechRecognition()
            }
        }
    }
    
    func stopAudioPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlayingResponse = false
        stopPlaybackProgressTimer()
    }
    
    func stopPlaybackProgressTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    func endCall() {
        isCallActive = false
        stopCallTimer()
        stopSpeechRecognition()
        stopAudioPlayback()
    }
    
    func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    weak var parent: StandaloneCallView?
    
    init(parent: StandaloneCallView) {
        self.parent = parent
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.parent?.addDebugMessage("🎵 Audio playback completed")
            self.parent?.isPlayingResponse = false
            self.parent?.stopPlaybackProgressTimer()
            self.parent?.restartSpeechRecognition()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.parent?.addDebugMessage("❌ Audio decode error: \(error?.localizedDescription ?? "Unknown error")")
            self.parent?.isPlayingResponse = false
            self.parent?.restartSpeechRecognition()
        }
    }
}
#Preview {
    StandaloneCallViewWrapper()
}
