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
    @State private var displayedCartRatio: Double = 0
    @State private var displayedFulfilledRatio: Double = 0
    @State private var hasAnimatedIn: Bool = false
    @State private var showCartValueLabel: Bool = false
    @State private var labelRevealTask: DispatchWorkItem?
    @State private var displayedPrimaryAmount: Double = 0
    @State private var showSpentValueLabel: Bool = false
    
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

    private var targetCartRatio: Double {
        min(max(cartRatio, 0), 1)
    }

    private var targetFulfilledRatio: Double {
        min(max(fulfilledRatio, 0), 1)
    }

    private var springAnimation: Animation {
        .spring(response: 0.6, dampingFraction: 0.8)
    }

    private var labelRevealDelay: Double {
        0.6
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

    private var primaryAmountValue: Double {
        if hasBudget, !isShowingSpent {
            return abs(remainingBudget)
        }
        return fulfilledTotal
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
                    progress: displayedCartRatio,
                    filledColor: cartProgressColor,
                    unfilledColor: .clear,
                    tickCount: tickCount,
                    tickWidth: tickWidth,
                    tickHeight: tickHeight,
                    radius: tickRadius
                )
                
                HalfCircleRing(
                    progress: displayedFulfilledRatio,
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
                        .opacity(showSpentValueLabel ? 1 : 0)
                        .scaleEffect(showSpentValueLabel ? 1 : 0.96)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showSpentValueLabel)
                    
                    Text(displayedPrimaryAmount.formattedCurrency)
                        .lexendFont(30, weight: .bold)
                        .foregroundStyle(isShowingSpent ? .black : spentProgressColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .allowsTightening(true)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: displayedPrimaryAmount)
                        .frame(width: spentValueFrame)
                        .offset(y: gaugeSize * 0.02)
                        .opacity(showSpentValueLabel ? 1 : 0)
                        .scaleEffect(showSpentValueLabel ? 1 : 0.96)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showSpentValueLabel)
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
                    let labelEndAngle: Double = -90 + (min(cartRatio, 1) * 180)
                    let labelFontSize: CGFloat = 12
                    let valueFontSize: CGFloat = 14
                    let labelRadius: CGFloat = springOuterRadius + 14
                    let labelArcLengthPerCharacter: CGFloat = labelFontSize * 0.62
                    let labelAngleStep: Double = Double(labelArcLengthPerCharacter / labelRadius) * 180 / .pi
                    let labelText = "Cart Value:  \(cartTotal.formattedCurrencySpaced)"
                    let valueText = cartTotal.formattedCurrencySpaced
                    let highlightRange: Range<Int>? = {
                        guard let range = labelText.range(of: valueText, options: .backwards) else { return nil }
                        let start = labelText.distance(from: labelText.startIndex, to: range.lowerBound)
                        let end = labelText.distance(from: labelText.startIndex, to: range.upperBound)
                        return start..<end
                    }()
                    let center = CGPoint(
                        x: proxy.size.width / 2,
                        y: (strokeAllowance / 2 + clipInset) + (gaugeSize / 2)
                    )
                    
                    ZStack {
                        ArcText(
                            text: labelText,
                            radius: labelRadius,
                            startAngle: -90,
                            endAngle: labelEndAngle,
                            angleStep: labelAngleStep,
                            baseFontSize: labelFontSize,
                            baseWeight: .medium,
                            baseColor: Color(hex: "231F30").opacity(0.65),
                            highlightRange: highlightRange,
                            highlightFontSize: valueFontSize,
                            highlightWeight: .semibold,
                            highlightColor: Color(hex: "231F30").opacity(0.85),
                            revealTrigger: showCartValueLabel,
                            revealDelay: 0
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
            .onAppear {
                if !hasAnimatedIn {
                    hasAnimatedIn = true
                    displayedCartRatio = 0
                    displayedFulfilledRatio = 0
                    animateToTargets()
                } else {
                    displayedCartRatio = targetCartRatio
                    displayedFulfilledRatio = targetFulfilledRatio
                    showCartValueLabel = true
                    displayedPrimaryAmount = primaryAmountValue
                    showSpentValueLabel = true
                }
            }
            .onChange(of: budget) { _, _ in
                animateToTargets()
            }
            .onChange(of: cartTotal) { _, _ in
                animateToTargets()
            }
            .onChange(of: fulfilledTotal) { _, _ in
                animateToTargets()
            }
            .onChange(of: primaryAmountValue) { _, newValue in
                animatePrimaryAmount(to: newValue)
            }
        }
    }

    private func animateToTargets() {
        scheduleLabelReveal()
        withAnimation(springAnimation) {
            displayedCartRatio = targetCartRatio
            displayedFulfilledRatio = targetFulfilledRatio
        }
        animatePrimaryAmount(to: primaryAmountValue, delay: labelRevealDelay)
    }

    private func scheduleLabelReveal() {
        showCartValueLabel = false
        showSpentValueLabel = false
        labelRevealTask?.cancel()
        let task = DispatchWorkItem {
            showCartValueLabel = true
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showSpentValueLabel = true
            }
        }
        labelRevealTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + labelRevealDelay, execute: task)
    }

    private func animatePrimaryAmount(to value: Double, delay: Double = 0) {
        let task = DispatchWorkItem {
            withAnimation(.interpolatingSpring(stiffness: 220, damping: 22)) {
                displayedPrimaryAmount = value
            }
        }
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
        } else {
            task.perform()
        }
    }
}

private struct ArcText: View {
    let text: String
    let radius: CGFloat
    let startAngle: Double
    let endAngle: Double
    let angleStep: Double
    let baseFontSize: CGFloat
    let baseWeight: Font.Weight
    let baseColor: Color
    let highlightRange: Range<Int>?
    let highlightFontSize: CGFloat
    let highlightWeight: Font.Weight
    let highlightColor: Color
    let revealTrigger: Bool
    let revealDelay: Double

    @State private var revealedCharacters: Int = 0
    @State private var didAppear = false

    init(
        text: String,
        radius: CGFloat,
        startAngle: Double,
        endAngle: Double,
        angleStep: Double,
        baseFontSize: CGFloat,
        baseWeight: Font.Weight,
        baseColor: Color,
        highlightRange: Range<Int>? = nil,
        highlightFontSize: CGFloat? = nil,
        highlightWeight: Font.Weight? = nil,
        highlightColor: Color? = nil,
        revealTrigger: Bool = true,
        revealDelay: Double = 0
    ) {
        self.text = text
        self.radius = radius
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.angleStep = angleStep
        self.baseFontSize = baseFontSize
        self.baseWeight = baseWeight
        self.baseColor = baseColor
        self.highlightRange = highlightRange
        self.highlightFontSize = highlightFontSize ?? baseFontSize
        self.highlightWeight = highlightWeight ?? baseWeight
        self.highlightColor = highlightColor ?? baseColor
        self.revealTrigger = revealTrigger
        self.revealDelay = revealDelay
    }
    
    var body: some View {
        let characters = Array(text)
        let angles = characterAngles(for: characters)
        
        ZStack {
            ForEach(characters.indices, id: \.self) { index in
                let style = styleForIndex(index)
                Text(String(characters[index]))
                    .lexendFont(style.fontSize, weight: style.weight)
                    .foregroundStyle(style.color)
                    .opacity(index < revealedCharacters ? 1 : 0)
                    .offset(y: index < revealedCharacters ? -radius : -radius + 4)
                    .rotationEffect(.degrees(angles[index]))
                    .animation(
                        revealAnimation(for: index),
                        value: revealedCharacters
                    )
            }
        }
        .frame(width: radius * 2, height: radius * 2)
        .accessibilityHidden(true)
        .onAppear {
            guard !didAppear else { return }
            didAppear = true
            if revealTrigger {
                startReveal()
            }
        }
        .onChange(of: revealTrigger) { _, newValue in
            if newValue {
                startReveal()
            } else {
                revealedCharacters = 0
            }
        }
        .onChange(of: text) { _, _ in
            if revealTrigger {
                startReveal()
            }
        }
    }

    private func characterAngles(for characters: [Character]) -> [Double] {
        let weights: [Double] = characters.enumerated().map { index, char in
            let base = char == " " ? 0.55 : 1.0
            let sizeScale = Double(styleForIndex(index).fontSize / baseFontSize)
            return base * sizeScale
        }
        let weightSum = weights.dropLast().reduce(0.0, +)

        guard weightSum > 0 else {
            return characters.map { _ in startAngle }
        }

        let desiredStart = endAngle - (angleStep * weightSum)
        let resolvedStart = max(startAngle, desiredStart)
        let maxStep = (endAngle - resolvedStart) / weightSum
        let finalStep = max(0, min(angleStep, maxStep))
        
        var currentAngle = resolvedStart
        return weights.map { weight in
            let angle = currentAngle
            currentAngle += finalStep * weight
            return angle
        }
    }

    private func styleForIndex(_ index: Int) -> (fontSize: CGFloat, weight: Font.Weight, color: Color) {
        if let highlightRange, highlightRange.contains(index) {
            return (highlightFontSize, highlightWeight, highlightColor)
        }
        return (baseFontSize, baseWeight, baseColor)
    }

    private func revealAnimation(for index: Int) -> Animation {
        Animation.interpolatingSpring(stiffness: 240, damping: 14)
            .delay(Double(index) * 0.01 + revealDelay)
    }

    private func startReveal() {
        revealedCharacters = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + revealDelay) {
            withAnimation(.easeOut(duration: 0.32)) {
                revealedCharacters = text.count
            }
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

private struct HalfCircleTickRing: View, Animatable {
    var progress: Double
    let filledColor: Color
    let unfilledColor: Color
    let tickCount: Int
    let tickWidth: CGFloat
    let tickHeight: CGFloat
    let radius: CGFloat
    var startAngle: Double = -90
    var endAngle: Double = 90

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
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
