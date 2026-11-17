import SwiftUI

struct FinaleToDxView: View {
    @State private var tapP = ""; @State private var tapGr = ""; @State private var tapGd = ""; @State private var tapM = ""
    @State private var holdP = ""; @State private var holdGr = ""; @State private var holdGd = ""; @State private var holdM = ""
    @State private var slideP = ""; @State private var slideGr = ""; @State private var slideGd = ""; @State private var slideM = ""
    @State private var breakP = ""; @State private var breakGr = ""; @State private var breakGd = ""; @State private var breakM = ""
    @State private var breakScore = ""

    @State private var resultText: String = "—"
    @State private var errorText: String?

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.cardSpacing) {
                AppSectionCard(
                    title: "换算结果",
                    subtitle: "根据旧框判定换算对应的 DX 达成率区间或精确值"
                ) {
                    AppInsetGroup(padding: 14) {
                        HStack {
                            Text("DX 达成率")
                                .font(AppTheme.Typography.inlineAction)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(resultText)
                                .font(AppTheme.Typography.heroTitle)
                                .foregroundStyle(AppTheme.accentText)
                        }
                    }
                }

                AppSectionCard(
                    title: "各音符判定数",
                    subtitle: "未填写的项默认按 0 计算"
                ) {
                    AppInlineButton(title: "清空", tint: .secondary) {
                        KeyboardDismiss.hide()
                        clearAll()
                    }
                } content: {
                    VStack(spacing: 14) {
                        noteGroup("Tap", color: AppTheme.Palette.noteTap, p: $tapP, gr: $tapGr, gd: $tapGd, m: $tapM)
                        Divider()
                        noteGroup("Hold", color: AppTheme.Palette.noteHold, p: $holdP, gr: $holdGr, gd: $holdGd, m: $holdM)
                        Divider()
                        noteGroup("Slide", color: AppTheme.Palette.noteSlide, p: $slideP, gr: $slideGr, gd: $slideGd, m: $slideM)
                        Divider()
                        noteGroup("Break", color: AppTheme.Palette.noteBreak, p: $breakP, gr: $breakGr, gd: $breakGd, m: $breakM)
                    }
                }

                AppSectionCard(
                    title: "Break 绝赞总分（可选）",
                    subtitle: "Break 全 Perfect 时填写旧框绝赞总分可计算精确值"
                ) {
                    AppTextField(
                        placeholder: "Break 总分（可留空或填 0）",
                        text: $breakScore,
                        keyboardType: .numberPad
                    )
                }

                AppPrimaryButton(title: "计算 DX 达成率", icon: "equal.circle.fill") {
                    KeyboardDismiss.hide()
                    calculate()
                }
            }
            .padding(.horizontal, AppTheme.pagePadding)
            .padding(.vertical, AppTheme.Space.m)
            .dismissKeyboardOnTap()
        }
        .scrollDismissesKeyboard(.interactively)
        .appPageBackground()
        .navigationTitle("旧框分数换算 DX")
        .navigationBarTitleDisplayMode(.inline)
        .errorAlert("输入错误", message: $errorText)
    }

    private func noteGroup(
        _ title: String,
        color: Color,
        p: Binding<String>,
        gr: Binding<String>,
        gd: Binding<String>,
        m: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.s) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(AppTheme.Typography.subheadlineBold)
                    .foregroundStyle(.primary)
            }

            HStack(spacing: AppTheme.Space.s) {
                AppTextField(title: "Perfect", placeholder: "0", text: p, keyboardType: .numberPad)
                AppTextField(title: "Great", placeholder: "0", text: gr, keyboardType: .numberPad)
                AppTextField(title: "Good", placeholder: "0", text: gd, keyboardType: .numberPad)
                AppTextField(title: "Miss", placeholder: "0", text: m, keyboardType: .numberPad)
            }
        }
    }

    private func clearAll() {
        tapP = ""; tapGr = ""; tapGd = ""; tapM = ""
        holdP = ""; holdGr = ""; holdGd = ""; holdM = ""
        slideP = ""; slideGr = ""; slideGd = ""; slideM = ""
        breakP = ""; breakGr = ""; breakGd = ""; breakM = ""
        breakScore = ""
        resultText = "—"
    }

    private func val(_ text: String) -> Int {
        Int(text.trimmingCharacters(in: .whitespaces)) ?? 0
    }

    private func calculate() {
        let counts = RatingCalculator.FinaleNoteCounts(
            tapPerfect: val(tapP), tapGreat: val(tapGr), tapGood: val(tapGd), tapMiss: val(tapM),
            holdPerfect: val(holdP), holdGreat: val(holdGr), holdGood: val(holdGd), holdMiss: val(holdM),
            slidePerfect: val(slideP), slideGreat: val(slideGr), slideGood: val(slideGd), slideMiss: val(slideM),
            breakPerfect: val(breakP), breakGreat: val(breakGr), breakGood: val(breakGd), breakMiss: val(breakM),
            breakScore: val(breakScore)
        )
        do {
            resultText = try RatingCalculator.convertFinaleToDx(counts)
        } catch {
            errorText = error.localizedDescription
        }
    }
}
