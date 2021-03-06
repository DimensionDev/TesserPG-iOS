// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(OSX)
  import AppKit.NSImage
  internal typealias AssetColorTypeAlias = NSColor
  internal typealias AssetImageTypeAlias = NSImage
#elseif os(iOS) || os(tvOS) || os(watchOS)
  import UIKit.UIImage
  internal typealias AssetColorTypeAlias = UIColor
  internal typealias AssetImageTypeAlias = UIImage
#endif

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal static let backButton = ImageAsset(name: "back_button")
  internal static let introArrowBottomLeft = ImageAsset(name: "intro_arrow_bottomLeft")
  internal static let introArrowBottomRight = ImageAsset(name: "intro_arrow_bottomRight")
  internal static let introArrowTopRight = ImageAsset(name: "intro_arrow_topRight")
  internal static let buttonInterpretDisable = ImageAsset(name: "button_interpret_disable")
  internal static let buttonInterpretNormal = ImageAsset(name: "button_interpret_normal")
  internal static let buttonInterpretNormalDark = ImageAsset(name: "button_interpret_normal_dark")
  internal static let buttonInterpretedCloseBlack = ImageAsset(name: "button_interpreted_close_black")
  internal static let buttonInterpretedCloseWhite = ImageAsset(name: "button_interpreted_close_white")
  internal static let buttonLockNormal = ImageAsset(name: "button_lock_normal")
  internal static let buttonLockNormalDark = ImageAsset(name: "button_lock_normal_dark")
  internal static let buttonModeChangeIcon = ImageAsset(name: "button_modeChange_icon")
  internal static let buttonModeChangeIconDark = ImageAsset(name: "button_modeChange_icon_dark")
  internal static let buttonModeChangeIconDarkSelected = ImageAsset(name: "button_modeChange_icon_dark_selected")
  internal static let buttonModeChangeIconSelected = ImageAsset(name: "button_modeChange_icon_selected")
  internal static let mainTabContacts = ImageAsset(name: "main_tab_contacts")
  internal static let mainTabMe = ImageAsset(name: "main_tab_me")
  internal static let mainTabMessages = ImageAsset(name: "main_tab_messages")
  internal static let sceneMeImportKey = ImageAsset(name: "scene_me_import_key")
  internal static let mockPoster = ImageAsset(name: "mock_poster")
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal struct ColorAsset {
  internal fileprivate(set) var name: String

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, OSX 10.13, *)
  internal var color: AssetColorTypeAlias {
    return AssetColorTypeAlias(asset: self)
  }
}

internal extension AssetColorTypeAlias {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, OSX 10.13, *)
  convenience init!(asset: ColorAsset) {
    let bundle = Bundle(for: BundleToken.self)
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(OSX)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

internal struct DataAsset {
  internal fileprivate(set) var name: String

  #if os(iOS) || os(tvOS) || os(OSX)
  @available(iOS 9.0, tvOS 9.0, OSX 10.11, *)
  internal var data: NSDataAsset {
    return NSDataAsset(asset: self)
  }
  #endif
}

#if os(iOS) || os(tvOS) || os(OSX)
@available(iOS 9.0, tvOS 9.0, OSX 10.11, *)
internal extension NSDataAsset {
  convenience init!(asset: DataAsset) {
    let bundle = Bundle(for: BundleToken.self)
    #if os(iOS) || os(tvOS)
    self.init(name: asset.name, bundle: bundle)
    #elseif os(OSX)
    self.init(name: NSDataAsset.Name(asset.name), bundle: bundle)
    #endif
  }
}
#endif

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  internal var image: AssetImageTypeAlias {
    let bundle = Bundle(for: BundleToken.self)
    #if os(iOS) || os(tvOS)
    let image = AssetImageTypeAlias(named: name, in: bundle, compatibleWith: nil)
    #elseif os(OSX)
    let image = bundle.image(forResource: NSImage.Name(name))
    #elseif os(watchOS)
    let image = AssetImageTypeAlias(named: name)
    #endif
    guard let result = image else { fatalError("Unable to load image named \(name).") }
    return result
  }
}

internal extension AssetImageTypeAlias {
  @available(iOS 1.0, tvOS 1.0, watchOS 1.0, *)
  @available(OSX, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init!(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = Bundle(for: BundleToken.self)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(OSX)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

private final class BundleToken {}
