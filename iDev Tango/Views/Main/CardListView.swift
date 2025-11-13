//
//  CardListView.swift
//  iDev Tango
//
//  単語一覧画面
//  フォルダ内の単語リストを表示し、編集・削除が可能
//

import SwiftUI
import SwiftData

struct CardListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = CardListViewModel()
    @StateObject private var learningService = LearningService.shared
    
    let deck: Deck
    
    @State private var showingAddCard = false
    @State private var editingCard: Card?
    @State private var editTerm = ""
    @State private var editDefinition = ""
    
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
                if viewModel.cards.isEmpty {
                    Spacer()
                    Text("単語を追加してください")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.cards, id: \.id) { card in
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
                    
                    NavigationLink(destination: LearningView(initialCards: getLearningCards())) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                            Text("学習する")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.cards.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    .disabled(viewModel.cards.isEmpty)
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
                viewModel.fetchCards()
            })
        }
        .sheet(item: $editingCard) { card in
            EditCardView(
                card: card,
                term: $editTerm,
                definition: $editDefinition,
                onSave: {
                    viewModel.updateCard(card, term: editTerm, definition: editDefinition)
                    editingCard = nil
                }
            )
        }
        .onAppear {
            viewModel.setModelContext(modelContext, deck: deck)
        }
    }
    
    private func deleteCards(at offsets: IndexSet) {
        for index in offsets {
            let card = viewModel.cards[index]
            viewModel.deleteCard(card)
        }
    }
    
    // 学習用カードを取得（理解度とランダム性を考慮）
    private func getLearningCards() -> [Card] {
        let cards = learningService.selectCardsForReview(from: deck)
        let maxQuestions = min(10, viewModel.cards.count)
        print("🎓 CardListView: 学習カード取得完了 - \(cards.count)枚 (最大\(maxQuestions)問)")
        return cards
    }
}

// カード行ビュー
struct CardRowView: View {
    let card: Card
    @StateObject private var learningService = LearningService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(card.term)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                // 理解度表示
                Text(learningService.getUnderstandingDisplayName(for: card))
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
