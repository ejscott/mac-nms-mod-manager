import AppKit
import SwiftUI

enum Brand {
    static let cyan = Color(red: 0.12, green: 0.82, blue: 0.91)
    static let teal = Color(red: 0.10, green: 0.66, blue: 0.70)
    static let amber = Color(red: 1.00, green: 0.68, blue: 0.24)
    static let navy = Color(red: 0.025, green: 0.075, blue: 0.14)
}

struct BrandLogo: View {
    var size: CGFloat

    private static let image: NSImage? = {
        guard let url = Bundle.main.url(forResource: "AppLogo", withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }()

    var body: some View {
        Group {
            if let image = Self.image {
                Image(nsImage: image).resizable().scaledToFit()
            } else {
                Image(systemName: "shippingbox.and.arrow.backward.fill")
                    .resizable().scaledToFit().padding(size * 0.18)
                    .foregroundStyle(Brand.cyan)
                    .background(Brand.navy)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
        .shadow(color: Brand.cyan.opacity(0.2), radius: size * 0.12, y: size * 0.04)
        .accessibilityHidden(true)
    }
}

struct BrandBackdrop: View {
    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            RadialGradient(
                colors: [Brand.cyan.opacity(0.10), Brand.teal.opacity(0.025), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 700
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    func brandPanel(cornerRadius: CGFloat = 14) -> some View {
        background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Brand.cyan.opacity(0.13), lineWidth: 1)
            }
    }
}
