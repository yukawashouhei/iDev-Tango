//
//  ConfettiView.swift
//  iDev Tango
//
//  紙吹雪アニメーションビュー
//  CADisplayLinkベースの滑らかなアニメーション
//

import SwiftUI
import QuartzCore

// MARK: - DisplayLinkDriver

/// 画面リフレッシュ同期のフレーム更新ドライバー
@MainActor
final class DisplayLinkDriver {
    private var displayLink: CADisplayLink?
    private var handler: ((Date) -> Void)?
    
    func start(handler: @escaping (Date) -> Void) {
        stop()
        self.handler = handler
        
        let displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
    }
    
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        handler = nil
    }
    
    @objc private func handleDisplayLink(_ displayLink: CADisplayLink) {
        handler?(Date(timeIntervalSinceReferenceDate: displayLink.timestamp))
    }
}

// MARK: - ConfettiParticle

/// パーティクル構造体
struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var color: Color
    var rotationX: Double     // X軸回転（前後回転、3D効果用）
    var rotationY: Double     // Y軸回転（左右回転、3D効果用）
    var rotationXSpeed: Double  // X軸回転速度
    var rotationYSpeed: Double  // Y軸回転速度
    var width: CGFloat        // 長方形の幅
    var height: CGFloat       // 長方形の高さ
    var opacity: Double = 1.0
    var windForce: Double     // 風の影響（ランダムな横方向の力）
}

// MARK: - ConfettiView

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var animationStartTime: Date?
    @State private var lastTickTime: Date?
    @State private var accumulatedTime: TimeInterval = 0
    @State private var simulationTime: TimeInterval = 0
    @State private var canvasSize: CGSize = .zero
    @State private var displayLinkDriver = DisplayLinkDriver()
    
    // MARK: - Configuration
    
    let particleCount = 150
    let animationDuration: TimeInterval = 3.0
    let fadeOutDuration: TimeInterval = 1.0
    let fixedDeltaTime: TimeInterval = 1.0 / 60.0
    let maxStepsPerTick = 5
    
    // 物理パラメータ
    let gravity: CGFloat = 2500
    let drag: CGFloat = 0.88
    let terminalVelocity: CGFloat = 150
    
    // 色のパレット（canvas-confettiのデフォルト色に近い）
    let colors: [Color] = [
        Color(red: 1.0, green: 0.42, blue: 0.42), // 赤
        Color(red: 1.0, green: 0.82, blue: 0.4),  // オレンジ
        Color(red: 1.0, green: 0.96, blue: 0.4),  // 黄
        Color(red: 0.4, green: 0.96, blue: 0.4),  // 緑
        Color(red: 0.4, green: 0.82, blue: 1.0),  // 青
        Color(red: 0.82, green: 0.4, blue: 1.0),  // 紫
        Color(red: 1.0, green: 0.4, blue: 0.82)   // ピンク
    ]
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for particle in particles {
                    drawParticle(context: context, particle: particle)
                }
            }
            .onAppear {
                canvasSize = geometry.size
                startAnimation()
            }
            .onDisappear {
                stopAnimation()
            }
            .onChange(of: geometry.size) { _, newSize in
                canvasSize = newSize
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Drawing
    
    private func drawParticle(context: GraphicsContext, particle: ConfettiParticle) {
        // 3D効果：Y軸回転に応じてサイズを調整（奥行き効果）
        let depthScale = 0.5 + 0.5 * abs(cos(particle.rotationY))
        let scaledWidth = particle.width * depthScale
        let scaledHeight = particle.height * depthScale
        
        // 長方形を描画
        let rect = CGRect(
            x: particle.position.x - scaledWidth / 2,
            y: particle.position.y - scaledHeight / 2,
            width: scaledWidth,
            height: scaledHeight
        )
        
        var path = Path(rect)
        
        // 3D効果：X軸回転に応じてZ軸回転を適用（ひらひら舞う効果）
        let zRotation = sin(particle.rotationX) * 0.3
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let transform = CGAffineTransform(translationX: center.x, y: center.y)
            .rotated(by: zRotation)
            .translatedBy(x: -center.x, y: -center.y)
        path = path.applying(transform)
        
        // 3D効果：X軸回転に応じて透明度を調整（奥行き感）
        let xRotationOpacity = 0.7 + 0.3 * abs(cos(particle.rotationX))
        var ctx = context
        ctx.opacity = particle.opacity * xRotationOpacity
        
        ctx.fill(path, with: .color(particle.color))
    }
    
    // MARK: - Animation Control
    
    private func startAnimation() {
        let now = Date()
        animationStartTime = now
        lastTickTime = now
        accumulatedTime = 0
        simulationTime = 0
        
        // 画面中央から放出
        let originX = canvasSize.width / 2
        let originY = canvasSize.height * 0.4
        createParticles(origin: CGPoint(x: originX, y: originY))
        
        // DisplayLinkを開始
        displayLinkDriver.start { [self] date in
            tick(at: date)
        }
    }
    
    private func stopAnimation() {
        displayLinkDriver.stop()
        particles.removeAll()
        animationStartTime = nil
        lastTickTime = nil
        accumulatedTime = 0
        simulationTime = 0
    }
    
    // MARK: - Tick (Frame Update)
    
    private func tick(at date: Date) {
        guard animationStartTime != nil else {
            displayLinkDriver.stop()
            return
        }
        
        // アニメーション終了チェック
        if simulationTime >= animationDuration {
            stopAnimation()
            return
        }
        
        // フレーム間隔を計算
        let lastTick = lastTickTime ?? date
        var frameDelta = date.timeIntervalSince(lastTick)
        lastTickTime = date
        
        // 異常値の補正
        if frameDelta.isNaN || frameDelta.isInfinite { frameDelta = 0 }
        frameDelta = max(0, min(frameDelta, 0.25))
        
        accumulatedTime += frameDelta
        
        // 固定タイムステップで物理シミュレーションを実行
        let epsilon: TimeInterval = 1e-6
        let availableSteps = Int((accumulatedTime + epsilon) / fixedDeltaTime)
        guard availableSteps > 0 else { return }
        
        let stepsToRun = min(availableSteps, maxStepsPerTick)
        for _ in 0..<stepsToRun {
            simulationTime += fixedDeltaTime
            stepSimulation(deltaTime: fixedDeltaTime)
        }
        accumulatedTime -= TimeInterval(stepsToRun) * fixedDeltaTime
        
        // フレームドロップが激しい場合はリセット
        if availableSteps > maxStepsPerTick {
            accumulatedTime = 0
        }
    }
    
    // MARK: - Simulation Step
    
    private func stepSimulation(deltaTime: TimeInterval) {
        for i in particles.indices {
            var particle = particles[i]
            
            // 重力を適用
            particle.velocity.dy += gravity * deltaTime
            
            // 終端速度の制限
            if particle.velocity.dy > terminalVelocity {
                particle.velocity.dy = terminalVelocity
            }
            
            // 風の影響を適用（ひらひら舞う効果）
            let windVariation = sin(simulationTime * 3.0 + Double(i) * 0.3) * particle.windForce
            particle.velocity.dx += windVariation * deltaTime
            
            // 空気抵抗を適用
            particle.velocity.dx *= drag
            particle.velocity.dy *= drag
            
            // 位置を更新
            particle.position.x += particle.velocity.dx * deltaTime
            particle.position.y += particle.velocity.dy * deltaTime
            
            // 画面外チェック
            let margin: CGFloat = 150
            let isOffscreen = particle.position.y < -margin
                || particle.position.y > canvasSize.height + margin
                || particle.position.x < -margin
                || particle.position.x > canvasSize.width + margin
            if isOffscreen {
                particle.opacity = 0
                particles[i] = particle
                continue
            }
            
            // 3D回転を更新（ひらひら舞う効果）
            let xRotationFromVelocity = particle.velocity.dy * 0.01
            let xRotationFromWind = windVariation * 0.05
            particle.rotationX += (particle.rotationXSpeed + xRotationFromVelocity + xRotationFromWind) * deltaTime
            
            let yRotationFromVelocity = particle.velocity.dx * 0.008
            let yRotationFromWind = windVariation * 0.03
            particle.rotationY += (particle.rotationYSpeed + yRotationFromVelocity + yRotationFromWind) * deltaTime
            
            // 落下時に回転速度が少し速くなる
            let fallSpeed = abs(particle.velocity.dy)
            if fallSpeed > 10 {
                particle.rotationX += fallSpeed * 0.0005 * deltaTime
                particle.rotationY += fallSpeed * 0.0003 * deltaTime
            }
            
            // フェードアウト
            let fadeStart = animationDuration - fadeOutDuration
            if simulationTime > fadeStart {
                let fadeProgress = (simulationTime - fadeStart) / fadeOutDuration
                particle.opacity = max(0, 1.0 - fadeProgress)
            }
            
            particles[i] = particle
        }
        
        // 透明度が0になったパーティクルを削除
        particles.removeAll { $0.opacity <= 0 }
    }
    
    // MARK: - Particle Creation
    
    private func createParticles(origin: CGPoint) {
        particles = []
        particles.reserveCapacity(particleCount)
        
        for _ in 0..<particleCount {
            // 上方向に偏った角度分布
            let baseAngle = -Double.pi / 2  // -90度（上方向）
            let spread = Double.pi / 3      // ±60度の範囲（ConfettiStandaloneと同じ）
            let angle = baseAngle + Double.random(in: -spread..<spread)
            
            // 初速
            let speed = Double.random(in: 1800...4000)
            let vx = cos(angle) * speed
            let vy = sin(angle) * speed
            
            // 長方形のサイズ
            let baseSize = CGFloat.random(in: 6...14)
            let width = baseSize * CGFloat.random(in: 0.5...2.0)
            let height = baseSize * CGFloat.random(in: 0.4...1.2)
            
            // ランダムな色
            let color = colors.randomElement() ?? .blue
            
            // 3D回転の初期値
            let rotationX = Double.random(in: 0...(2 * .pi))
            let rotationY = Double.random(in: 0...(2 * .pi))
            
            // 回転速度（ConfettiStandaloneの値に合わせる）
            let rotationXSpeed = Double.random(in: 2.0...15.0)
            let rotationYSpeed = Double.random(in: 4.0...20.0)
            
            // 風の影響（ConfettiStandaloneの値に合わせる）
            let windForce = Double.random(in: -600...600)
            
            let particle = ConfettiParticle(
                position: origin,
                velocity: CGVector(dx: vx, dy: vy),
                color: color,
                rotationX: rotationX,
                rotationY: rotationY,
                rotationXSpeed: rotationXSpeed,
                rotationYSpeed: rotationYSpeed,
                width: width,
                height: height,
                windForce: windForce
            )
            
            particles.append(particle)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // 背景（確認しやすくするため）
        LinearGradient(
            colors: [
                Color(red: 0.85, green: 0.95, blue: 1.0),
                Color(red: 0.95, green: 0.90, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        // 紙吹雪アニメーション
        ConfettiView()
    }
    .frame(width: 393, height: 852) // iPhone 15 Proサイズ
}
