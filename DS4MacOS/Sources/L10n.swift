import Foundation

// MARK: - Localization helper
// SPM build uses Bundle.module; Xcode native target uses Bundle.main

private var _localizationBundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle.main
    #endif
}()

func L(_ key: String, _ args: CVarArg...) -> String {
    let fmt = NSLocalizedString(key, bundle: _localizationBundle, comment: "")
    if args.isEmpty { return fmt }
    return String(format: fmt, arguments: args)
}
