import UIKit

class CardPreviewViewController: UIViewController, CardPreviewProtocol
{
    private var front : CardPreviewFrontView!
    private var back  : CardPreviewBackView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        setupSubviews()
    }
    
    // MARK: - Subviews -
    
    private func setupSubviews()
    {
        self.front = CardPreviewFrontView()
        self.view.addSubview(self.front)

        DispatchQueue.main.async
        {
            self.back = CardPreviewBackView()
        }
    }
    
    override func viewWillLayoutSubviews()
    {
        log("frame:\(self.view.frame)")
        guard self.view.frame.size != self.front.frame.size else
        {
            log("Frames are equal. No need to adjust.")
            return
        }
        self.fixPreviewOnScreen()
    }
    
    private func fixPreviewOnScreen()
    {
        let previewSize = self.front.frame.size
        let selfSize = self.view.frame.size
        let scale = selfSize.width / previewSize.width
        self.front.transform = self.front.transform.scaledBy(x: scale, y: scale)
        self.front.center = CGPoint(x: selfSize.width/2, y: selfSize.height/2)
        DispatchQueue.main.async
        {
            self.back.transform = self.front.transform
            self.back.center = self.front.center
        }
    }
    
    // MARK: - CardPreviewProtocol -
    
    func update(for card: CardIdentity?, from fieldKind: FormField.Kind, with string: String)
    {
        //TODO: add location of PAN and date, as on some cards(N26 Metal) they can be on the back
        switch fieldKind
        {
        case .PAN, .holderName, .expiryDate  :  self.front.update(for: card, from: fieldKind, with: string)
        default                              : break
        }
    }
    
    func updateCVVLocation(for card: CardIdentity, showing: Bool)
    {
        guard let description = card.description else { return }
        guard description.CVV.location == .front else
        {
            self.updateCVVOnBack(for: card, description: description, showing: showing)
            return
        }
        
        self.front.updateCVVLocation(for: card, showing: showing)
    }
}


extension CardPreviewViewController
{
    private func updateCVVOnBack(for card: CardIdentity, description: CardDescription, showing: Bool)
    {
        self.back.updateCVVLocation(for: card, showing: showing)
        
        if showing
        {
            self.animateToBack()
        }
        else
        {
            self.animateToFront()
        }
    }
    
    private func animateToBack()
    {
        UIView.transition(with: self.view,
                          duration: 0.3,
                          options: [.curveEaseOut, .transitionFlipFromRight],
                          animations:
            {
                self.front.removeFromSuperview()
                self.view.addSubview(self.back)
                
        },
                          completion: nil)
    }
    
    private func animateToFront()
    {
        UIView.transition(with: self.view,
                          duration: 0.3,
                          options: [.curveEaseOut, .transitionFlipFromLeft],
                          animations:
            {
                self.back.removeFromSuperview()
                self.view.addSubview(self.front)
        },
                          completion: nil)
    }
}
