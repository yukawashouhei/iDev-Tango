//
//  CardListView.swift
//  iDev Tango
//
//  単語一覧画面
//  フォルダ内の単語リストを表示し、編集・削除が可能
//  SwiftDataの@Queryを使用した最新実装
//

import SwiftUI
import SwiftData
import StoreKit
import os.log

struct CardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) var requestReview
    @StateObject private var learningService = LearningService.shared
    
    let deck: Deck
    
    // SwiftDataの@Queryを使用（最新推奨方法）
    // データベースの変更を自動的に監視してUIを更新
    @Query private var cards: [Card]
    
    @State private var showingAddCard = false
    @State private var editingCard: Card?
    @State private var editTerm = ""
    @State private var editDefinition = ""
    
    // 学習カード準備用の状態
    @State private var isLoadingLearningCards = false
    @State private var preparedLearningCards: [Card] = []
    @State private var showLearningView = false
    
    // レビューリクエスト管理用のState（UserDefaultsから遅延読み込み）
    @State private var reviewRequestCount = 0
    @State private var lastReviewRequestDate: TimeInterval = 0
    
    // ログ用のサブ™™システム
    private let logger = Logger(subsystem: "com.idevtango", category: "CardListView")
    
    // カスタムイニシャライザで@Queryを初期化
    init(deck: Deck) {
        self.deck = deck
        
        // デッキ名でフィルタリングした@Queryを初期化
        let deckName = deck.name
        _cards = Query(
            filter: #Predicate<Card> { card in
                (card.deck?.name ?? "") == deckName
            },
            sort: [SortDescriptor<Card>(\.createdAt, order: .forward)]
        )
    }
    
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
            
            VStack(spacing: 0) {
                if cards.isEmpty {
                    Spacer()
                    Text("単語を追加してください")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(cards, id: \.id) { card in
                            CardRowView(card: card)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .onTapGesture {
                                    editingCard = card
                                    editTerm = card.term
                                    editDefinition = card.definition
                                }
                        }
                        .onDelete(perform: deleteCards)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                
                // 下部ボタン
                HStack(spacing: 15) {
                    Button(action: {
                        showingAddCard = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("追加")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    
                    Button(action: {
                        Task {
                            await prepareLearningCards()
                        }
                    }) {
                        HStack {
                            if isLoadingLearningCards {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "brain.head.profile")
                            }
                            Text(isLoadingLearningCards ? "準備中..." : "学習する")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(cards.isEmpty || isLoadingLearningCards ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    .disabled(cards.isEmpty || isLoadingLearningCards)
                    .navigationDestination(isPresented: $showLearningView) {
                        LearningView(cards: preparedLearningCards)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(Color.white.opacity(0.95))
            }
        }
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddCard) {
            AddCardView(deck: deck, onCardAdded: {
                logger.info("✅ カードが追加されました")
            })
        }
        .sheet(item: $editingCard) { card in
            EditCardView(
                card: card,
                term: $editTerm,
                definition: $editDefinition,
                onSave: {
                    updateCard(card, term: editTerm, definition: editDefinition)
                    editingCard = nil
                }
            )
        }
        .onAppear {
            logger.info("📋 CardListView表示: デッキ名=\(deck.name), カード数=\(cards.count)")
            
            // レビューリクエストの状態を非同期で読み込む
            Task {
                await loadReviewRequestState()
                
                // 画面遷移のアニメーションが完了するまで待機（0.5秒）
                // これにより、アニメーションとレビューダイアログの表示が競合することを防ぐ
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                // レビューリクエストが必要かチェック
                await checkAndRequestReviewIfNeeded()
            }
        }
    }
    
    private func deleteCards(at offsets: IndexSet) {
        for index in offsets {
            let card = cards[index]
            deleteCard(card)
        }
    }
    
    private func deleteCard(_ card: Card) {
        modelContext.delete(card)
        do {
            try modelContext.save()
            logger.info("🗑️ カードを削除: \(card.term)")
        } catch {
            logger.error("❌ カードの削除に失敗: \(error.localizedDescription)")
        }
    }
    
    private func updateCard(_ card: Card, term: String, definition: String) {
        card.term = term
        card.definition = definition
        do {
            try modelContext.save()
            logger.info("🔄 カードを更新: \(term)")
        } catch {
            logger.error("❌ カードの更新に失敗: \(error.localizedDescription)")
        }
    }
    
    // 学習用カードを非同期で準備（理解度とランダム性を考慮）
    // @Queryで取得したcardsを使用（パフォーマンス最適化）
    private func prepareLearningCards() async {
        guard !cards.isEmpty else { return }
        
        isLoadingLearningCards = true
        
        // LearningServiceは@MainActorなので、メインスレッドで実行
        // ただし、重い処理を非同期で実行するために、Task.detachedでIDのみを処理し、
        // その後メインスレッドでCardオブジェクトを再取得する方法も可能だが、
        // 現在の実装では直接呼び出す方がシンプルで安全
        let selectedCards = learningService.selectCardsForReview(from: cards)
        
        // UIを更新
        preparedLearningCards = selectedCards
        isLoadingLearningCards = false
        showLearningView = true
        logger.info("🎓 学習カード取得完了 - \(selectedCards.count)枚")
    }
    
    // レビューリクエストの状態をUserDefaultsから読み込む（非同期）
    @MainActor
    private func loadReviewRequestState() async {
        // バックグラウンドスレッドでUserDefaultsにアクセス
        let count = await Task.detached {
            UserDefaults.standard.integer(forKey: "reviewRequestCount")
        }.value
        
        let date = await Task.detached {
            UserDefaults.standard.double(forKey: "lastReviewRequestDate")
        }.value
        
        // メインスレッドでStateを更新
        reviewRequestCount = count
        lastReviewRequestDate = date
    }
    
    // レビューリクエストの状態をUserDefaultsに保存（非同期）
    @MainActor
    private func saveReviewRequestState(count: Int, date: TimeInterval) async {
        await Task.detached {
            UserDefaults.standard.set(count, forKey: "reviewRequestCount")
            UserDefaults.standard.set(date, forKey: "lastReviewRequestDate")
        }.value
    }
    
    // レビューリクエストが必要かチェックして実行（非同期）
    @MainActor
    private func checkAndRequestReviewIfNeeded() async {
        // レビューリクエストが必要かチェック
        let reviewNeeded = await Task.detached {
            UserDefaults.standard.bool(forKey: "reviewRequestNeeded")
        }.value
        
        guard reviewNeeded else { return }
        
        // フラグをリセット
        await Task.detached {
            UserDefaults.standard.set(false, forKey: "reviewRequestNeeded")
        }.value
        
        // 日付計算を最適化（一度だけ計算）
        let now = Date().timeIntervalSince1970
        let lastRequestDate = lastReviewRequestDate > 0 ? Date(timeIntervalSince1970: lastReviewRequestDate) : Date.distantPast
        let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 365
        
        // 365日以内のリクエスト回数をチェック
        if lastReviewRequestDate == 0 || daysSinceLastRequest >= 365 {
            // 1年経過した場合はカウントをリセット
            reviewRequestCount = 0
        }
        
        // 365日以内に3回未満の場合のみリクエスト
        guard reviewRequestCount < 3 else {
            logger.info("🚫 レビューリクエスト上限到達: 365日以内に3回リクエスト済み")
            return
        }
        
        // 最後のリクエストから少なくとも90日経過しているか、初回の場合
        guard lastReviewRequestDate == 0 || daysSinceLastRequest >= 90 else {
            logger.info("⏳ レビューリクエスト待機中: 最後のリクエストから\(daysSinceLastRequest)日経過（90日必要）")
            return
        }
        
        // レビューリクエストを実行
        requestReview()
        reviewRequestCount += 1
        lastReviewRequestDate = now
        
        // 状態を非同期で保存
        await saveReviewRequestState(count: reviewRequestCount, date: lastReviewRequestDate)
        
        logger.info("⭐ レビューリクエスト: 回数=\(reviewRequestCount)")
    }
}

// カード行ビュー
struct CardRowView: View {
    let card: Card
    
    // 理解度表示名を直接計算（learningServiceの呼び出しを削減）
    private var understandingDisplayName: String {
        let level = UnderstandingLevel(rawValue: card.understandingLevel) ?? .new
        return level.displayName
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(card.term)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                // 理解度表示
                Text(understandingDisplayName)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(getUnderstandingColor())
                    .cornerRadius(8)
            }
            
            Text(card.definition)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
            
            // 学習回数のみ表示
            HStack {
                Text("学習回数: \(card.reviewCount)")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
    }
    
    private func getUnderstandingColor() -> Color {
        let level = UnderstandingLevel(rawValue: card.understandingLevel) ?? .new
        switch level {
        case .new: return .red
        case .difficult: return .orange
        case .learning: return .yellow
        case .familiar: return .blue
        case .mastered: return .green
        case .expert: return .purple
        }
    }
}

// カード編集ビュー
struct EditCardView: View {
    let card: Card
    @Binding var term: String
    @Binding var definition: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.85, green: 0.95, blue: 1.0),
                        Color(red: 0.95, green: 0.90, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // 単語入力
                    VStack(alignment: .leading, spacing: 10) {
                        Text("単語")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        TextField("単語を入力", text: $term)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 30)
                    
                    // 定義入力
                    VStack(alignment: .leading, spacing: 10) {
                        Text("定義")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        TextEditor(text: $definition)
                            .frame(height: 200)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // 保存ボタン
                    Button(action: {
                        onSave()
                        dismiss()
                    }) {
                        Text("保存する")
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
                .padding(.top, 20)
            }
            .navigationTitle("カードを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Deck.self, Card.self, configurations: config)
    let deck = Deck(name: "iOS Swift")
    container.mainContext.insert(deck)
    
    return NavigationStack {
        CardListView(deck: deck)
            .modelContainer(container)
    }
}
