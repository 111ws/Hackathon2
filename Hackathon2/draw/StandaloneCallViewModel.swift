//import SwiftUI
//import AVFoundation
//import Speech
//import Combine
//
//class StandaloneCallViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
//    @Published var isVideoEnabled = true
//    @Published var isFrontCamera = true
//    @Published var isCallActive = true
//    @Published var callDuration: TimeInterval = 0
//    @Published var currentSpeechText = ""
//    @Published var speechHistory: [String] = []
//    @Published var isSpeaking = false
//    @Published var isMuted = false
//    @Published var isPlayingResponse = false
//    @Published var debugMessages: [String] = []
//    @Published var audioDownloadProgress: Float = 0.0
//    @Published var audioPlaybackProgress: Float = 0.0
//    
//    private var timer: Timer?
//    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
//    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
//    private var recognitionTask: SFSpeechRecognitionTask?
//    private var audioEngine = AVAudioEngine()
//    private var audioPlayer: AVAudioPlayer?
//    private var playbackTimer: Timer?
//    private var previousTranscription: String = ""
//    private var speechTimer: Timer?
//    
//    let contactName = "Contact"
//    private let userId = "user_001"
//    
//    var statusText: String {
//        if !isCallActive {
//            return "Call ended"
//        } else if callDuration < 1 {
//            return "Connecting..."
//        } else {
//            let minutes = Int(callDuration) / 60
//            let seconds = Int(callDuration) % 60
//            return String(format: "In call %02d:%02d", minutes, seconds)
//        }
//    }
//    
//    override init() {
//        super.init()
//        startCallTimer()
//        requestSpeechAuthorization()
//        setupAudioSession()
//        addDebugMessage("App started, initializing audio session")
//    }
//    
//    deinit {
//        stopCallTimer()
//        stopSpeechRecognition()
//        stopAudioPlayback()
//        addDebugMessage("App closed, cleaning up resources")
//    }
//    
//    func startCallTimer() {
//        timer?.invalidate()
//        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
//            if self.isCallActive {
//                self.callDuration += 1
//            }
//        }
//    }
//    
//    func stopCallTimer() {
//        timer?.invalidate()
//        timer = nil
//    }
//    
//    func requestSpeechAuthorization() {
//        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
//            DispatchQueue.main.async {
//                switch authStatus {
//                case .authorized:
//                    self?.addDebugMessage("Speech recognition authorized")
//                    self?.startContinuousSpeechRecognition()
//                case .denied:
//                    self?.addDebugMessage("Speech recognition denied")
//                case .restricted:
//                    self?.addDebugMessage("Speech recognition restricted")
//                case .notDetermined:
//                    self?.addDebugMessage("Speech recognition not determined")
//                @unknown default:
//                    self?.addDebugMessage("Speech recognition unknown status")
//                }
//            }
//        }
//    }
//    
//    func setupAudioSession() {
//        do {
//            let audioSession = AVAudioSession.sharedInstance()
//            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .duckOthers])
//            try audioSession.setActive(true)
//            addDebugMessage("Audio session setup successful")
//        } catch {
//            addDebugMessage("Audio session setup failed: \(error.localizedDescription)")
//        }
//    }
//    
//    func startContinuousSpeechRecognition() {
//        guard !audioEngine.isRunning else { return }
//        
//        do {
//            let node = audioEngine.inputNode
//            let recordingFormat = node.outputFormat(forBus: 0)
//            
//            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
//            guard let recognitionRequest = recognitionRequest else {
//                addDebugMessage("Unable to create speech recognition request")
//                return
//            }
//            
//            recognitionRequest.shouldReportPartialResults = true
//            recognitionRequest.requiresOnDeviceRecognition = false
//            
//            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
//                if let result = result {
//                    let transcription = result.bestTranscription.formattedString
//                    
//                    // 更新当前语音文本显示
//                    self?.currentSpeechText = transcription
//                    self?.isSpeaking = !result.isFinal
//                    
//                    // 如果文本发生变化且不为空，设置定时器
//                    if !transcription.isEmpty && transcription != self?.previousTranscription {
//                        self?.previousTranscription = transcription
//                        
//                        // 取消之前的定时器
//                        self?.speechTimer?.invalidate()
//                        
//                        // 设置新的定时器，延迟发送
//                        self?.speechTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
//                            if !transcription.isEmpty {
//                                self?.sendSpeechToBackend(message: transcription)
//                                self?.speechHistory.append(transcription)
//                                self?.currentSpeechText = ""
//                                self?.previousTranscription = ""
//                            }
//                        }
//                    }
//                    
//                    // 如果是最终结果，立即发送
//                    if result.isFinal {
//                        self?.speechTimer?.invalidate()
//                        if !transcription.isEmpty {
//                            self?.sendSpeechToBackend(message: transcription)
//                            self?.speechHistory.append(transcription)
//                            self?.currentSpeechText = ""
//                            self?.previousTranscription = ""
//                        }
//                    }
//                }
//                
//                if let error = error {
//                    self?.addDebugMessage("Speech recognition error: \(error.localizedDescription)")
//                    self?.restartSpeechRecognition()
//                }
//            }
//            
//            node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
//                self.recognitionRequest?.append(buffer)
//            }
//            
//            audioEngine.prepare()
//            try audioEngine.start()
//            
//            addDebugMessage("Speech recognition started")
//            
//        } catch {
//            addDebugMessage("Speech recognition startup failed: \(error.localizedDescription)")
//        }
//    }
//    
//    func addDebugMessage(_ message: String) {
//        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
//        let debugMessage = "[\(timestamp)] \(message)"
//        debugMessages.append(debugMessage)
//        
//        if debugMessages.count > 50 {
//            debugMessages.removeFirst()
//        }
//        
//        print(debugMessage)
//    }
//    
//    func stopSpeechRecognition() {
//        audioEngine.stop()
//        audioEngine.inputNode.removeTap(onBus: 0)
//        recognitionRequest?.endAudio()
//        recognitionTask?.cancel()
//        
//        recognitionRequest = nil
//        recognitionTask = nil
//        isSpeaking = false
//        
//        addDebugMessage("Speech recognition stopped")
//    }
//    
//    func restartSpeechRecognition() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
//            if self?.isCallActive == true {
//                self?.startContinuousSpeechRecognition()
//            }
//        }
//    }
//    
//    func stopAudioPlayback() {
//        audioPlayer?.stop()
//        audioPlayer = nil
//        isPlayingResponse = false
//        stopPlaybackProgressTimer()
//        addDebugMessage("Audio playback stopped")
//    }
//    
//    func stopPlaybackProgressTimer() {
//        playbackTimer?.invalidate()
//        playbackTimer = nil
//    }
//    
//    func sendSpeechToBackend(message: String) {
//        guard !message.isEmpty else { return }
//        
//        addDebugMessage("📤 Sending speech to backend: \"\(message.prefix(20))...\"")
//        
//        let url = URL(string: "https://emohunter-biometric-api-6106408799.us-central1.run.app/api/v1/unified/emotion_chat")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.timeoutInterval = 30.0
//        
//        let requestBody = [
//            "message": message,
//            "user_id": userId
//        ]
//        
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
//            addDebugMessage("✅ Request body serialized successfully")
//        } catch {
//            addDebugMessage("❌ JSON serialization failed: \(error.localizedDescription)")
//            return
//        }
//        
//        let startTime = Date()
//        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
//            let responseTime = Date().timeIntervalSince(startTime)
//            
//            DispatchQueue.main.async {
//                if let error = error {
//                    self?.addDebugMessage("❌ API request failed (\(String(format: "%.2f", responseTime))s): \(error.localizedDescription)")
//                    return
//                }
//                
//                if let httpResponse = response as? HTTPURLResponse {
//                    self?.addDebugMessage("✅ API response status code: \(httpResponse.statusCode)")
//                }
//                
//                if let data = data, let responseString = String(data: data, encoding: .utf8) {
//                    self?.addDebugMessage("📥 Received response data: \(responseString.prefix(200))...")
//                    
//                    do {
//                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
//                            if let audioUrl = json["audio_url"] as? String {
//                                self?.addDebugMessage("🎵 Received audio URL: \(audioUrl)")
//                                self?.playAudioFromURL(audioUrl)
//                            } else if let textResponse = json["response"] as? String {
//                                self?.addDebugMessage("📝 Received text response: \(textResponse)")
//                                self?.requestTTSAudio(text: textResponse)
//                            }
//                        }
//                    } catch {
//                        self?.addDebugMessage("❌ Response parsing failed: \(error.localizedDescription)")
//                    }
//                }
//            }
//        }.resume()
//    }
//    
//    func playAudioFromURL(_ urlString: String) {
//        guard let url = URL(string: urlString) else {
//            addDebugMessage("❌ Invalid audio URL")
//            return
//        }
//        
//        stopSpeechRecognition()
//        
//        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
//            DispatchQueue.main.async {
//                if let error = error {
//                    self?.addDebugMessage("❌ Audio download failed: \(error.localizedDescription)")
//                    return
//                }
//                
//                guard let data = data else {
//                    self?.addDebugMessage("❌ Audio data is empty")
//                    return
//                }
//                
//                do {
//                    self?.audioPlayer = try AVAudioPlayer(data: data)
//                    self?.audioPlayer?.delegate = self
//                    self?.audioPlayer?.prepareToPlay()
//                    
//                    self?.isPlayingResponse = true
//                    self?.audioPlayer?.play()
//                    self?.startPlaybackProgressTimer()
//                    
//                    self?.addDebugMessage("🎵 Started playing audio")
//                } catch {
//                    self?.addDebugMessage("❌ Audio playback error: \(error.localizedDescription)")
//                }
//            }
//        }.resume()
//    }
//    
//    func requestTTSAudio(text: String) {
//        addDebugMessage("📝 Received text response, TTS needed: \(text)")
//    }
//    
//    func startPlaybackProgressTimer() {
//        stopPlaybackProgressTimer()
//        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
//            guard let player = self?.audioPlayer else { return }
//            
//            let currentTime = player.currentTime
//            let progress = Float(currentTime / player.duration)
//            self?.audioPlaybackProgress = progress
//        }
//    }
//    
//    func endCall() {
//        isCallActive = false
//        stopCallTimer()
//        stopSpeechRecognition()
//        stopAudioPlayback()
//    }
//    
//    // MARK: - AVAudioPlayerDelegate
//    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
//        addDebugMessage("🎵 Audio playback completed")
//        isPlayingResponse = false
//        stopPlaybackProgressTimer()
//        restartSpeechRecognition()
//    }
//    
//    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
//        addDebugMessage("❌ Audio decode error: \(error?.localizedDescription ?? "Unknown error")")
//        isPlayingResponse = false
//        restartSpeechRecognition()
//    }
//}
