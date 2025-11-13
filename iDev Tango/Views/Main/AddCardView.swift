//
//  AddCardView.swift
//  iDev Tango
//
//  単語登録画面
//  AI定義生成機能を搭載し、手動入力にも対応
//

import SwiftUI
import SwiftData

struct AddCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiService = AIService.shared
    
    let deck: Deck
    let onCardAdded: () -> Void
    
    @State private var term = ""
    @State private var definition = ""
    @State private var isGenerating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var hasGeneratedDefinition = false
    
    var body: some View {
        NavigationStack {
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
                
                ScrollView {
                    VStack(spacing: 25) {
                        // ユーザー入力カード
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ユーザー入力")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 30)
                            
                            VStack(spacing: 15) {
                                TextField("単語を入力", text: $term)
                                    .font(.title)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                
                                if !term.isEmpty {
                                    if aiService.isAvailable {
                                        Button(action: generateDefinition) {
                                            HStack {
                                                if isGenerating {
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle())
                                                    Text("生成中...")
                                                } else {
                                                    Image(systemName: "sparkles")
                                                    Text("意味を確認")
                                                }
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(15)
                                        }
                                        .disabled(isGenerating)
                                        .padding(.horizontal)
                                    } else {
                                        Text("AI機能は利用できません。下の欄で手動入力してください。")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.white)
                            .cornerRadius(25)
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                            .padding(.horizontal, 30)
                        }
                        .padding(.top, 20)
                        
                        // 意味入力カード
                        VStack(alignment: .leading, spacing: 10) {
                            Text(aiService.isAvailable ? "AI生成" : "意味入力")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 30)
                            
                            VStack(spacing: 15) {
                                if definition.isEmpty && !hasGeneratedDefinition && aiService.isAvailable {
                                    Text("単語を入力後、意味を確認ボタンを押してください")
                                        .font(.body)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                } else {
                                    TextEditor(text: $definition)
                                        .frame(minHeight: 200)
                                        .padding()
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 25)
                                                .stroke(definition.isEmpty ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                                        )
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(25)
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                            .padding(.horizontal, 30)
                        }
                        
                        // 注意書き
                        if hasGeneratedDefinition {
                            Text("AIが生成した意味は間違っている場合があります。")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 30)
                        } else if !aiService.isAvailable {
                            Text("手動で意味を入力してください。")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 30)
                        }
                        
                        Spacer(minLength: 50)
                        
                        // 保存ボタン
                        Button(action: saveCard) {
                            Text("保存する")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(canSave ? Color.blue : Color.gray)
                                .cornerRadius(25)
                        }
                        .disabled(!canSave)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle(deck.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var canSave: Bool {
        !term.isEmpty && !definition.isEmpty
    }
    
    private func generateDefinition() {
        guard !term.isEmpty else { return }
        
        isGenerating = true
        hasGeneratedDefinition = true
        
        Task {
            do {
                let response = try await aiService.fetchDefinition(for: term)
                await MainActor.run {
                    definition = response.definition
                    isGenerating = false
                }
            } catch let error as AIError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isGenerating = false
                    // AI生成失敗時は手動入力を促す
                    definition = ""
                }
            } catch {
                await MainActor.run {
                    errorMessage = "定義の生成に失敗しました"
                    showError = true
                    isGenerating = false
                    definition = ""
                }
            }
        }
    }
    
    private func saveCard() {
        guard canSave else { return }
        
        let newCard = Card(term: term, definition: definition, deck: deck)
        modelContext.insert(newCard)
        
        do {
            try modelContext.save()
            onCardAdded()
            dismiss()
        } catch {
            errorMessage = "カードの保存に失敗しました"
            showError = true
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Deck.self, Card.self, configurations: config)
    let deck = Deck(name: "iOS Swift")
    container.mainContext.insert(deck)
    
    return AddCardView(deck: deck, onCardAdded: {})
        .modelContainer(container)
}
