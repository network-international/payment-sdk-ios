import Foundation


protocol ShowInlineErrorMessage
{
    typealias ShowErrorMessageBlock = (String?) -> ()
    var showErrorMessage : ShowErrorMessageBlock? { get set }
}
