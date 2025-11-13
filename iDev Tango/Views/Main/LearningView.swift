//
//  LearningView.swift
//  iDev Tango
//
//  学習画面
//  カードフリップアニメーションで単語と定義を表示
//

import SwiftUI
import SwiftData

struct LearningView: View {
    let initialCards: [Card] // 初期カード配列
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var learningService = LearningService.shared
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var showCompletion = false
    
    // 学習用の固定カード配列（Stateで保持）
    @State private var cards: [Card] = []
    
    // 「説明できる」を押した回数
    @State private var correctCount = 0
    
    var body: some View {
        ZStack {
            // グラデーション背景
            LinearGradient(
                colors: [
                    Color(red: 0.85, green: 0.95, blue: 1.0),
                    Color(red: 0.95, green: 0.90, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if showCompletion {
                // 完了画面
                let understandingRate = calculateUnderstandingRate()
                CompletionView(
                    understandingRate: understandingRate,
                    onDismiss: {
                        dismiss()
                    }
                )
            } else if !cards.isEmpty {
                VStack(spacing: 30) {
                    // デッキ名とプログレス
                    VStack(spacing: 10) {
                        if let deckName = cards[currentIndex].deck?.name {
                            Text(deckName)
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        
                        Text("\(currentIndex + 1) / \(cards.count)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                        .frame(height: 30)
                    
                    // カードフリップビュー
                    FlipCardView(
                        card: cards[currentIndex],
                        isFlipped: $isFlipped
                    )
                    .padding(.horizontal, 30)
                    .onAppear {
                        let currentCard = cards[currentIndex]
                        print("📱 カード表示: インデックス\(currentIndex), カードID: \(currentCard.id), 単語: \(currentCard.term)")
                        print("📱 カード配列確認: 総数\(cards.count), 現在のインデックス\(currentIndex)")
                    }
                    
                    Spacer()
                    
                    // 理解度ボタン（カードをめくる前）
                    if !isFlipped {
                        HStack(spacing: 20) {
                            Button("説明できない") {
                                updateUnderstanding(isCorrect: false)
                                // カードをフリップして次へボタンを表示
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    isFlipped = true
                                }
                            }
                            .buttonStyle(UnderstandingButtonStyle(isCorrect: false))
                            .accessibilityLabel("説明できない")
                            .accessibilityHint("この単語の意味を説明できない場合にタップしてください")
                            
                            Button("説明できる") {
                                correctCount += 1
                                updateUnderstanding(isCorrect: true)
                                nextCard()
                            }
                            .buttonStyle(UnderstandingButtonStyle(isCorrect: true))
                            .accessibilityLabel("説明できる")
                            .accessibilityHint("この単語の意味を説明できる場合にタップしてください")
                        }
                        .padding(.horizontal, 30)
                    }
                    
                    // 次へボタン（カードをめくった後）
                    if isFlipped {
                        Button(action: nextCard) {
                            HStack {
                                Text("次へ")
                                    .font(.headline)
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(15)
                        }
                        .padding(.horizontal, 30)
                    }
                    
                    Spacer()
                        .frame(height: 50)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // カード配列を固定化（学習中は変更しない）
            cards = initialCards
            correctCount = 0 // カウントをリセット
            print("🎯 学習開始: カード配列を固定化 - \(cards.count)枚")
            for (index, card) in cards.enumerated() {
                print("  \(index): \(card.term) (ID: \(card.id))")
            }
            // 学習セッション開始
            learningService.startLearningSession()
        }
        .onDisappear {
            // 学習セッション終了
            learningService.endLearningSession()
        }
    }
    
    private func updateUnderstanding(isCorrect: Bool) {
        let currentCard = cards[currentIndex]
        print("🎯 理解度更新: インデックス\(currentIndex), カードID: \(currentCard.id), 単語: \(currentCard.term)")
        
        learningService.updateUnderstanding(for: currentCard, isCorrect: isCorrect)
        
        // データベースに保存
        do {
            try modelContext.save()
            print("💾 理解度保存完了: \(currentCard.term)")
        } catch {
            print("❌ 理解度の保存に失敗: \(error)")
        }
    }
    
    private func nextCard() {
        // カードをリセット
        isFlipped = false
        
        print("🔄 次のカードへ: 現在のインデックス\(currentIndex), 総カード数\(cards.count)")
        
        // 次のカードへ
        if currentIndex < cards.count - 1 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentIndex += 1
            }
            print("➡️ インデックス更新: \(currentIndex - 1) → \(currentIndex)")
        } else {
            // 全カード完了
            print("🏁 全カード完了")
            showCompletion = true
        }
    }
    
    // 理解度を計算
    private func calculateUnderstandingRate() -> Int {
        let totalQuestions = cards.count
        guard totalQuestions > 0 else {
            return 0
        }
        
        let rate = Int((Double(correctCount) / Double(totalQuestions)) * 100)
        return min(rate, 100) // 最大100%
    }
}

// カードフリップビュー（Apple公式推奨の方法）
struct FlipCardView: View {
    let card: Card
    @Binding var isFlipped: Bool
    
    var body: some View {
        ZStack {
            // 表面（単語）
            CardFaceView(text: card.term, isLarge: true)
                .opacity(isFlipped ? 0 : 1)
                .onAppear {
                    print("🎴 表面表示: \(card.term) (ID: \(card.id))")
                }
            
            // 裏面（定義）
            CardFaceView(text: card.definition, isLarge: false)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .onAppear {
                    if isFlipped {
                        print("🎴 裏面表示: \(card.term) → \(card.definition) (ID: \(card.id))")
                    }
                }
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
    }
}

// カード面ビュー（横長長方形、固定サイズ）
struct CardFaceView: View {
    let text: String
    let isLarge: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            
            Text(text)
                .font(isLarge ? .system(size: 36, weight: .bold) : .system(size: 16, weight: .medium))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
        }
        .frame(width: 340, height: 200)
    }
}

// 完了画面
struct CompletionView: View {
    let understandingRate: Int
    let onDismiss: () -> Void
    
    private var completionMessage: String {
        CompletionMessageService.shared.getMessage(for: understandingRate)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("学習完了！")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(completionMessage)
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
            
            Button(action: onDismiss) {
                Text("閉じる")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
    }
}

// 理解度ボタンスタイル
struct UnderstandingButtonStyle: ButtonStyle {
    let isCorrect: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isCorrect ? Color.green : Color.red)
            .cornerRadius(15)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    @Previewable @State var previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Deck.self, Card.self, configurations: config)
        let deck = Deck(name: "iOS Swift")
        let card1 = Card(term: "Swift Testing", definition: "Swift Testingは、2024年のWWDCで発表された、XCTestに代わる新しいテストフレームワークです。", deck: deck)
        let card2 = Card(term: "SwiftUI", definition: "SwiftUIは、Appleのプラットフォーム向けの宣言的UIフレームワークです。", deck: deck)
        container.mainContext.insert(deck)
        container.mainContext.insert(card1)
        container.mainContext.insert(card2)
        return container
    }()
    
    NavigationStack {
        LearningView(initialCards: (try? previewContainer.mainContext.fetch(FetchDescriptor<Card>())) ?? [])
            .modelContainer(previewContainer)
    }
}
