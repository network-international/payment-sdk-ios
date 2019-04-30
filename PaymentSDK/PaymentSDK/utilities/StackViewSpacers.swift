import UIKit

struct StackViewSpacers
{
    static func addSpacer(toStack stack: UIStackView, width: CGFloat)
    {
        let spacer = self.spacer()
        stack.addArrangedSubview(spacer)
        spacer.widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    
    static func addSpacer(toStack stack: UIStackView, height: CGFloat)
    {
        let spacer = self.spacer()
        stack.addArrangedSubview(spacer)
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
    }
    
    static func addFlexibleSpacer(toStack stack: UIStackView)
    {
        let spacer = self.spacer()
        stack.addArrangedSubview(spacer)
        spacer.setContentHuggingPriority(UILayoutPriority.defaultLow, for: .horizontal)
        spacer.setContentHuggingPriority(UILayoutPriority.defaultLow, for: .vertical)
    }
    
    static func spacer() -> UIView
    {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }

}
