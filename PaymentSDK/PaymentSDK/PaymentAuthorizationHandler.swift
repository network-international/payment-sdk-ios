import Foundation
import PassKit

public final class PaymentAuthorizationHandler
{
    private let applePayManger = ApplePayManager()
    private let acceptedCards : [CardDescription]
    
    init(acceptedCards: [CardDescription]?)
    {
        self.acceptedCards = acceptedCards ?? []
    }
    
    /// Present the Payment UI full screen over the parent view controller supplied by the host app. The parent view
    /// controller must be the topmost view controller. The SDK deals with presenting the UI and dismissing it and
    /// will notify the host app through the `authorizationDelegate` property of the `Configuration` object that
    /// conforms to the `PaymentAuthorizationDelegate` protocol. The items are used to populate the UI for the user
    /// to see the payment items overview, and must total the same amount as the payment amount. See Apple Pay
    /// documentation for details.
    ///
    /// - Parameters:
    ///   - parentViewController: The topmost UIViewController object in the host app.
    ///   - configuration: The configuration object that contains properties required to present the payment UI.
    ///   - items: The items to show the user. Contains high level summary of items(product total, tax total, delivery
    ///     total) and the actual total the customer will be charged.
    ///   - completion: The block executed when the UI has finished animating into view.
    
    public func presentCardView(overParent parentViewController : UIViewController,
                                withDelegate paymentDelegate : PaymentDelegate,
                                completion                      : VoidBlock?){
        let manager = CardDataCollectionManager(withDelegate  : paymentDelegate, acceptedCards : self.acceptedCards)
        let viewController = PaymentAuthorizationViewController(withShowCompletion: completion)
        parentViewController.present(viewController, animated: false)
        {
            viewController.animateContent(withDataCollectionManager: manager)
        }
    }
    
    public func presentApplePayView(overParent parentViewController : UIViewController,
                                    withDelegate paymentDelegate : PaymentDelegate,
                                    withApplePayDelegate applePayDelegate : ApplePayDelegate,
                                    withRequest applePayRequest : PKPaymentRequest?,
                                    items                           : [PKPaymentSummaryItem],
                                    completion                      : VoidBlock?)
    {
        guard let paymentRequest = applePayRequest else
        {
            completion?()
            return
        }
        
        let loadingView = ActivityLoader()
        parentViewController.present(loadingView, animated: false, completion: nil)
        let paymentMethod = PKPaymentMethod.init()
        let method = PaymentMethod.method(fromPK: paymentMethod)
        
        paymentDelegate.authorizationStarted()
        paymentDelegate.beginAuthorization(didSelect: method) { (paymentAuthorizationLink) in
            
            guard let paymentAuthorizationLink = paymentAuthorizationLink else
            {
                loadingView.dismiss(animated: false, completion: nil)
                paymentDelegate.authorizationCompleted(withStatus: .failed)
                completion?()
                return
            }
            
            let apiInteractor = PaymentAuthorizationApiInteractor()
            apiInteractor.doAuthorization(with: paymentAuthorizationLink){
                [weak self]
                (status, orderData) in
                
                loadingView.dismiss(animated: false, completion: nil)
                guard let cards = orderData?.paymentMethods.card,
                    let acceptedCards = self?.getSupportedCards(cards) else {
                        paymentDelegate.authorizationCompleted(withStatus: .failed)
                        completion?()
                        return
                }
                
                guard let merchantIdentifier = Interface.sharedInstance.configuration?.merchantIdentifier,
                    let merchantCapabilities = Interface.sharedInstance.configuration?.merchantCapabilities else {
                        paymentDelegate.authorizationCompleted(withStatus: .failed)
                        completion?()
                        return
                }
                
                paymentRequest.merchantIdentifier = merchantIdentifier // TODO: get it from PaymentSDK.Interface config
                paymentRequest.merchantCapabilities = merchantCapabilities
                paymentRequest.supportedNetworks = acceptedCards
                paymentRequest.paymentSummaryItems = items
                paymentRequest.requiredBillingContactFields = [.postalAddress, .name]
                
                let vc = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest)
                guard let viewController = vc else
                {
                    paymentDelegate.authorizationCompleted(withStatus: .failed)
                    completion?()
                    return
                }
                
                self?.applePayManger.delegate = paymentDelegate
                self?.applePayManger.applePayDelegate = applePayDelegate
                self?.applePayManger.apiInteractor = apiInteractor
                viewController.delegate = self?.applePayManger
                
                paymentDelegate.authorizationCompleted(withStatus: .failed)
                
                parentViewController.present(viewController, animated: true, completion: completion)
            }
        }
    }
    
    func getSupportedCards(_ cards: [String]) -> [PKPaymentNetwork] {
        return PaymentConfigurationHandler.getCards().filter{
            cards.contains(($0.cardType?.rawValue)!)
            }.map{ $0.network }
    }
}
