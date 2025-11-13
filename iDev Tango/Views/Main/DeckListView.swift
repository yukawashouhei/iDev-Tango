//
//  DeckListView.swift
//  iDev Tango
//
//  フォルダ一覧画面（起動画面）
//  グラデーション背景に白い角丸カードでデッキを表示
//

import SwiftUI
import SwiftData

struct DeckListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DeckListViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // グラデーション背景
                LinearGradient(
                    colors: [
                        Color(red: 0.85, green: 0.95, blue: 1.0),  // 淡い青
                        Color(red: 0.95, green: 0.90, blue: 1.0)   // 淡い紫
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // ヘッダー
                    Text("新しいフォルダを作成する")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                    
                    // 新規フォルダ作成ボタン
                    Button(action: {
                        viewModel.showingAddDeck = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.title2)
                            Text("フォルダ名")
                                .font(.title2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.white)
                        .cornerRadius(25)
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    }
                    .accessibilityLabel("新しいフォルダを作成")
                    .accessibilityHint("タップすると新しいフォルダを作成できます")
                    .padding(.horizontal, 30)
                    
                    // デッキリスト
                    if viewModel.decks.isEmpty {
                        Spacer()
                        Text("フォルダを作成してください")
                            .foregroundColor(.gray)
                        Spacer()
                    } else {
                        List {
                            ForEach(viewModel.decks, id: \.id) { deck in
                                ZStack {
                                    NavigationLink(destination: CardListView(deck: deck)) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                    
                                    DeckCardView(deck: deck)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 7.5, leading: 30, bottom: 7.5, trailing: 30))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.deleteDeck(deck)
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .alert("新しいフォルダを作成", isPresented: $viewModel.showingAddDeck) {
                TextField("フォルダ名", text: $viewModel.newDeckName)
                Button("キャンセル", role: .cancel) {
                    viewModel.newDeckName = ""
                }
                Button("作成") {
                    viewModel.addDeck(name: viewModel.newDeckName)
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }
}

// デッキカードビュー
struct DeckCardView: View {
    let deck: Deck
    
    private var wordCount: Int {
        deck.cards.count
    }
    
    private var wordCountText: String {
        wordCount <= 1 ? "word" : "words"
    }
    
    var body: some View {
        HStack {
            Text(deck.name)
                .font(.title2)
                .foregroundColor(.black)
            Spacer()
            Text("\(wordCount) \(wordCountText)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}

#Preview {
    DeckListView()
        .modelContainer(for: [Deck.self, Card.self, ActivityLog.self])
}
