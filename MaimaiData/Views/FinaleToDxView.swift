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
                    EmptyView()
                } content: {
                    AppInsetGroup(padding: 14) {
                        HStack {
                            Text("DX 达成率")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(resultText)
                                .font(.title3.weight(.bold).monospacedDigit())
                                .foregroundStyle(AppTheme.accent)
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
                    EmptyView()
                } content: {
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
            .padding(.vertical, 12)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
            }

            HStack(spacing: 8) {
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
        let tp = val(tapP), tgr = val(tapGr), tgd = val(tapGd), tm = val(tapM)
        let hp = val(holdP), hgr = val(holdGr), hgd = val(holdGd), hm = val(holdM)
        let sp = val(slideP), sgr = val(slideGr), sgd = val(slideGd), sm = val(slideM)
        let bp = val(breakP), bgr = val(breakGr), bgd = val(breakGd), bm = val(breakM)
        let bs = val(breakScore)

        let tapCount = tp + tgr + tgd + tm
        let holdCount = hp + hgr + hgd + hm
        let slideCount = sp + sgr + sgd + sm
        let breakCount = bp + bgr + bgd + bm

        let dxTotal = tapCount * 10 + holdCount * 20 + slideCount * 30 + breakCount * 50
        guard dxTotal > 0, breakCount > 0 else {
            errorText = "请填写有效物量（至少需要包含 Break 数量）"
            return
        }

        let dxPlayMax = tp * 10 + tgr * 8 + tgd * 5 +
            hp * 20 + hgr * 16 + hgd * 10 +
            sp * 30 + sgr * 24 + sgd * 15 +
            bp * 50 + bgr * 40 + bgd * 20

        let dxPlayMin = tp * 10 + tgr * 8 + tgd * 5 +
            hp * 20 + hgr * 16 + hgd * 10 +
            sp * 30 + sgr * 24 + sgd * 15 +
            bp * 50 + bgr * 25 + bgd * 20

        if bs == 0 {
            let maxScore = Double(dxPlayMax) / Double(dxTotal) * 100.0
                + Double(bp) / Double(breakCount) * 1.0
                + Double(bgr) / Double(breakCount) * 0.4
                + Double(bgd) / Double(breakCount) * 0.3
            let minScore = Double(dxPlayMin) / Double(dxTotal) * 100.0
                + Double(bp) / Double(breakCount) * 0.5
                + Double(bgr) / Double(breakCount) * 0.4
                + Double(bgd) / Double(breakCount) * 0.3
            resultText = String(format: "%.4f%% ~ %.4f%%", minScore, maxScore)
        } else {
            if bgr > 0 || bgd > 0 || bm > 0 || bp * 2600 < bs || bp * 2500 > bs {
                errorText = "绝赞数据错误，请重新填写"
                return
            }
            let dxBreak = 1.0 - 0.25 * Double(breakCount * 2600 - bs) / 50.0 / Double(breakCount)
            let dxCurrent = Double(dxPlayMax) / Double(dxTotal) * 100.0 + dxBreak
            resultText = String(format: "%.4f%%", dxCurrent)
        }
    }
}
