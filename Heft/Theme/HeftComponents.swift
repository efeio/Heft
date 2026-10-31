//
//  HeftComponents.swift
//  Heft
//
//  Reusable UI components, custom inputs, selectors, and container layouts.
//

import SwiftUI

// MARK: - Keyboard Dismiss Toolbar
struct KeyboardDismissToolbar: ViewModifier {
    @Environment(\.heftAccent) private var accent
    @FocusState.Binding var isFocused: Bool

    func body(content: Content) -> some View {
        content.toolbar {
            if isFocused {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Bitti") {
                        isFocused = false
                    }
                    .font(.heftBodySemibold)
                    .foregroundStyle(accent)
                }
            }
        }
    }
}

struct KeyboardDismissToolbarWithBinding: ViewModifier {
    @Environment(\.heftAccent) private var accent
    @Binding var isFocused: Bool

    func body(content: Content) -> some View {
        content.toolbar {
            if isFocused {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Bitti") {
                        isFocused = false
                    }
                    .font(.heftBodySemibold)
                    .foregroundStyle(accent)
                }
            }
        }
    }
}

extension View {
    func keyboardDismissToolbar(isFocused: FocusState<Bool>.Binding) -> some View {
        modifier(KeyboardDismissToolbar(isFocused: isFocused))
    }

    func keyboardDismissToolbar(isFocused: Binding<Bool>) -> some View {
        modifier(KeyboardDismissToolbarWithBinding(isFocused: isFocused))
    }
}

// MARK: - Primary Button Style
struct HeftPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.heftAccentFill) private var accentFill
    @Environment(\.heftAccentPressed) private var accentPressed
    @ScaledMetric(relativeTo: .headline) private var verticalPadding: CGFloat = 14
    @ScaledMetric(relativeTo: .headline) private var horizontalPadding: CGFloat = 20

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.heftButton)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .background {
                Capsule()
                    .fill(configuration.isPressed ? accentPressed : accentFill)
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.4)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Primary Button Component
struct HeftPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
        }
        .buttonStyle(HeftPrimaryButtonStyle())
        .disabled(!isEnabled)
    }
}

// MARK: - Onboarding Step Container
struct OnboardingStepContainer<Content: View>: View {
    @Environment(\.heftAccent) private var accent
    @ScaledMetric(relativeTo: .body) private var topPadding: CGFloat = 12
    @ScaledMetric(relativeTo: .body) private var bottomPadding: CGFloat = 12
    @ScaledMetric(relativeTo: .body) private var barHeight: CGFloat = 6

    let currentStep: Int
    let totalSteps: Int
    let buttonTitle: String
    var isButtonEnabled: Bool = true
    var onBack: (() -> Void)? = nil
    let onButtonTap: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Header: Progress Bar with optional back button
            HStack(spacing: 12) {
                if let onBack, currentStep > 1 {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.primary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.heftSurface))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Geri")
                }

                // Progress Bar
                GeometryReader { proxy in
                    let progress = CGFloat(currentStep) / CGFloat(max(totalSteps, 1))
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.heftSurfaceSub)
                        Capsule()
                            .fill(accent)
                            .frame(width: proxy.size.width * min(max(progress, 0.0), 1.0))
                            .animation(.easeOut(duration: 0.3), value: currentStep)
                    }
                }
                .frame(height: barHeight)

                if onBack != nil && currentStep > 1 {
                    Spacer()
                        .frame(width: 36, height: 36)
                }
            }
            .frame(height: 36)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)

            // Step Content
            VStack {
                content()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom Action Button
            HeftPrimaryButton(
                title: buttonTitle,
                isEnabled: isButtonEnabled,
                action: onButtonTap
            )
            .padding(.bottom, bottomPadding)
        }
        .padding(.horizontal)
        .background(Color.heftCanvas)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Premium Text Input Card (Name, General)
struct HeftTextInputCard: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let placeholder: String
    @Binding var text: String
    var isError: Bool = false
    var errorMessage: String? = nil
    var onTextChange: (() -> Void)? = nil

    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.heftAccent) private var accent
    @ScaledMetric(relativeTo: .body) private var iconBoxSize: CGFloat = 38
    @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 14

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    // Leading Icon Badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isFocused ? accent.opacity(0.15) : (colorScheme == .dark ? Color.heftSurfaceSub : accent.opacity(0.08)))
                            .frame(width: iconBoxSize, height: iconBoxSize)

                        Image(systemName: icon)
                            .font(.headline)
                            .foregroundStyle(isFocused ? accent : (colorScheme == .dark ? Color.white : accent))
                    }

                    // Title & Subtitle
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(.heftBodySemibold)
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)

                        if let subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()
                }

                // Text Input Bar
                HStack {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .focused($isFocused)
                        .onChange(of: text) { _, _ in
                            onTextChange?()
                        }

                    if !text.isEmpty {
                        Button {
                            text = ""
                            onTextChange?()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.footnote)
                                .foregroundStyle(Color.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.heftSurfaceSub)
                }
            }
            .padding(cardPadding)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.heftSurface)
                    .shadow(color: (colorScheme == .dark || contrast == .increased) ? Color.clear : Color.heftNavy.opacity(0.04), radius: 8, x: 0, y: 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isError ? Color.heftError : (isFocused ? accent : Color.heftDivider),
                        lineWidth: (isFocused || isError || contrast == .increased) ? 1.5 : 1
                    )
            }

            if isError, let message = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(message)
                        .font(.heftMeta)
                }
                .foregroundStyle(Color.heftError)
                .padding(.leading, 4)
                .transition(.opacity)
            }
        }
        .keyboardDismissToolbar(isFocused: $isFocused)
    }
}

// MARK: - Premium Gender Selector
struct HeftGenderSelector: View {
    @Binding var selectedGender: Gender
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.heftAccent) private var accent
    @Environment(\.heftAccentFill) private var accentFill
    @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 50
    @ScaledMetric(relativeTo: .body) private var circleSize: CGFloat = 30

    var body: some View {
        HStack(spacing: 10) {
            genderButton(
                title: "Erkek",
                icon: "figure.stand",
                tag: .male
            )

            genderButton(
                title: "Kadın",
                icon: "figure.stand.dress",
                tag: .female
            )
        }
    }

    @ViewBuilder
    private func genderButton(title: String, icon: String, tag: Gender) -> some View {
        let isSelected = selectedGender == tag

        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                selectedGender = tag
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? accentFill : Color.heftSurfaceSub)
                        .frame(width: circleSize, height: circleSize)

                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)
                }

                Text(title)
                    .font(.heftBodySemibold)
                    .foregroundStyle(isSelected ? accent : Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: minHeight)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? (colorScheme == .dark ? accent.opacity(0.15) : accent.opacity(0.08)) : Color.heftSurface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected ? accent : Color.heftDivider,
                        lineWidth: (isSelected || contrast == .increased) ? 1.5 : 1.0
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Premium Goal Selector (Lose vs Gain Weight)
struct HeftGoalSelector: View {
    @Binding var selectedGoal: GoalType
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.heftAccent) private var accent
    @Environment(\.heftAccentFill) private var accentFill
    @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 50
    @ScaledMetric(relativeTo: .body) private var circleSize: CGFloat = 30

    var body: some View {
        HStack(spacing: 8) {
            goalButton(
                title: "Kilo Vermek",
                icon: "flame.fill",
                tag: .lose
            )

            goalButton(
                title: "Korumak",
                icon: "equal.circle.fill",
                tag: .maintain
            )

            goalButton(
                title: "Kilo Almak",
                icon: "figure.strengthtraining.traditional",
                tag: .gain
            )
        }
    }

    @ViewBuilder
    private func goalButton(title: String, icon: String, tag: GoalType) -> some View {
        let isSelected = selectedGoal == tag

        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                selectedGoal = tag
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? accentFill : Color.heftSurfaceSub)
                        .frame(width: circleSize, height: circleSize)

                    Image(systemName: icon)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)
                }

                Text(title)
                    .font(.heftBodySemibold)
                    .foregroundStyle(isSelected ? accent : Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: minHeight)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? (colorScheme == .dark ? accent.opacity(0.15) : accent.opacity(0.08)) : Color.heftSurface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected ? accent : Color.heftDivider,
                        lineWidth: (isSelected || contrast == .increased) ? 1.5 : 1.0
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Horizontal Scrollable Tick Picker
struct HeftTickPicker: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let formatStyle: TickPickerFormatStyle

    enum TickPickerFormatStyle {
        case integer    // "28" for age, "178" for height
        case decimal    // "78.5" for weight
    }

    @Environment(\.heftAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    @State private var scrolledID: Int?
    @State private var feedbackGenerator: UIImpactFeedbackGenerator?

    private let tickSpacing: CGFloat = 8

    private var totalSteps: Int {
        max(0, Int(round((range.upperBound - range.lowerBound) / step)))
    }

    private var formattedValue: String {
        if formatStyle == .integer {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }

    private func value(for index: Int) -> Double {
        let raw = range.lowerBound + Double(index) * step
        if formatStyle == .decimal {
            return (raw * 10).rounded() / 10.0
        } else {
            return raw.rounded()
        }
    }

    private func index(for val: Double) -> Int {
        let clamped = min(max(val, range.lowerBound), range.upperBound)
        let steps = (clamped - range.lowerBound) / step
        return min(max(Int(round(steps)), 0), totalSteps)
    }

    private func labelText(for index: Int) -> String {
        let val = value(for: index)
        return String(format: "%.0f", val)
    }

    private func tickHeight(for index: Int, centerIndex: Int) -> CGFloat {
        let baseHeight: CGFloat = (index % 5 == 0) ? 18 : 9
        let dist = abs(Double(index) - Double(centerIndex))
        if dist <= 6 {
            let factor = 1.0 + 0.65 * exp(-(dist * dist) / 6.0)
            return baseHeight * factor
        }
        return baseHeight
    }

    private func tickColor(for index: Int, centerIndex: Int) -> Color {
        let dist = abs(Double(index) - Double(centerIndex))
        if dist <= 2.5 {
            return Color.primary
        } else if index % 5 == 0 {
            return Color.primary.opacity(0.85)
        } else {
            return Color.secondary.opacity(0.4)
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            // Value display with smooth transition
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(formattedValue)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: formattedValue)

                Text(unit)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // Ruler area
            GeometryReader { rulerGeo in
                let halfWidth = rulerGeo.size.width / 2
                let centerIdx = scrolledID ?? index(for: value)

                ZStack {
                    // 1. Bottom layer: ScrollView
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 0) {
                            ForEach(0...totalSteps, id: \.self) { idx in
                                VStack(spacing: 4) {
                                    VStack {
                                        Spacer(minLength: 0)
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(tickColor(for: idx, centerIndex: centerIdx))
                                            .frame(width: 2, height: tickHeight(for: idx, centerIndex: centerIdx))
                                    }
                                    .frame(height: 32)

                                    if idx % 10 == 0 {
                                        Text(labelText(for: idx))
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                            .foregroundStyle(Color.secondary)
                                            .fixedSize()
                                    } else {
                                        Text(" ")
                                            .font(.system(size: 11))
                                            .fixedSize()
                                            .hidden()
                                    }
                                }
                                .frame(width: tickSpacing)
                                .id(idx)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollPosition(id: $scrolledID, anchor: .center)
                    .scrollTargetBehavior(.viewAligned)
                    .contentMargins(.horizontal, halfWidth, for: .scrollContent)

                    // 2. Middle layer: Fixed center indicator line
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(accent)
                            .frame(width: 2.5, height: 36)

                        Circle()
                            .fill(accent)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .allowsHitTesting(false)

                    // 3. Top layer: Edge fade gradients
                    HStack {
                        LinearGradient(
                            colors: [
                                Color.heftSurface,
                                Color.heftSurface.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 32)

                        Spacer()

                        LinearGradient(
                            colors: [
                                Color.heftSurface.opacity(0),
                                Color.heftSurface
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 32)
                    }
                    .allowsHitTesting(false)
                }
            }
            .frame(height: 52)
        }
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.heftSurface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.heftDivider, lineWidth: contrast == .increased ? 1.5 : 1)
        }
        .onAppear {
            feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
            feedbackGenerator?.prepare()
            let initialIdx = index(for: value)
            scrolledID = initialIdx
        }
        .onChange(of: scrolledID) { _, newID in
            guard let newID = newID else { return }
            let newVal = value(for: newID)
            if abs(newVal - value) > 0.0001 {
                value = newVal
            }
            if !reduceMotion {
                let isMajor = (newID % 5 == 0)
                feedbackGenerator?.impactOccurred(intensity: isMajor ? 0.5 : 0.3)
                feedbackGenerator?.prepare()
            }
        }
        .onChange(of: value) { _, newVal in
            let targetID = index(for: newVal)
            if targetID != scrolledID {
                scrolledID = targetID
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(unit)
        .accessibilityValue("\(formattedValue) \(unit)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                let next = min(value + step, range.upperBound)
                value = (next * 10).rounded() / 10.0
            case .decrement:
                let prev = max(value - step, range.lowerBound)
                value = (prev * 10).rounded() / 10.0
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Previews
#Preview("Tick Picker") {
    VStack(spacing: 24) {
        HeftTickPicker(value: .constant(178), range: 50...250, step: 1, unit: "cm", formatStyle: .integer)
        HeftTickPicker(value: .constant(78.5), range: 30...250, step: 0.1, unit: "kg", formatStyle: .decimal)
    }
    .padding()
}

#Preview("Male Accent (Blue)") {
    VStack(spacing: 16) {
        HeftPrimaryButton(title: "Devam Et", icon: "arrow.right", isEnabled: true) {}
        HeftTextInputCard(icon: "person.fill", title: "Adınız", placeholder: "Örn: Efe", text: .constant("Efe"))
        HeftGenderSelector(selectedGender: .constant(.male))
        HeftGoalSelector(selectedGoal: .constant(.lose))
    }
    .padding()
    .environment(\.heftAccent, .heftBlue)
    .environment(\.heftAccentFill, .heftBlueFill)
    .environment(\.heftAccentPressed, .heftBluePressed)
}

#Preview("Female Accent (Pink)") {
    VStack(spacing: 16) {
        HeftPrimaryButton(title: "Devam Et", icon: "arrow.right", isEnabled: true) {}
        HeftTextInputCard(icon: "person.fill", title: "Adınız", placeholder: "Örn: Ayşe", text: .constant("Ayşe"))
        HeftGenderSelector(selectedGender: .constant(.female))
        HeftGoalSelector(selectedGoal: .constant(.lose))
    }
    .padding()
    .environment(\.heftAccent, .heftPink)
    .environment(\.heftAccentFill, .heftPinkFill)
    .environment(\.heftAccentPressed, .heftPinkPressed)
}

#Preview("iPhone SE (3rd gen)", traits: .fixedLayout(width: 375, height: 667)) {
    VStack(spacing: 16) {
        HeftPrimaryButton(title: "Devam Et", icon: "arrow.right", isEnabled: true) {}
        HeftTextInputCard(icon: "person.fill", title: "Adınız", placeholder: "Örn: Efe", text: .constant("Efe"))
        HeftGenderSelector(selectedGender: .constant(.male))
        HeftGoalSelector(selectedGoal: .constant(.lose))
    }
    .padding()
}

#Preview("iPhone 16 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    VStack(spacing: 16) {
        HeftPrimaryButton(title: "Devam Et", icon: "arrow.right", isEnabled: true) {}
        HeftTextInputCard(icon: "person.fill", title: "Adınız", placeholder: "Örn: Efe", text: .constant("Efe"))
        HeftGenderSelector(selectedGender: .constant(.male))
        HeftGoalSelector(selectedGoal: .constant(.lose))
    }
    .padding()
}
