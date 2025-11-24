import SwiftUI

//NOTE: LIMIT TO ONLY 1 store for free users
struct AddStoreSheet: View {
    @Binding var storeName: String
    @Binding var isPresented: Bool
    var onSave: ((String) -> Void)?
    
    @FocusState private var isFocused: Bool
    
    private var isSaveDisabled: Bool {
        storeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Enter store name", text: $storeName)
                    .font(.subheadline)
                    .bold()
                    .normalizedText($storeName)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($isFocused)
                    .onAppear {
                        isFocused = true
                    }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add New Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let trimmedName = storeName.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave?(trimmedName)
                    }
                    .disabled(isSaveDisabled)
                }
            }
        }
    }
}


//#Preview {
//    AddStoreSheet()
//}
