// CreateCartPopover.swift
import SwiftUI

struct CreateCartPopover: View {
    @Binding var isPresented: Bool
    let onConfirm: (String, Double) -> Void
    let onCancel: () -> Void
    
    @State private var cartTitle: String = ""
    @State private var budget: String = ""
    @FocusState private var focusedField: Field?
    @State private var showing = false
    
    private enum Field {
        case title, budget
    }
    
    private var budgetValue: Double {
        Double(budget) ?? 0.0
    }
    
    private var canConfirm: Bool {
        !cartTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                titleSection
                budgetSection
                buttonsSection
            }
            .frame(width: UIScreen.main.bounds.width * 0.92)
            .presentationBackground(.clear)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 1)
        .frame(width: UIScreen.main.bounds.width * 1)
        .background(Color.white.opacity(0.01))
        .scaleEffect(showing ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                showing = true
            }
            
            focusedField = .title
        }
        .onTapGesture {
            focusedField = nil
        }
    }

    private var titleSection: some View {
        VStack(spacing: 0) {
            TextField("My Monday Shopping Trip...", text: $cartTitle)
                .lexendFont(20, weight: .semibold)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .focused($focusedField, equals: .title)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .budget
                }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .offset(y: 8)
        }
        .padding(20)
    }
    
    private var budgetSection: some View {
        VStack(spacing: 0) {
            budgetRow
                .padding(.bottom)
        }
        .padding(.horizontal, 20)
    }
    
    private var buttonsSection: some View {
        HStack(spacing: 12) {
            cancelButton
            confirmButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var cancelButton: some View {
        Button(action: {
            focusedField = nil
            
            withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 100, damping: 10, initialVelocity: 0)) {
                showing = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onCancel()
            }
        }) {
            Text("Cancel")
                .fuzzyBubblesFont(16, weight: .bold)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.white)
                .cornerRadius(10)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private var confirmButton: some View {
        FormCompletionButton.createEmptyCartButton(
            isEnabled: canConfirm,
            cornerRadius: 10,
            verticalPadding: 12,
            maxWidth: true
        ) {
            focusedField = nil
            
            withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 100, damping: 10, initialVelocity: 0)) {
                showing = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onConfirm(cartTitle, budgetValue)
            }
        }
    }
    
    private var budgetRow: some View {
        HStack {
            HStack(spacing: 6) {
                Text("Budget")
                Text("(Optional) :")
                    .foregroundStyle(Color(.systemGray))
            }
            .lexendFont(16)

            Spacer()
            
            HStack(spacing: 4) {
                Text("₱")
                    .lexendFont(18, weight: .medium)
                    .foregroundStyle(budget.isEmpty ? .gray : .black)
                
                Text(budget.isEmpty ? "0" : budget)
                    .foregroundStyle(budget.isEmpty ? .gray : .black)
                    .lexendFont(18, weight: .medium)
                    .multilineTextAlignment(.trailing)
                    .overlay(
                        TextField("0", text: $budget)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .fixedSize(horizontal: true, vertical: false)
                            .autocorrectionDisabled(true)
                            .offset(x: 0)
                            .textInputAutocapitalization(.never)
                            .numbersOnly($budget, includeDecimal: true, maxDigits: 10)
                            .lexendFont(18, weight: .medium)
                            .focused($focusedField, equals: .budget)
                            .opacity(focusedField == .budget ? 1 : 0)
                    )
            }
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = .budget
            }
        }
        .padding(.bottom)
    }
}
