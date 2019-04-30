import UIKit


enum AllowedFormFieldActions
{
    case none
    case paste
    case all
}

class FormTextField: UITextField
{
    var invalidAppearance        : Bool = false
    var allowedActions           : AllowedFormFieldActions = .none
    var actionOnDeleteEmptyField : VoidBlock?
    
    override func deleteBackward()
    {
        if self.text?.count == 0
        {
            if let emptyDeleteAction = self.actionOnDeleteEmptyField
            {
                emptyDeleteAction()
            }
        }
        super.deleteBackward()
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool
    {
        switch self.allowedActions
        {
        case .none  : self.disableSharedMenuController()
                      fallthrough
        case .all   : return super.canPerformAction(action, withSender: sender)
        case .paste : return ( action == #selector(paste(_:)) )
        }
    }
    
    private func disableSharedMenuController()
    {
        OperationQueue.main.addOperation { UIMenuController.shared.setMenuVisible(false, animated: false) }
    }
}
