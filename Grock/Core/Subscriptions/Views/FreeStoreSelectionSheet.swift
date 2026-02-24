import SwiftUI

struct FreeStoreSelectionSheet: View {
    @Binding var isPresented: Bool

    @Environment(VaultService.self) private var vaultService

    @State private var availableStores: [String] = []
    @State private var selectedStoreKeys: Set<String> = []
    @State private var showSelectionError = false
    @State private var selectedDetent: PresentationDetent = .medium
    @State private var showPaywall = false

    private var requiredSelectionCount: Int {
        min(2, availableStores.count)
    }

    private var selectedCount: Int {
        selectedStoreKeys.count
    }

    private var selectedStoresInOrder: [String] {
        availableStores.filter { selectedStoreKeys.contains(normalizedStoreKey($0)) }
    }

    private var canConfirm: Bool {
        selectedCount == requiredSelectionCount && requiredSelectionCount > 0
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .center, spacing: 6) {
                    VStack(spacing: 2) {
                        Text("Free Plan includes")
                            .fuzzyBubblesFont(22, weight: .bold)
                            .foregroundStyle(Color.black.opacity(0.92))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)

                        Text("2 active stores 🧺")
                            .fuzzyBubblesFont(22, weight: .bold)
                            .foregroundStyle(Color.black.opacity(0.92))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
  
                    Text("You can keep 2 stores fully editable on Free. All other stores remain saved and view-only.")
                        .lexendFont(13, weight: .light)
                        .foregroundStyle(Color.gray)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                VStack(spacing: 0) {
                    Text("\(selectedCount) / \(requiredSelectionCount)")
                        .lexendFont(13, weight: .bold)
                        .monospacedDigit()
                        .tracking(1.0)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: selectedCount)
                        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: requiredSelectionCount)
                        .foregroundStyle(Color.black.opacity(0.76))
                        .frame(maxWidth: .infinity, alignment: .center)

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(availableStores.enumerated()), id: \.offset) { index, store in
                                let key = normalizedStoreKey(store)
                                let isSelected = selectedStoreKeys.contains(key)
                                let canSelect = isSelected || selectedCount < requiredSelectionCount

                                HStack(spacing: 8) {
                                    Text(store)
                                        .lexend(.body)
                                        .foregroundStyle(canSelect ? .black : .gray)

                                    Spacer()

                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundStyle(isSelected ? Color.green : Color.gray.opacity(0.5))
                                        .scaleEffect(isSelected ? 1.07 : 1.0)
                                        .contentTransition(.symbolEffect(.replace))
                                        .symbolEffect(.bounce, value: isSelected)
                                        .animation(
                                            .interactiveSpring(response: 0.24, dampingFraction: 0.64, blendDuration: 0.08),
                                            value: isSelected
                                        )
                                        .frame(width: 34, height: 34)
                                        .contentShape(Rectangle())
                                }
                                .padding(.horizontal, 8)
                                .frame(minHeight: 48)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    guard canSelect else { return }
                                    toggleStoreSelection(store)
                                }
                                .opacity(canSelect ? 1 : 0.58)

                                if index < availableStores.count - 1 {
                                    DashedLine()
                                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                                        .foregroundStyle(Color.gray.opacity(0.24))
                                        .frame(height: 1)
                                        .padding(.horizontal, 8)
                                }
                            }
                        }
                    }
                    .background(Color.clear)
                    .padding(.horizontal, 6)
                }
                .padding(.top, 4)

                FormCompletionButton(
                    title: "Apply 2 Stores",
                    isEnabled: canConfirm,
                    cornerRadius: 100,
                    verticalPadding: 12,
                    maxRadius: 1000,
                    bounceScale: (0.98, 1.05, 1.0),
                    bounceTiming: (0.1, 0.3, 0.3),
                    maxWidth: true
                ) {
                    guard canConfirm else {
                        showSelectionError = true
                        return
                    }

                    let applied = vaultService.applyFreeStoreSelection(selectedStoresInOrder)
                    if applied {
                        isPresented = vaultService.isFreeStoreSelectionRequired()
                    } else {
                        showSelectionError = true
                    }
                }
                .frame(maxWidth: .infinity)

                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 8) {
                        Text("Need unlimited stores?")
                            .lexendFont(13, weight: .semibold)
                            .foregroundStyle(Color.black.opacity(0.9))
                            .lineLimit(1)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.28), lineWidth: 1)
                            )
                            .overlay(
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.black)
                            )
                    }
                    .padding(.leading, 10)
                    .padding(.trailing, 6)
                    .padding(.vertical, 6)
                    .background(
                        Color(hex: "FFE08A")
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.black.opacity(0.7), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal)
            .padding(.top, 32)
            .alert("Select 2 stores", isPresented: $showSelectionError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Choose exactly 2 stores to continue on Free.")
            }
            .onAppear {
                selectedDetent = .medium
                refreshStoresAndSelection()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DataUpdated"))) { _ in
                refreshStoresAndSelection()
            }
        }
        .background(Color.white.ignoresSafeArea())
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .presentationBackground(Color.white)
        .presentationDetents([.medium, .large], selection: $selectedDetent)
        .fullScreenCover(isPresented: $showPaywall) {
            GrockPaywallView(initialFeatureFocus: .stores) {
                showPaywall = false
            }
        }
    }

    private func normalizedStoreKey(_ storeName: String) -> String {
        storeName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func refreshStoresAndSelection() {
        let stores = vaultService.storesForFreeSelection()
        availableStores = stores
        let requiredCount = min(2, stores.count)

        var keysToSelect = Set(vaultService.preselectedStoresForFreeSelection().map(normalizedStoreKey))
        if keysToSelect.count > requiredCount {
            let limitedKeys = stores
                .map(normalizedStoreKey)
                .filter { keysToSelect.contains($0) }
                .prefix(requiredCount)
            keysToSelect = Set(limitedKeys)
        }
        selectedStoreKeys = keysToSelect
    }

    private func toggleStoreSelection(_ store: String) {
        let key = normalizedStoreKey(store)
        if selectedStoreKeys.contains(key) {
            selectedStoreKeys.remove(key)
            return
        }

        guard selectedStoreKeys.count < requiredSelectionCount else { return }
        selectedStoreKeys.insert(key)
    }
}
