import UIKit

final class ScrollViewKeyboardHandler : NSObject
{
    weak private var scrollView : UIScrollView?
    private var visibility      : KeyboardVisibility = .hidden
    private var contentInset    : UIEdgeInsets
    
    init(with scrollView: UIScrollView)
    {
        self.scrollView   = scrollView
        self.contentInset = scrollView.contentInset
        super.init()
        self.subscribeToNotifications()
    }
    
    // MARK: - Notification Handling -
    
    private func subscribeToNotifications()
    {
        let center = NotificationCenter.default
        
        center.addObserver(self, selector: #selector(willShow(notification:)),
                           name: UIResponder.keyboardWillShowNotification, object: nil)
        
        center.addObserver(self, selector: #selector(willHide(notification:)),
                           name: UIResponder.keyboardWillHideNotification, object: nil)
        
        center.addObserver(self, selector: #selector(didHide(notification:)),
                           name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    @objc private func willShow(notification: Notification?)
    {
        log("")
        guard self.visibility == .hidden else { return }
        guard let scrollView = self.scrollView else { return }
        guard let info = KeyboardAnimationUtility.keyboardShowingInfo(for: notification) else { return }
        
        self.visibility = .visible
        scrollView.contentInset = type(of: self).contentInset(forOriginal: scrollView.contentInset,
                                                              keybaordFrame: info.frame.end)
    }
    
    @objc private func willHide(notification: Notification?)
    {
        log("")
        guard let scrollView = self.scrollView else { return }
        scrollView.contentInset = self.contentInset
    }
    
    @objc private func didHide(notification: Notification?)
    {
        log("")
        self.visibility = .hidden
    }
    
    private class func contentInset(forOriginal originalInsets: UIEdgeInsets, keybaordFrame: CGRect) -> UIEdgeInsets
    {
        var insets = originalInsets
        insets.bottom += keybaordFrame.size.height
        return insets
    }
    
    enum KeyboardVisibility
    {
        case visible
        case hidden
    }
}
