import Foundation

struct CardholderFieldFormatUtility
{
    static func preview(forText text : String) -> String
    {
        guard text.count > 0 else { return LocalizedString("cardholder_field_preview", comment: "") }
        return ""
    }
    
    static func validTextOnly(forText text: String) -> String
    {
        var digits = text.uppercased()
        let validCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ .-'")
        digits = String(digits.unicodeScalars.filter(validCharacters.contains))
        return self.stringByRemovingInitialSpace(from:digits)
    }
    
    private static func stringByRemovingInitialSpace(from string: String) -> String
    {
        let first = string.prefix(1)
        guard first.contains(" ") else
        {
            return string
        }
        return String(string.suffix(from: String.Index.init(encodedOffset: 1)))
    }
}
