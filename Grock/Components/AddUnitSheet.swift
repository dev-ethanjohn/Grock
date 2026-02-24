import SwiftUI

struct AddUnitSheet: View {
    @Binding var unitName: String
    @Binding var isPresented: Bool
    var onSave: ((String) -> Void)?

    @FocusState private var isFocused: Bool

    private var isSaveDisabled: Bool {
        unitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Enter unit (e.g. scoop)", text: $unitName)
                    .lexend(.subheadline)
                    .normalizedText($unitName)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
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
            .navigationTitle("Add New Unit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let trimmedName = unitName.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave?(trimmedName)
                    }
                    .disabled(isSaveDisabled)
                }
            }
        }
    }
}
