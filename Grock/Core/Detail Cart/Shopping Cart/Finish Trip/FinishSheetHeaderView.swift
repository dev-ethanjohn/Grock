import SwiftUI

struct FinishSheetHeaderView: View {
    let headerSummaryText: String
    let cart: Cart
    let cartBudget: Double
    let cartTotal: Double
    let totalSpent: Double
    
    var body: some View {
        VStack(spacing: 10) {
            Text(headerSummaryText)
                .fuzzyBubblesFont(18, weight: .bold)
                .foregroundColor(Color(hex: "231F30"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 44)
                .padding(.top, 24)
                .padding(.bottom, 12)
            
            BudgetCartFulfillmentGauge(
                budget: cartBudget,
                cartTotal: cartTotal,
                fulfilledTotal: totalSpent
            )
            .padding(.top, 12)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .padding(.top, 20)
    }
}

private struct BudgetCartFulfillmentGauge: View {
    let budget: Double
    let cartTotal: Double
    let fulfilledTotal: Double
    
    @State private var isShowingSpent: Bool = true
    
    private var hasBudget: Bool { budget > 0 }
    
    private var denominator: Double {
        if hasBudget { return budget }
        return max(cartTotal, fulfilledTotal, 1)
    }
    
    private var fulfilledRatio: Double {
        guard denominator > 0 else { return 0 }
        return fulfilledTotal / denominator
    }
    
    private var cartRatio: Double {
        guard denominator > 0 else { return 0 }
        return cartTotal / denominator
    }
    
    private var fulfilledArcColor: Color {
        spentProgressColor
    }
    
    private var remainingBudget: Double {
        budget - fulfilledTotal
    }
    
    private var isOverBudget: Bool {
        remainingBudget < 0
    }
    
    private var primaryLabelText: String {
        guard hasBudget, !isShowingSpent else { return "Spent" }
        return isOverBudget ? "Over" : "Unspent"
    }
    
    private var primaryAmountText: String {
        if hasBudget, !isShowingSpent {
            return abs(remainingBudget).formattedCurrency
        }
        return fulfilledTotal.formattedCurrency
    }

    private var accessibilitySummaryValue: String {
        if hasBudget {
            let remainingSummary: String
            if isOverBudget {
                remainingSummary = "\(abs(remainingBudget).formattedCurrency) over budget"
            } else {
                remainingSummary = "\(remainingBudget.formattedCurrency) unspent"
            }
            return "\(budget.formattedCurrency) budget, \(cartTotal.formattedCurrency) cart, \(fulfilledTotal.formattedCurrency) spent, \(remainingSummary)"
        }
        return "\(cartTotal.formattedCurrency) cart, \(fulfilledTotal.formattedCurrency) spent"
    }
    
    private var cartProgressColor: Color {
        let progress = max(0, min(cartRatio, 1))
        if progress < 0.7 {
            return Color(hex: "98F476")
        } else if progress < 0.9 {
            return Color(hex: "F4B576")
        } else {
            return Color(hex: "F47676")
        }
    }

    private var spentProgressColor: Color {
        guard hasBudget else { return Color(hex: "231F30") }
        let ratio = fulfilledRatio
        if ratio < 0.7 {
            return Color(hex: "98F476")
        } else if ratio < 0.9 {
            return Color(hex: "F4B576")
        } else {
            return Color(hex: "F47676")
        }
    }
    
    var body: some View {
        let canTogglePrimaryMetric = hasBudget
        let togglePrimaryMetric = {
            guard canTogglePrimaryMetric else { return }
            withAnimation(.snappy(duration: 0.2)) {
                isShowingSpent.toggle()
            }
        }
        
        let gaugeSize: CGFloat = max(200, min(UIScreen.main.bounds.width - 140, 260))
        let outerLineWidth: CGFloat = max(14, gaugeSize * 0.055)
        let innerLineWidth: CGFloat = max(10, gaugeSize * 0.04)
        let innerInset: CGFloat = max(10, outerLineWidth * 0.75)
        let spentRingInset: CGFloat = innerInset + max(4, outerLineWidth * 0.18)
        let visibleHeightRatio: CGFloat = 0.62
        let strokeAllowance: CGFloat = max(outerLineWidth, innerLineWidth)
        let clipInset: CGFloat = 2
        let visibleHeight: CGFloat = gaugeSize * visibleHeightRatio + strokeAllowance * 0.5 + clipInset
        let spentValueFrame: CGFloat = max(0, gaugeSize - 2 * (spentRingInset + innerLineWidth + 8))
        let tickRadius: CGFloat = gaugeSize / 2
        let tickThickness: CGFloat = 2
        let tickGap: CGFloat = 3
        let tickArcLength: CGFloat = CGFloat.pi * tickRadius
        let tickCount: Int = Int((tickArcLength / (tickThickness + tickGap)).rounded()) + 1
        let tickWidth: CGFloat = tickThickness
        let tickHeight: CGFloat = outerLineWidth
        let ringTrackColor: Color = Color(hex: "E6E6E6")
        
        VStack(spacing: 0) {
            ZStack {
                HalfCircleTickRing(
                    progress: 1,
                    filledColor: ringTrackColor,
                    unfilledColor: ringTrackColor,
                    tickCount: tickCount,
                    tickWidth: tickWidth,
                    tickHeight: tickHeight,
                    radius: tickRadius
                )
                
                HalfCircleTickRing(
                    progress: min(cartRatio, 1),
                    filledColor: cartProgressColor,
                    unfilledColor: .clear,
                    tickCount: tickCount,
                    tickWidth: tickWidth,
                    tickHeight: tickHeight,
                    radius: tickRadius
                )
                
                HalfCircleRing(
                    progress: min(fulfilledRatio, 1),
                    color: fulfilledArcColor,
                    lineWidth: innerLineWidth
                )
                .padding(spentRingInset)
                
                VStack(spacing: 4) {
                    Text(primaryLabelText)
                        .lexendFont(16, weight: .medium)
                        .foregroundStyle(Color(hex: "666"))
                        .contentTransition(.opacity)
                        .frame(width: spentValueFrame)
                        .offset(y: gaugeSize * 0.02)
                    
                    Text(primaryAmountText)
                        .lexendFont(30, weight: .bold)
                        .foregroundStyle(isShowingSpent ? .black : spentProgressColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .allowsTightening(true)
                        .contentTransition(.numericText())
                        .frame(width: spentValueFrame)
                        .offset(y: gaugeSize * 0.02)
                }
                .offset(y: -gaugeSize * 0.12)
            }
            .frame(width: gaugeSize, height: gaugeSize)
            .padding(strokeAllowance / 2 + clipInset)
            .frame(height: visibleHeight, alignment: .top)
            .clipped()
            .overlay {
                GeometryReader { proxy in
                    let springOuterRadius = tickRadius + tickHeight / 2
                    let labelStartAngle: Double = -90
                    let labelFontSize: CGFloat = 11
                    let labelRadius: CGFloat = springOuterRadius + 14
                    let labelArcLengthPerCharacter: CGFloat = labelFontSize * 0.62
                    let labelAngleStep: Double = Double(labelArcLengthPerCharacter / labelRadius) * 180 / .pi
                    let center = CGPoint(
                        x: proxy.size.width / 2,
                        y: (strokeAllowance / 2 + clipInset) + (gaugeSize / 2)
                    )
                    
                    ZStack {
                        ArcText(
                            text: "Cart Value:  \(cartTotal.formattedCurrency)",
                            radius: labelRadius,
                            startAngle: labelStartAngle,
                            angleStep: labelAngleStep,
                            fontSize: labelFontSize,
                            weight: .medium,
                            color: Color(hex: "231F30").opacity(0.75)
                        )
                        .position(center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: togglePrimaryMetric)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Budget summary")
            .accessibilityValue(accessibilitySummaryValue)
            .accessibilityHint(canTogglePrimaryMetric ? "Double-tap to toggle between spent and unspent." : "")
            .accessibilityAddTraits(canTogglePrimaryMetric ? .isButton : [])
            .accessibilityAction { togglePrimaryMetric() }
        }
    }
}

private struct ArcText: View {
    let text: String
    let radius: CGFloat
    let startAngle: Double
    let angleStep: Double
    let fontSize: CGFloat
    let weight: Font.Weight
    let color: Color
    
    var body: some View {
        let characters = Array(text)
        let angles = characterAngles(for: characters)
        
        ZStack {
            ForEach(characters.indices, id: \.self) { index in
                Text(String(characters[index]))
                    .lexendFont(fontSize, weight: weight)
                    .foregroundStyle(color)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(angles[index]))
            }
        }
        .frame(width: radius * 2, height: radius * 2)
        .accessibilityHidden(true)
    }
    
    private func characterAngles(for characters: [Character]) -> [Double] {
        let maxEndAngle: Double = 90
        let weights: [Double] = characters.map { $0 == " " ? 0.55 : 1 }
        let weightSum = weights.dropLast().reduce(0.0, +)
        let maxStep = weightSum > 0 ? (maxEndAngle - startAngle) / weightSum : angleStep
        let step = max(0, min(angleStep, maxStep))
        
        var currentAngle = startAngle
        return weights.map { weight in
            let angle = currentAngle
            currentAngle += step * weight
            return angle
        }
    }
}

private struct HalfCircleRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    
    var body: some View {
        Circle()
            .trim(from: 0, to: max(0, min(progress, 1)) * 0.5)
            .stroke(
                color,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            )
            .rotationEffect(.degrees(180))
    }
}

private struct HalfCircleTickRing: View {
    let progress: Double
    let filledColor: Color
    let unfilledColor: Color
    let tickCount: Int
    let tickWidth: CGFloat
    let tickHeight: CGFloat
    let radius: CGFloat
    var startAngle: Double = -90
    var endAngle: Double = 90
    
    var body: some View {
        let clampedProgress = max(0, min(progress, 1))
        let rawFilledCount = clampedProgress * Double(tickCount)
        let filledCount = Int(rawFilledCount.rounded(.down))
        let remainder = rawFilledCount - Double(filledCount)
        let denominator = max(tickCount - 1, 1)
        
        ZStack {
            ForEach(0..<tickCount, id: \.self) { index in
                let position = Double(index) / Double(denominator)
                let angle = startAngle + position * (endAngle - startAngle)
                
                let (tickColor, tickOpacity): (Color, Double) = {
                    if index < filledCount {
                        return (filledColor, 1)
                    }
                    if index == filledCount, remainder > 0 {
                        return (filledColor, remainder)
                    }
                    return (unfilledColor, 1)
                }()
                
                Capsule(style: .continuous)
                    .fill(tickColor)
                    .opacity(tickOpacity)
                    .frame(width: tickWidth, height: tickHeight)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(angle))
            }
        }
    }
}

#Preview("FinishSheetHeaderView") {
    let previewCart = Cart(name: "Preview Trip", budget: 200)
    return FinishSheetHeaderView(
        headerSummaryText: "You set a $200 plan, and this trip stayed comfortably within it.",
        cart: previewCart,
        cartBudget: 200,
        cartTotal: 140,
        totalSpent: 80
    )
    .padding()
    .background(Color.white)
}
