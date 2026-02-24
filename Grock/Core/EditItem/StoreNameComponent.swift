import SwiftUI

struct StoreNameComponent: View {
    @Binding var storeName: String
    @Environment(VaultService.self) private var vaultService
    @FocusState private var isFocused: Bool
    @State private var showAddStoreSheet = false
    @State private var newStoreName = ""
    @State private var showDropdown = false
    @State private var showPaywall = false
    @State private var paywallFeatureFocus: GrockPaywallFeatureFocus?
    let hasError: Bool
    var bypassPlanLocks: Bool = false
    
    var onStoreChange: (() -> Void)?
    
    // Track last selected store across sessions
    @AppStorage("lastSelectedStore") private var lastSelectedStore: String = ""
    
    private var availableStores: [String] {
        vaultService.getAllStores()
    }

    private var editableStores: [String] {
        bypassPlanLocks ? availableStores : availableStores.filter { !vaultService.isStoreLockedByPlan(named: $0) }
    }
    
    //Prioritize last selected store, then most recent
    private var defaultStore: String? {
        // 1. If lastSelectedStore exists and is still valid, use it
        if !lastSelectedStore.isEmpty && editableStores.contains(where: { $0.lowercased() == lastSelectedStore.lowercased() }) {
            return lastSelectedStore
        }
        
        // 2. Otherwise, use most recently added store
        if let recentStore = vaultService.getMostRecentStore(),
           (bypassPlanLocks || !vaultService.isStoreLockedByPlan(named: recentStore)) {
            return recentStore
        }
        
        // 3. Fallback to first editable store
        return editableStores.first
    }
    
    var body: some View {
        HStack {
            Text("Store")
                .font(.footnote)
                .foregroundColor(.gray)
            
            Spacer()
           
            if availableStores.isEmpty || !showDropdown {
                // Text field (stores = 0)
                TextField("Enter store name", text: $storeName)
                    .normalizedText($storeName)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.black)
                    .multilineTextAlignment(.trailing)
                    .focused($isFocused)
            } else {
                // Dropdown (stores >0)
                Menu {
                    Button(action: {
                        guard bypassPlanLocks || !vaultService.isStoreLimitReached() else {
                            presentPaywall(for: .stores)
                            return
                        }
                        newStoreName = ""
                        showAddStoreSheet = true
                    }) {
                        Label("Add New Store", systemImage: "plus.circle.fill")
                    }
                    
                    Divider()
                    
                    ForEach(availableStores, id: \.self) { store in
                        let isLockedStore = !bypassPlanLocks && vaultService.isStoreLockedByPlan(named: store)
                        Button(action: {
                            guard !isLockedStore else {
                                presentPaywall(for: .stores)
                                return
                            }
                            storeName = store
                            // Save the selected store
                            lastSelectedStore = store
                            onStoreChange?()
                        }) {
                            if isLockedStore {
                                Label(store, systemImage: "lock.fill")
                                    .foregroundStyle(.gray)
                            } else if storeName == store {
                                Label(store, systemImage: "checkmark")
                                    .foregroundStyle(.black)
                            } else {
                                Text(store)
                                    .foregroundStyle(.black)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(storeName.isEmpty ? "Select Store" : storeName)
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(storeName.isEmpty ? .gray : .black)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    Color.Grock.accentDanger,
                    lineWidth: hasError ? 2.0 : 0
                )
        )
        .sheet(isPresented: $showAddStoreSheet) {
            AddStoreSheet(
                storeName: $newStoreName,
                isPresented: $showAddStoreSheet,
                onSave: { newStore in
                    let trimmedNewStore = newStore.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedNewStore.isEmpty else { return }

                    guard bypassPlanLocks || vaultService.canUseStoreName(trimmedNewStore) else {
                        showAddStoreSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            presentPaywall(for: .stores)
                        }
                        return
                    }

                    vaultService.addStore(trimmedNewStore)
                    storeName = trimmedNewStore
                    //  Save newly added store as last selected
                    lastSelectedStore = trimmedNewStore
                    showAddStoreSheet = false
                    print("➕ New store added and persisted: \(trimmedNewStore)")
                    onStoreChange?()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showDropdown = true
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showPaywall) {
            GrockPaywallView(initialFeatureFocus: paywallFeatureFocus) {
                paywallFeatureFocus = nil
                showPaywall = false
            }
        }
        .onAppear {
            //  Use defaultStore computed property
            if storeName.isEmpty, let store = defaultStore {
                storeName = store
            } else if !storeName.isEmpty,
                      !bypassPlanLocks && vaultService.isStoreLockedByPlan(named: storeName),
                      let store = defaultStore {
                storeName = store
            }
            
            if !availableStores.isEmpty {
                showDropdown = true
            } else {
                showDropdown = false
            }
        }
        .onChange(of: availableStores) { oldValue, newValue in
            if oldValue.isEmpty && !newValue.isEmpty {
                showDropdown = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showDropdown = true
                }
            } else if !newValue.isEmpty {
                showDropdown = true
            } else {
                showDropdown = false
            }
            
            //  Update to default store when stores change (only if empty)
            if storeName.isEmpty, let store = defaultStore {
                storeName = store
                onStoreChange?()
            } else if !storeName.isEmpty,
                      !bypassPlanLocks && vaultService.isStoreLockedByPlan(named: storeName),
                      let store = defaultStore {
                storeName = store
                onStoreChange?()
            }
        }
        .onChange(of: storeName) { oldValue, newValue in
            //  Update last selected whenever store changes
            if !newValue.isEmpty {
                lastSelectedStore = newValue
            }
            onStoreChange?()
        }
    }

    private func presentPaywall(for featureFocus: GrockPaywallFeatureFocus) {
        guard !bypassPlanLocks else { return }
        paywallFeatureFocus = featureFocus
        showPaywall = true
    }
}
