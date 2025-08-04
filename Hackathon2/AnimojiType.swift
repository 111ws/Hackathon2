//
//  AnimojiType.swift
//  Hackathon2
//
//  Created by 陆氏干饭王 on 03-08-2025.
//


import SwiftUI
import ARKit
import AVFoundation
import RealityKit
import Combine

enum AnimojiType: String, CaseIterable {
    case memoji = "Memoji"
    case robot = "Robot"
    case alien = "Alien"
    case cat = "Cat"
    case dog = "Dog"
    
    var fileName: String {
        switch self {
        case .memoji: return "Memoji.usdz"
        case .robot: return "RobotHead.usdz"
        case .alien: return "AlienHead.usdz"
        case .cat: return "CatHead.usdz"
        case .dog: return "DogHead.usdz"
        }
    }
}

// 用户视频渲染管理器
// 修改UserVideoRenderer类，将videoCapture改为internal访问级别
class UserVideoRenderer: NSObject, ObservableObject {
    @Published var isAnimojiEnabled = true
    @Published var currentAnimoji: AnimojiType = .memoji
    @Published var faceTrackingActive = false
    @Published var blendShapes: [ARFaceAnchor.BlendShapeLocation: Float] = [:]
    
    // 将videoCapture改为internal访问级别
    var videoCapture: AVCaptureSession?
    private var arSession: ARSession?
    private var faceAnchor: ARFaceAnchor?
    private var animojiEntity: Entity?
    
    override init() {
        super.init()
        setupFaceTracking()
        setupVideoCapture()
    }
    
    // 设置面部追踪
    private func setupFaceTracking() {
        guard ARFaceTrackingConfiguration.isSupported else {
            print("设备不支持面部追踪")
            return
        }
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        arSession = ARSession()
        arSession?.delegate = self
        arSession?.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        faceTrackingActive = true
    }
    
    // 设置视频捕捉
    private func setupVideoCapture() {
        videoCapture = AVCaptureSession()
        
        guard let captureSession = videoCapture,
              let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            
            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
            }
            
            captureSession.startRunning()
        } catch {
            print("视频捕捉设置失败: \(error)")
        }
    }
    
    // 切换拟我表情
    func switchAnimoji(_ type: AnimojiType) {
        currentAnimoji = type
        loadAnimojiModel(type)
    }
    
    // 加载拟我表情模型
    private func loadAnimojiModel(_ type: AnimojiType) {
        guard let modelURL = Bundle.main.url(forResource: type.fileName, withExtension: nil) else {
            print("找不到拟我表情模型: \(type.fileName)")
            return
        }
        
        do {
            let entity = try Entity.load(contentsOf: modelURL)
            animojiEntity = entity
            
            // 设置面部绑定
            if let faceAnchor = faceAnchor {
                updateAnimojiWithFaceAnchor(faceAnchor)
            }
        } catch {
            print("加载拟我表情失败: \(error)")
        }
    }
    
    // 更新拟我表情与面部数据
    private func updateAnimojiWithFaceAnchor(_ anchor: ARFaceAnchor) {
        guard isAnimojiEnabled, let entity = animojiEntity else { return }
        
        // 获取面部混合形状数据并转换为Float
        var floatBlendShapes: [ARFaceAnchor.BlendShapeLocation: Float] = [:]
        for (location, value) in anchor.blendShapes {
            floatBlendShapes[location] = value.floatValue
        }
        blendShapes = floatBlendShapes
        
        // 应用面部表情到拟我表情
        for (blendShapeLocation, coefficient) in floatBlendShapes {
            applyBlendShape(blendShapeLocation, coefficient: coefficient, to: entity)
        }
        
        // 更新头部位置和旋转
        entity.transform = Transform(matrix: anchor.transform)
    }
    
    // 应用混合形状到拟我表情
    private func applyBlendShape(_ location: ARFaceAnchor.BlendShapeLocation, coefficient: Float, to entity: Entity) {
        let blendShapeName = blendShapeName(for: location)
        
        // 使用RealityKit的方式处理混合形状权重
        if let modelEntity = entity as? Entity {
            // RealityKit中混合形状权重需要通过组件系统处理
            // 这里使用简化的方式，实际应用中需要根据模型结构调整
            print("应用混合形状: \(blendShapeName) 权重: \(coefficient)")
        }
    }
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupVideoCapture()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupVideoCapture()
                    }
                }
            }
        case .denied, .restricted:
            print("摄像头权限被拒绝")
        @unknown default:
            break
        }
    }
    // 映射AR面部混合形状到模型混合形状名称
    private func blendShapeName(for location: ARFaceAnchor.BlendShapeLocation) -> String {
        switch location {
        case .eyeBlinkLeft: return "eyeBlink_L"
        case .eyeBlinkRight: return "eyeBlink_R"
        case .jawOpen: return "jawOpen"
        case .mouthSmileLeft: return "mouthSmile_L"
        case .mouthSmileRight: return "mouthSmile_R"
        case .browDownLeft: return "browDown_L"
        case .browDownRight: return "browDown_R"
        case .browOuterUpLeft: return "browOuterUp_L"
        case .browOuterUpRight: return "browOuterUp_R"
        case .cheekPuff: return "cheekPuff"
        case .noseSneerLeft: return "noseSneer_L"
        case .noseSneerRight: return "noseSneer_R"
        case .tongueOut: return "tongueOut"
        default: return location.rawValue
        }
    }
    
    // 获取面部数据用于传输
    func getFaceDataForTransmission() -> FaceData {
        return FaceData(
            blendShapes: blendShapes,
            headTransform: faceAnchor?.transform ?? matrix_identity_float4x4,
            timestamp: Date()
        )
    }
    
    // 获取ARSession实例（解决访问权限问题）
    func getARSession() -> ARSession? {
        return arSession
    }
    
    // 清理资源
    func cleanup() {
        arSession?.pause()
        videoCapture?.stopRunning()
        arSession = nil
        videoCapture = nil
    }
}

// 面部数据传输结构 - 修复Codable实现
struct FaceData: Codable {
    let blendShapes: [String: Float]
    let headTransform: simd_float4x4
    let timestamp: Date
    
    init(blendShapes: [ARFaceAnchor.BlendShapeLocation: Float], headTransform: simd_float4x4, timestamp: Date) {
        self.blendShapes = Dictionary(uniqueKeysWithValues: blendShapes.map { ($0.rawValue, $1) })
        self.headTransform = headTransform
        self.timestamp = timestamp
    }
    
    // 实现Codable协议
    enum CodingKeys: String, CodingKey {
        case blendShapes, headTransform, timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        blendShapes = try container.decode([String: Float].self, forKey: .blendShapes)
        
        let transformArray = try container.decode([Float].self, forKey: .headTransform)
        headTransform = simd_float4x4(
            simd_float4(transformArray[0], transformArray[1], transformArray[2], transformArray[3]),
            simd_float4(transformArray[4], transformArray[5], transformArray[6], transformArray[7]),
            simd_float4(transformArray[8], transformArray[9], transformArray[10], transformArray[11]),
            simd_float4(transformArray[12], transformArray[13], transformArray[14], transformArray[15])
        )
        
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(blendShapes, forKey: .blendShapes)
        
        let transformArray: [Float] = [
            headTransform.columns.0.x, headTransform.columns.0.y, headTransform.columns.0.z, headTransform.columns.0.w,
            headTransform.columns.1.x, headTransform.columns.1.y, headTransform.columns.1.z, headTransform.columns.1.w,
            headTransform.columns.2.x, headTransform.columns.2.y, headTransform.columns.2.z, headTransform.columns.2.w,
            headTransform.columns.3.x, headTransform.columns.3.y, headTransform.columns.3.z, headTransform.columns.3.w
        ]
        try container.encode(transformArray, forKey: .headTransform)
        
        try container.encode(timestamp, forKey: .timestamp)
    }
}

// ARSession 代理
extension UserVideoRenderer: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let faceAnchor = anchor as? ARFaceAnchor {
                self.faceAnchor = faceAnchor
                updateAnimojiWithFaceAnchor(faceAnchor)
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("ARSession 失败: \(error)")
    }
}

// AVCaptureVideoDataOutput 代理
extension UserVideoRenderer: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 处理视频帧数据
        // 这里可以进行视频编码和传输
    }
}

// SwiftUI 视图包装器
struct UserVideoView: UIViewRepresentable {
    @ObservedObject var renderer: UserVideoRenderer
    
    // 修改UserVideoView的makeUIView方法
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .black
        
        // 添加视频预览层
        if let captureSession = renderer.videoCapture {
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            previewLayer.frame = containerView.bounds
            containerView.layer.addSublayer(previewLayer)
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 更新视图
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

// 使用示例
struct UserVideoCallView: View {
    @StateObject private var renderer = UserVideoRenderer()
    
    var body: some View {
        VStack {
            UserVideoView(renderer: renderer)
                .frame(height: 300)
                .cornerRadius(12)
                .padding()
            
            HStack {
                Button("切换表情") {
                    let nextType = AnimojiType.allCases[(renderer.currentAnimoji.hashValue + 1) % AnimojiType.allCases.count]
                    renderer.switchAnimoji(nextType)
                }
                .padding()
                
                Toggle("启用拟我表情", isOn: $renderer.isAnimojiEnabled)
                    .padding()
            }
        }
    }
}
#Preview {
    UserVideoCallView()
}
