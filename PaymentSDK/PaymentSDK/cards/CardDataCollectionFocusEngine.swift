import Foundation

final class CardDataCollectionFocusEngine
{
	private var responderForKind : [FormField.Kind : UIResponder] = [:]

	func registerResponder(_ responder: UIResponder, forKind kind: FormField.Kind)
	{
		self.responderForKind[kind] = responder
	}

	func nextViewToFocus(afterViewOfKind kind: FormField.Kind ) -> UIResponder?
	{
		guard let nextKind = self.nextFocusTargetKind(forKind: kind) else { return nil }
		return responderForKind[nextKind]
	}

	private func nextFocusTargetKind(forKind kind: FormField.Kind) -> FormField.Kind?
	{
		switch kind
		{
		case .PAN           : return .expiryDate
		case .expiryDate    : return .CVV
		case .CVV           : return .holderName
		case .holderName    : return nil
		}
	}
}
