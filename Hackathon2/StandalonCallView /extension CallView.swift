//
//  Untitled.swift
//  Aura calling
//
//  Created by Macbook pro on 2025/8/17.
//
import SwiftUI
import AVFoundation
import Speech


extension StandaloneCallView {
    func addDebugMessage(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let debugMessage = "[\(timestamp)] \(message)"
        debugMessages.append(debugMessage)
        
        if debugMessages.count > 50 {
            debugMessages.removeFirst()
        }
        
        print(debugMessage)
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
    func audioBufferToData(_ buffer: AVAudioPCMBuffer) -> Data {
        let channelData = buffer.floatChannelData![0]
        let frameLength = Int(buffer.frameLength)
        
        let data = Data(bytes: channelData, count: frameLength * MemoryLayout<Float>.size)
        return data
    }
    
    // 删除这些存储属性定义（第78-88行）：
    // private var isRecording = false
    // private var speechBuffer = Data()
    // private var silenceTimer: Timer?
    // private var lastSpeechTime: Date?
    // private var speechStartTime: Date?
    // private let silenceThreshold: Float = -40.0
    // private let silenceDuration: TimeInterval = 1.5
    // private let minSpeechDuration: TimeInterval = 0.5
    // private let maxSpeechDuration: TimeInterval = 10.0
    
    func startContinuousSpeechRecognition() {
        guard !isMuted else { return }
        
        stopSpeechRecognition()
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker, .duckOthers])
            try audioSession.setActive(true)
        } catch {
            addDebugMessage("Audio session configuration failed: \(error.localizedDescription)")
            return
        }
        
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        // 重置VAD状态
        resetVADState()
        
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, time in
            guard let self = self else { return }
            
            // 计算音频音量
            let volume = self.calculateVolume(from: buffer)
            
            // 语音活动检测
            self.processVoiceActivity(buffer: buffer, volume: volume)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            addDebugMessage("🎤 Voice Activity Detection started")
        } catch {
            addDebugMessage("❌ Audio recording startup failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 语音活动检测核心逻辑
    
    private func processVoiceActivity(buffer: AVAudioPCMBuffer, volume: Float) {
        let currentTime = Date()
        let isSpeech = volume > silenceThreshold
        
        if isSpeech {
            // 检测到语音
            handleSpeechDetected(buffer: buffer, currentTime: currentTime)
        } else {
            // 检测到静音
            handleSilenceDetected(currentTime: currentTime)
        }
        
        // 检查最大录音时长
        checkMaxRecordingDuration(currentTime: currentTime)
    }
    
    private func handleSpeechDetected(buffer: AVAudioPCMBuffer, currentTime: Date) {
        lastSpeechTime = currentTime
        
        // 取消静音计时器
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        if !isRecording {
            // 开始录音
            startRecording(currentTime: currentTime)
        }
        
        // 添加音频数据到缓冲区
        let audioData = audioBufferToData(buffer)
        speechBuffer.append(audioData)
        
        DispatchQueue.main.async {
            self.addDebugMessage("🗣️ Speech detected, buffer size: \(self.speechBuffer.count) bytes")
        }
    }
    
    private func handleSilenceDetected(currentTime: Date) {
        if isRecording && silenceTimer == nil {
            // 开始静音计时
            silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceDuration, repeats: false) { [weak self] _ in
                self?.finishRecording(reason: "Silence detected")
            }
            
            DispatchQueue.main.async {
                self.addDebugMessage("🤫 Silence detected, starting timer...")
            }
        }
    }
    
    private func startRecording(currentTime: Date) {
        isRecording = true
        speechStartTime = currentTime
        speechBuffer.removeAll()
        
        DispatchQueue.main.async {
            self.addDebugMessage("🎙️ Recording started")
        }
    }
    
    private func finishRecording(reason: String) {
        guard isRecording else { return }
        
        let recordingDuration = speechStartTime.map { Date().timeIntervalSince($0) } ?? 0
        
        // 检查最小录音时长
        if recordingDuration < minSpeechDuration {
            DispatchQueue.main.async {
                self.addDebugMessage("⚠️ Recording too short (\(String(format: "%.1f", recordingDuration))s), discarded")
            }
            resetVADState()
            return
        }
        
        // 发送音频数据
        let finalBuffer = speechBuffer
        
        DispatchQueue.main.async {
            self.addDebugMessage("✅ Recording finished (\(reason)): \(String(format: "%.1f", recordingDuration))s, \(finalBuffer.count) bytes")
            self.sendAudioBufferToBackend(finalBuffer)
        }
        
        resetVADState()
    }
    
    private func checkMaxRecordingDuration(currentTime: Date) {
        guard isRecording,
              let startTime = speechStartTime,
              currentTime.timeIntervalSince(startTime) > maxSpeechDuration else { return }
        
        finishRecording(reason: "Max duration reached")
    }
    
    private func resetVADState() {
        isRecording = false
        speechBuffer.removeAll()
        silenceTimer?.invalidate()
        silenceTimer = nil
        lastSpeechTime = nil
        speechStartTime = nil
    }
    
    // MARK: - 音量计算
    
    private func calculateVolume(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return -100.0 }
        
        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0.0
        
        // 计算RMS (Root Mean Square)
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        
        let rms = sqrt(sum / Float(frameLength))
        
        // 转换为分贝
        let db = 20.0 * log10(max(rms, 1e-10))
        return db
    }
    
    // MARK: - 停止录音
    
    // 保留第256行的stopSpeechRecognition函数，删除第495行的重复定义
    func stopSpeechRecognition() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // 如果正在录音，完成当前录音
        if isRecording {
            finishRecording(reason: "Manual stop")
        }
        
        resetVADState()
        addDebugMessage("🛑 Voice Activity Detection stopped")
    }

    
    
    func createWAVData(from pcmData: Data, sampleRate: Double) -> Data {
        let wavHeaderSize = 44
        let totalAudioLen = pcmData.count
        let totalDataLen = totalAudioLen + wavHeaderSize - 8
        let byteRate = Int(sampleRate) * 2 * 1 // 假设16bit, mono
        
        var wavHeader = Data()
        
        // RIFF header
        wavHeader.append("RIFF".data(using: .ascii)!)
        wavHeader.append(contentsOf: withUnsafeBytes(of: totalDataLen.littleEndian) { Data($0) })
        wavHeader.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        wavHeader.append("fmt ".data(using: .ascii)!)
        wavHeader.append(contentsOf: withUnsafeBytes(of: 16.littleEndian) { Data($0) }) // Subchunk1Size
        wavHeader.append(contentsOf: withUnsafeBytes(of: 1.littleEndian) { Data($0) }) // AudioFormat (PCM)
        wavHeader.append(contentsOf: withUnsafeBytes(of: 1.littleEndian) { Data($0) }) // NumChannels (Mono)
        wavHeader.append(contentsOf: withUnsafeBytes(of: Int32(sampleRate).littleEndian) { Data($0) })
        wavHeader.append(contentsOf: withUnsafeBytes(of: Int32(byteRate).littleEndian) { Data($0) })
        wavHeader.append(contentsOf: withUnsafeBytes(of: 2.littleEndian) { Data($0) }) // BlockAlign
        wavHeader.append(contentsOf: withUnsafeBytes(of: 16.littleEndian) { Data($0) }) // BitsPerSample
        
        // data chunk
        wavHeader.append("data".data(using: .ascii)!)
        wavHeader.append(contentsOf: withUnsafeBytes(of: totalAudioLen.littleEndian) { Data($0) })
        
        return wavHeader + pcmData
    }
    func sendAudioBufferToBackend(_ audioData: Data) {
        guard !audioData.isEmpty else { return }
            
            addDebugMessage("📤 Sending audio data to backend（发送音频到后台）: \(audioData.count) bytes")
            
            let url = URL(string: "https://emohunter-api-6106408799.us-central1.run.app/api/v1/voice_conversation")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 30.0
            
            // 创建multipart/form-data格式
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            // 构建multipart body
            var body = Data()
            
            // 添加音频文件
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
            
            // 添加user_id字段
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
            body.append(userId.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
            
            // 结束boundary
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            addDebugMessage("✅ Audio data encoded as multipart/form-data")
            
            // 网络请求执行代码保持不变...
            let startTime = Date()
            // 在 sendAudioBufferToBackend 函数中，替换现有的响应处理代码
            URLSession.shared.dataTask(with: request) { data, response, error in
                let responseTime = Date().timeIntervalSince(startTime)
                
                DispatchQueue.main.async {
                    if let error = error {
                        self.addDebugMessage("❌ API request failed (\(String(format: "%.2f", responseTime))s): \(error.localizedDescription)")
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        self.addDebugMessage("✅ API response status code: \(httpResponse.statusCode) (duration: \(String(format: "%.2f", responseTime)) seconds)")
                        
                        // 添加响应头信息调试
                        if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
                            self.addDebugMessage("📋 Response Content-Type: \(contentType)")
                        }
                        if let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length") {
                            self.addDebugMessage("📏 Response Content-Length: \(contentLength)")
                        }
                    }
                    
                    // 改进数据处理逻辑
                    if let data = data {
                        self.addDebugMessage("📥 Received \(data.count) bytes of response data")
                        
                        if data.count == 0 {
                            self.addDebugMessage("⚠️ Response data is empty")
                            return
                        }
                        
                        if let responseString = String(data: data, encoding: .utf8) {
                            self.addDebugMessage("📥 Response content: \(responseString.prefix(500))...")
                            
                            do {
                                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                    self.addDebugMessage("✅ Successfully parsed JSON response")
                                    
                                    if let audioUrl = json["audio_url"] as? String {
                                        self.addDebugMessage("🎵 Received MP3 audio URL: \(audioUrl)")
                                        self.playMP3AudioFromURL(audioUrl)
                                    } else if let audioData = json["audio_data"] as? String {
                                        self.addDebugMessage("🎵 Received base64 audio data (\(audioData.count) characters)")
                                        self.playMP3AudioFromBase64(audioData)
                                    } else {
                                        self.addDebugMessage("❌ No audio_url or audio_data found in response")
                                        self.addDebugMessage("📋 Available keys: \(Array(json.keys))")
                                    }
                                } else {
                                    self.addDebugMessage("❌ Response is not valid JSON")
                                }
                            } catch {
                                self.addDebugMessage("❌ JSON parsing failed: \(error.localizedDescription)")
                                // 尝试直接播放音频数据
                                self.addDebugMessage("🔄 Attempting to play response as direct audio data")
                                self.playMP3AudioData(data)
                            }
                        } else {
                            self.addDebugMessage("❌ Cannot convert response data to string, trying as binary audio")
                            // 尝试直接播放二进制音频数据
                            self.playMP3AudioData(data)
                        }
                    } else {
                        self.addDebugMessage("❌ No response data received (data is nil)")
                    }
                }
            }
            .resume()
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
        addDebugMessage(" Text response received, but using MP3 audio instead: \(text)")
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
