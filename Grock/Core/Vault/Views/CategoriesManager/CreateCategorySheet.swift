import SwiftUI
import Observation
import UIKit

struct CreateCategorySheet: View {
    @Bindable var viewModel: CategoriesManagerViewModel
    let onSave: () -> Void
    @FocusState private var isNameFocused: Bool
    @State private var didRequestInitialFocus = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Create New Category")
                    .fuzzyBubblesFont(18, weight: .bold)
                    .foregroundStyle(.black)

                Spacer()

                Button(action: {
                    onSave()
                }) {
                    Text("Save")
                        .lexendFont(14, weight: .bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.popoverCanCreate)
                .opacity(viewModel.popoverCanCreate ? 1 : 0.5)
            }
            .padding(.top)

            // Input Row
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.showEmojiPicker = true
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.selectedColorHex != nil ? Color(hex: viewModel.selectedColorHex!) : Color.clear)

                        if viewModel.selectedColorHex == nil {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        }

                        if !viewModel.newCategoryEmoji.isEmpty {
                            Text(viewModel.newCategoryEmoji)
                                .font(.system(size: 24))
                        } else if let first = viewModel.newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).first {
                            Text(String(first).uppercased())
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.black)
                        } else {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)

                TextField("Category name...", text: $viewModel.newCategoryName)
                    .lexendFont(16, weight: .medium)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .focused($isNameFocused)
                    .submitLabel(.done)
            }

            if let createCategoryError = viewModel.createCategoryError {
                Text(createCategoryError)
                    .lexendFont(12, weight: .medium)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)

            // Content (Color Grid with Pagination)
            TabView {
                let chunks = Array(viewModel.backgroundColors.chunked(into: 14))
                ForEach(0..<chunks.count, id: \.self) { pageIndex in
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
                        ForEach(chunks[pageIndex], id: \.self) { colorHex in
                            Button(action: {
                                viewModel.selectedColorHex = colorHex
                                HapticManager.shared.playButtonTap()
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: colorHex))
                                        .frame(height: 44)

                                    if viewModel.selectedColorHex == colorHex {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.black.opacity(0.6))
                                            .padding(4)
                                            .background(
                                                Circle()
                                                    .fill(.white.opacity(0.4))
                                            )
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                            .padding(2)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 1) // Avoid clipping
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 120)
            .onAppear {
                UIPageControl.appearance().currentPageIndicatorTintColor = .black
                UIPageControl.appearance().pageIndicatorTintColor = .systemGray4
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .background(Color.white)
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 12)
        }
        .onAppear {
            requestInitialFocusIfNeeded()
        }
    }

    private func requestInitialFocusIfNeeded() {
        guard !didRequestInitialFocus else { return }
        didRequestInitialFocus = true
        
        DispatchQueue.main.async {
            isNameFocused = true
        }
    }
}

#Preview {
    CreateCategorySheetPreview()
}

private struct CreateCategorySheetPreview: View {
    @State private var viewModel = CategoriesManagerViewModel(startOnHiddenTab: false)

    var body: some View {
        CreateCategorySheet(
            viewModel: viewModel,
            onSave: {}
        )
        .padding()
        .background(Color(.systemGray6))
    }
}
