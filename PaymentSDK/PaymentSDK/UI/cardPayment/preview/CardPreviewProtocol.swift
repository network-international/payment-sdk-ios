import Foundation

protocol CardPreviewProtocol
{
    func update(for card: CardIdentity?, from fieldKind: FormField.Kind, with string: String)
    
    func updateCVVLocation(for card: CardIdentity, showing: Bool)
}
