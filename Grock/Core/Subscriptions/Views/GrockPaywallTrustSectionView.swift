import SwiftUI

struct GrockPaywallTrustSectionView: View {
    @State private var expandedQuestionID: String?

    private let faqs: [FAQItem] = [
        .init(
            id: "charged",
            question: "When will I be charged?",
            answer: "You are charged at the end of your free trial period shown above."
        ),
        .init(
            id: "cancel",
            question: "How do I cancel?",
            answer: "Open App Store > your profile > Subscriptions > Grock Pro, then tap Cancel Trial."
        ),
        .init(
            id: "during-trial",
            question: "What happens if I cancel during trial?",
            answer: "Your Pro access stays active until the trial ends, and you are not charged."
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            reassuranceRow
            faqCard
        }
    }

    private var reassuranceRow: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.Grock.budgetSafe)

            Text("No charge today • Cancel anytime • Reminder before billing")
                .lexend(.caption, weight: .medium)
                .foregroundStyle(.black.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var faqCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Mini FAQ")
                .lexend(.subheadline, weight: .semibold)
                .foregroundStyle(.black)
                .padding(.bottom, 8)

            ForEach(Array(faqs.enumerated()), id: \.element.id) { index, faq in
                FAQRow(
                    item: faq,
                    isExpanded: expandedQuestionID == faq.id,
                    onToggle: { toggleFAQ(faq.id) }
                )

                if index < faqs.count - 1 {
                    Divider()
                        .overlay(Color.black.opacity(0.06))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.90))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private func toggleFAQ(_ id: String) {
        withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
            if expandedQuestionID == id {
                expandedQuestionID = nil
            } else {
                expandedQuestionID = id
            }
        }
    }
}

private struct FAQItem: Hashable {
    let id: String
    let question: String
    let answer: String
}

private struct FAQRow: View {
    let item: FAQItem
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(alignment: .top, spacing: 10) {
                    Text(item.question)
                        .lexend(.footnote, weight: .medium)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.60))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(item.answer)
                    .lexend(.caption)
                    .foregroundStyle(.black.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

#Preview {
    GrockPaywallTrustSectionView()
        .padding()
        .background(Color.Grock.surfaceMuted)
}
