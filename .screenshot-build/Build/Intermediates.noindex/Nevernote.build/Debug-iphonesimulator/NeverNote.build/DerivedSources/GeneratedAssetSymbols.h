#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "BrandGraphic" asset catalog image resource.
static NSString * const ACImageNameBrandGraphic AC_SWIFT_PRIVATE = @"BrandGraphic";

/// The "Launch Screen iPad Landscape" asset catalog image resource.
static NSString * const ACImageNameLaunchScreenIPadLandscape AC_SWIFT_PRIVATE = @"Launch Screen iPad Landscape";

/// The "Launch Screen iPad Portrait" asset catalog image resource.
static NSString * const ACImageNameLaunchScreenIPadPortrait AC_SWIFT_PRIVATE = @"Launch Screen iPad Portrait";

/// The "Launch Screen iPhone Portrait" asset catalog image resource.
static NSString * const ACImageNameLaunchScreenIPhonePortrait AC_SWIFT_PRIVATE = @"Launch Screen iPhone Portrait";

#undef AC_SWIFT_PRIVATE
