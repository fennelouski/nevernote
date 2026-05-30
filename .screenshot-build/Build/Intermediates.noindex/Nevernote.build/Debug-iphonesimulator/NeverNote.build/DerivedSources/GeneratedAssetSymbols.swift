import Foundation
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "BrandGraphic" asset catalog image resource.
    static let brandGraphic = DeveloperToolsSupport.ImageResource(name: "BrandGraphic", bundle: resourceBundle)

    /// The "Launch Screen iPad Landscape" asset catalog image resource.
    static let launchScreenIPadLandscape = DeveloperToolsSupport.ImageResource(name: "Launch Screen iPad Landscape", bundle: resourceBundle)

    /// The "Launch Screen iPad Portrait" asset catalog image resource.
    static let launchScreenIPadPortrait = DeveloperToolsSupport.ImageResource(name: "Launch Screen iPad Portrait", bundle: resourceBundle)

    /// The "Launch Screen iPhone Portrait" asset catalog image resource.
    static let launchScreenIPhonePortrait = DeveloperToolsSupport.ImageResource(name: "Launch Screen iPhone Portrait", bundle: resourceBundle)

}

