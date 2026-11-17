import SwiftUI

enum AppTheme {
    // Brand & Accent Colors
    static let accent = Color(hex: 0x1668DC)
    static let accentBright = Color(hex: 0x2B88FF)
    static let favoritePink = Palette.noteBreak

    // Semantic Palette (game terms + shared accents; values must not change)
    enum Palette {
        // Notes
        static let noteTap = Color(hex: 0x12B4FF)
        static let noteHold = Color(hex: 0xFF9C24)
        static let noteSlide = Color(hex: 0x2FCA4C)
        static let noteBreak = Color(hex: 0xF43F7E)

        // Chart / delta
        static let chartRemaster = Color(hex: 0x762D8C)
        static let deltaUp = Color(hex: 0xE53935)
        static let deltaDown = Color(hex: 0x1E8E3E)

        // Judgments
        static let judgePerfect = Color(hex: 0x854400)
        static let judgeGreat = Color(hex: 0xB72267)
        static let judgeGood = Color(hex: 0x176523)
        static let judgeMiss = Color(.secondaryLabel)

        // Rating tool row icons (same values as note / difficulty colors)
        static let ratingPurple = Color(hex: 0x9F51DC)
        static let ratingOrange = noteHold
        static let ratingBlue = noteTap

        // Difficulty
        static let diffBasic = Color(hex: 0x6FD43D)
        static let diffAdvanced = Color(hex: 0xF8B709)
        static let diffExpert = Color(hex: 0xFF818D)
        static let diffMaster = ratingPurple
        static let diffRemaster = Color(hex: 0xCB5EEA)
        static let diffUtage = Color(hex: 0xB12876)
        static let diffBasicText = Color(hex: 0x183C12)
        static let diffAdvancedText = Color(hex: 0x4B3700)
        static let diffExpertText = Color(hex: 0x681B28)
        static let diffBasicDark = Color(hex: 0x025235)
        static let diffAdvancedDark = Color(hex: 0xC7450C)
        static let diffExpertDark = Color(hex: 0xC02138)
        static let diffMasterDark = Color(hex: 0x671B8D)
        static let diffRemasterDark = Color(hex: 0x8C2DD5)
        static let diffOtherDark = Color(hex: 0x053264)

        // Brightened difficulty colors for text/board on dark tinted backgrounds.
        static let boardMainBasic = Color(hex: 0x6FE163)
        static let boardMainAdvanced = Color(hex: 0xF8DF3B)
        static let boardMainExpert = Color(hex: 0xFFA0AE)
        static let boardMainMaster = Color(hex: 0xC27FF4)
        static let boardMainRemaster = Color(hex: 0xE5DDEA)

        // Genres: (fill, stroke) and text
        static let genrePop: (bg: Color, stroke: Color) = (bg: Color(hex: 0xFF9C24), stroke: Color(hex: 0xFFD21F))
        static let genreNico: (bg: Color, stroke: Color) = (bg: Color(hex: 0x12B4FF), stroke: Color(hex: 0x7ED6FF))
        static let genreTouhou: (bg: Color, stroke: Color) = (bg: Color(hex: 0xCA6FEB), stroke: Color(hex: 0xE8A7FF))
        static let genreGame: (bg: Color, stroke: Color) = (bg: Color(hex: 0x287516), stroke: Color(hex: 0xBAFBA3))
        static let genreMaimai: (bg: Color, stroke: Color) = (bg: Color(hex: 0xFF4646), stroke: Color(hex: 0xFFA7A7))
        static let genreUtage: (bg: Color, stroke: Color) = (bg: Color(hex: 0xDC39B8), stroke: diffUtage)
        static let genreOther: (bg: Color, stroke: Color) = (bg: Color(hex: 0x319DF8), stroke: Color(hex: 0x99D1FF))
        static let genrePopText = Color(hex: 0x8A4800)
        static let genreNicoText = Color(hex: 0x055C84)
        static let genreTouhouText = chartRemaster
        static let genreGameText = Color(hex: 0x1C560C)
        static let genreMaimaiText = Color(hex: 0x9A1B1B)
        static let genreUtageText = Color(hex: 0x8F1863)
        static let genreOtherText = Color(hex: 0x125BB8)

        // Checklist stat pills
        static let statSSS = Color(hex: 0xB46900)
        static let statFC = Color(hex: 0x237818)
        static let statAP = Color(hex: 0xC85A00)
        static let statFSD = Color(hex: 0x0A6BA1)

        // Shared surfaces & hairlines (light-mode chrome over the page gradient)
        static let surfaceDark = Color(hex: 0x172135)
        static let hairline = Color(hex: 0x0F2952)
        static let genreGameCardFill = Color(hex: 0x398428)
    }

    // Spacing & Sizing
    static let pagePadding: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12
    static let itemSpacing: CGFloat = 10
    static let rowMinHeight: CGFloat = 50

    // Corner Radii (Always use .continuous)
    enum Radius {
        static let card: CGFloat = 16
        static let inset: CGFloat = 12
        static let button: CGFloat = 14
        static let input: CGFloat = 12
        static let badge: CGFloat = 6
        static let tile: CGFloat = 10
        static let chip: CGFloat = 12
    }

    // Spacing scale
    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
    }

    // Typography Hierarchy (17pt Card Title > 15pt Row Title > 12pt Subtitle / Inline Button)
    enum Typography {
        static let cardTitle = Font.headline
        static let rowTitle = Font.subheadline.weight(.medium)
        static let songTitle = Font.subheadline.weight(.semibold)
        static let body = Font.subheadline
        static let inlineAction = Font.caption.weight(.semibold)
        static let badge = Font.caption2.weight(.bold).monospacedDigit()
        static let tag = Font.caption.weight(.medium)

        static let caption = Font.caption
        static let captionSemibold = Font.caption.weight(.semibold)
        static let captionBold = Font.caption.weight(.bold)
        static let captionMonospaced = Font.caption.monospacedDigit()
        static let captionMeta = Font.caption.weight(.semibold).monospacedDigit()
        static let captionMetaBold = Font.caption.weight(.bold).monospacedDigit()
        static let captionSemiboldMonospaced = Font.caption.weight(.semibold).monospaced()

        static let caption2 = Font.caption2
        static let caption2Semibold = Font.caption2.weight(.semibold)
        static let caption2Bold = Font.caption2.weight(.bold)
        static let caption2Medium = Font.caption2.weight(.medium)
        static let caption2Monospaced = Font.caption2.monospacedDigit()
        static let caption2Meta = Font.caption2.weight(.semibold).monospacedDigit()

        static let subheadlineBold = Font.subheadline.weight(.bold)
        static let subheadlineMediumMeta = Font.subheadline.weight(.medium).monospacedDigit()
        static let subheadlineSemiboldMeta = Font.subheadline.weight(.semibold).monospacedDigit()
        static let subheadlineBoldMeta = Font.subheadline.weight(.bold).monospacedDigit()

        static let headlineBold = Font.headline.weight(.bold)
        static let headlineBoldMonospaced = Font.headline.weight(.bold).monospacedDigit()
        static let title3Bold = Font.title3.weight(.bold)
        static let title3BoldMonospaced = Font.title3.weight(.bold).monospacedDigit()
        static let calloutBoldMonospaced = Font.callout.weight(.bold).monospacedDigit()
    }
}

struct AppPageBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var tint: Color = AppTheme.accent

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(hex: 0x0B1120), Color(hex: 0x0F172A), Color(hex: 0x111827)]
                : [Color(hex: 0xE8F0FC), Color(hex: 0xF1F5FB), Color(hex: 0xEDF2FA)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [
                    tint.opacity(colorScheme == .dark ? 0.16 : 0.10),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 260)
        }
        .ignoresSafeArea()
    }
}

extension View {
    func appPageBackground(tint: Color = AppTheme.accent) -> some View {
        background {
            AppPageBackground(tint: tint)
        }
    }
}
