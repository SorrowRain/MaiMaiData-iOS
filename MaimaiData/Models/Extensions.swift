import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

extension Color {
    /// Appearance-adaptive color resolved by the trait collection.
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
    }

    /// Same hue with HSB brightness raised to at least `minimum`; saturation optionally capped so
    /// small text keeps >= 4.5:1 against a 22% tint of the base color on dark surfaces.
    func brightened(toAtLeast minimum: CGFloat = 0.85, maxSaturation: CGFloat = 1) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
        return Color(UIColor(hue: h, saturation: min(s, maxSaturation), brightness: max(b, minimum), alpha: a))
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
