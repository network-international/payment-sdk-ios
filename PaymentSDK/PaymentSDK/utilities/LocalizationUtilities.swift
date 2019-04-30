import Foundation

fileprivate let localBundle = Bundle(for: Interface.self)


/// Returns a localized string, using the bundle of the `Payment SDK` Framework. Used to avoid the automatic usage of the
/// default bundle (host App bundle) when searching for localized strings that we get from a call to `NSLocalizedString`
/// - Parameters:
///   - key: The key used to find the localized string value in the `Localizable.string` file.
///   - comment: The comment used by translators to know the context of usage, so they can provide the correct variant
///   of a word.
/// - Returns: The localized string(returns the passed in `key` if no value was found).
func LocalizedString(_ key: String, comment: String) -> String
{
    return NSLocalizedString(key, bundle: localBundle, comment: comment)
}
