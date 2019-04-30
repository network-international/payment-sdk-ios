import UIKit

extension UIView
{
    func height(constant: CGFloat)
    {
        addConstraint(value: constant, attribute: .height)
    }
    
    func width(constant: CGFloat)
    {
        addConstraint(value: constant, attribute: .width)
    }
    
    func width(sameAs parent: UIView)
    {
        self.widthAnchor.constraint(equalTo: parent.widthAnchor).isActive = true
    }
    
    private func removeConstraint(attribute: NSLayoutConstraint.Attribute)
    {
        constraints.forEach
        {
            if $0.firstAttribute == attribute
            {
                removeConstraint($0)
            }
        }
    }
    
    private func addConstraint(value: CGFloat, attribute: NSLayoutConstraint.Attribute)
    {
        removeConstraint(attribute: attribute)
        let constraint = NSLayoutConstraint(item        : self,
                                            attribute   : attribute,
                                            relatedBy   : .equal,
                                            toItem      : nil,
                                            attribute   : .notAnAttribute,
                                            multiplier  : 1,
                                            constant    : value)
        self.addConstraint(constraint)
    }
    
    class func constrain(stackView: UIStackView, toScrollView parent: UIView)
    {
        UIView.constrain(view: stackView, toParent: parent)
        stackView.widthAnchor.constraint(equalTo: parent.widthAnchor).isActive = true
    }
    
    class func constrain(view: UIView, toParent parent: UIView)
    {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.topAnchor.constraint(equalTo: parent.topAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: parent.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: parent.trailingAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: parent.bottomAnchor).isActive = true
    }
    
    class func constrain(view: UIView, toParent parent: UIView, padding: UIEdgeInsets)
    {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        if padding.top == 0
        {
            view.topAnchor.constraint(equalTo: parent.topAnchor).isActive = true
        }
        else
        {
            view.topAnchor.constraint(equalTo: parent.topAnchor, constant: padding.top).isActive = true
        }
        
        if padding.bottom == 0
        {
            view.bottomAnchor.constraint(equalTo: parent.bottomAnchor).isActive = true
        }
        else
        {
            view.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -padding.bottom).isActive = true
        }
        
        if padding.left == 0
        {
            view.leadingAnchor.constraint(equalTo: parent.leadingAnchor).isActive = true
        }
        else
        {
            view.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: padding.left).isActive = true
        }
        
        if padding.right == 0
        {
            view.trailingAnchor.constraint(equalTo: parent.trailingAnchor).isActive = true
        }
        else
        {
            view.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -padding.right).isActive = true
        }
    }
    
    class func centerFixedSizeView(_ view: UIView, in parent: UIView)
    {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.centerYAnchor.constraint(equalTo: parent.centerYAnchor).isActive = true
        view.centerXAnchor.constraint(equalTo: parent.centerXAnchor).isActive = true
    }
    
    class func center(view: UIView, ofSize size: CGSize, in parent: UIView)
    {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.width(constant: size.width)
        view.height(constant: size.height)
        self.centerFixedSizeView(view, in: parent)
    }
}
