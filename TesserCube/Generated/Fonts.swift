// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(OSX)
  import AppKit.NSFont
  internal typealias Font = NSFont
#elseif os(iOS) || os(tvOS) || os(watchOS)
  import UIKit.UIFont
  internal typealias Font = UIFont
#endif

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Fonts

// swiftlint:disable identifier_name line_length type_body_length
internal enum FontFamily {
  internal enum Menlo {
    internal static let bold = FontConvertible(name: "Menlo-Bold", family: "Menlo", path: "Menlo.ttc")
    internal static let boldItalic = FontConvertible(name: "Menlo-BoldItalic", family: "Menlo", path: "Menlo.ttc")
    internal static let italic = FontConvertible(name: "Menlo-Italic", family: "Menlo", path: "Menlo.ttc")
    internal static let regular = FontConvertible(name: "Menlo-Regular", family: "Menlo", path: "Menlo.ttc")
    internal static let all: [FontConvertible] = [bold, boldItalic, italic, regular]
  }
  internal enum SFProDisplay {
    internal static let bold = FontConvertible(name: "SFProDisplay-Bold", family: "SF Pro Display", path: "SF-Pro-Display-Bold.otf")
    internal static let light = FontConvertible(name: "SFProDisplay-Light", family: "SF Pro Display", path: "SF-Pro-Display-Light.otf")
    internal static let medium = FontConvertible(name: "SFProDisplay-Medium", family: "SF Pro Display", path: "SF-Pro-Display-Medium.otf")
    internal static let regular = FontConvertible(name: "SFProDisplay-Regular", family: "SF Pro Display", path: "SF-Pro-Display-Regular.otf")
    internal static let all: [FontConvertible] = [bold, light, medium, regular]
  }
  internal enum SFProText {
    internal static let regular = FontConvertible(name: "SFProText-Regular", family: "SF Pro Text", path: "SF-Pro-Text-Regular.otf")
    internal static let semibold = FontConvertible(name: "SFProText-Semibold", family: "SF Pro Text", path: "SF-Pro-Text-Semibold.otf")
    internal static let all: [FontConvertible] = [regular, semibold]
  }
  internal enum SourceCodePro {
    internal static let regular = FontConvertible(name: "SourceCodePro-Regular", family: "Source Code Pro", path: "SourceCodePro-Regular.otf")
    internal static let all: [FontConvertible] = [regular]
  }
  internal enum SourceCodeProMedium {
    internal static let regular = FontConvertible(name: "SourceCodePro-Medium", family: "Source Code Pro Medium", path: "SourceCodePro-Medium.ttf")
    internal static let all: [FontConvertible] = [regular]
  }
  internal static let allCustomFonts: [FontConvertible] = [Menlo.all, SFProDisplay.all, SFProText.all, SourceCodePro.all, SourceCodeProMedium.all].flatMap { $0 }
  internal static func registerAllCustomFonts() {
    allCustomFonts.forEach { $0.register() }
  }
}
// swiftlint:enable identifier_name line_length type_body_length

// MARK: - Implementation Details

internal struct FontConvertible {
  internal let name: String
  internal let family: String
  internal let path: String

  internal func font(size: CGFloat) -> Font! {
    return Font(font: self, size: size)
  }

  internal func register() {
    // swiftlint:disable:next conditional_returns_on_newline
    guard let url = url else { return }
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
  }

  fileprivate var url: URL? {
    let bundle = Bundle(for: BundleToken.self)
    return bundle.url(forResource: path, withExtension: nil)
  }
}

internal extension Font {
  convenience init!(font: FontConvertible, size: CGFloat) {
    #if os(iOS) || os(tvOS) || os(watchOS)
    if !UIFont.fontNames(forFamilyName: font.family).contains(font.name) {
      font.register()
    }
    #elseif os(OSX)
    if let url = font.url, CTFontManagerGetScopeForURL(url as CFURL) == .none {
      font.register()
    }
    #endif

    self.init(name: font.name, size: size)
  }
}

private final class BundleToken {}
