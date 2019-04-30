import Foundation
import PassKit

typealias CardVerificationAction = (CardPaymentStatus.Payload3DS, @escaping (Bool)->Void) -> Void

final class CardDataCollectionManager: CardFieldValidation
{
    weak var delegate               : PaymentDelegate?
    private(set) var cardIdentity   : CardIdentity?
    private var acceptedCards       : [CardDescription]?
    let maxEndDateLength            : Int = 4
    let focusEngine                 = CardDataCollectionFocusEngine()
    var cardDataForm                : CardFieldValidation?
    var preview                     : CardPreviewProtocol!
    
    var failedPaymentAction         : VoidBlock?
    var paymentSuccessAction        : VoidBlock?
	var cardVerificationAction		: CardVerificationAction?
    
    private var paymentAuthorizationLink         : PaymentSDK.PaymentAuthorizationLink?
    private var card                : Card!
    private(set) var orderLink      : PaymentAuthorizationService.OrderLink?
    private(set) var currentPaymentLink    : PaymentAuthorizationService.PaymentLink?
    
    init(withDelegate delegate : PaymentDelegate,
         acceptedCards         : [CardDescription]?)
    {
        self.card = .init(PAN: "", expiry: "", CVV: "", holder: "")
        self.delegate = delegate
        self.acceptedCards = acceptedCards
    }
    
    init()
    {
        log("🚨   DON'T USE THIS    🚨")
    }
    
    var maxLengthCVV : Int {
        get {
            guard let card = self.cardIdentity else { return CVVValidation.Default.CVVLength }
            return CVVValidation.maxLengthCVV(forCard: card.description)
        }
    }
    
    var maxLengthsPAN : [Int] { get { return PANValidation.maxLengthsPAN(forCard: self.cardIdentity) } }
    
    var maxLengthCardHolder : Int { get { return CardholderValidation.maxLength } }
    
    func lengthState(forPAN PAN: String) -> PANLengthState
    {
        return PANValidation.lengthStatePAN(PAN, cardIdentity: self.cardIdentity)
    }
    
    func updateIdentityForFirstSixDigits(_ firstSix : String)
    {
        guard self.cardIdentity?.PAN.firstSix() != firstSix else
        {
            return
        }
        
        self.cardIdentity = CardDetector.cardIdentity(forBIN        : firstSix,
                                                      acceptedCards : self.acceptedCards)
    }
    
    func validEndDate(_ date: String) -> Bool
    {
        return EndDateValidation.isValid(date: date)
    }
    
    func createOrderOnInitialisation(with completion: @escaping () -> Void) {
        initiatePaymentFlow { [weak self] orderLink in
            self?.orderLink = orderLink
            completion()
        }
    }
    
    // MARK: - Update values -
    
    func updatePAN(_ value: String)
    {
        self.card = Card.card(byUpdating: self.card, newPAN: value)
    }
    
    func updateExpiryDate(_ value: String)
    {
        self.card = Card.card(byUpdating: self.card, newExpiry: value)
    }
    
    func updateCVV(_ value: String)
    {
        self.card = Card.card(byUpdating: self.card, newCVV: value)
    }
    
    func updateCardholderName(_ value: String)
    {
        self.card = Card.card(byUpdating: self.card, newHolderName: value)
    }
    
    // MARK: - CardFieldValidation Protocol -
    
    func valid(inContext context: CardDetailsValidation.ValidityContext) -> CardDetailsValidation.ValidStatus
    {
        guard let cardForm = self.cardDataForm else { return .invalid(reason: .all) }
        return cardForm.valid(inContext: context)
    }
    
    func defaultValidationErrorReason() -> CardDetailsValidation.ValidationIssue
    {
        guard let cardForm = self.cardDataForm else { return .all }
        return cardForm.defaultValidationErrorReason()
    }
    
    func showValidity(inContext context: CardDetailsValidation.ValidityContext)
    {
        log("not implemented")
    }
    
    // MARK: - Preview -
    
    func previewPAN(string: String)
    {
        self.preview.update(for: self.cardIdentity, from: .PAN, with: string)
    }
    
    func previewEndDate(string: String)
    {
        self.preview.update(for: self.cardIdentity, from: .expiryDate, with: string)
    }
    
    func previewCardholderName(string: String)
    {
        self.preview.update(for: self.cardIdentity, from: .holderName, with: string)
    }
    
    func previewCVVPosition(showing: Bool)
    {
        guard let identity = self.cardIdentity else { return }
        self.preview.updateCVVLocation(for: identity, showing: showing)
    }
    
    // MARK: - Known Card Type
    
    func initiatePaymentFlow(with completion: @escaping (PaymentAuthorizationService.OrderLink?) -> Void){
        let paymentMethod = type(of: self).paymentMethod(from: self.cardIdentity)
        
        
        self.delegate?.beginAuthorization(didSelect: paymentMethod, handler:
            {
                [weak self]
                (paymentAuthorizationLink) in
                
                guard let paymentAuthorizationLink = paymentAuthorizationLink else
                {
                    self?.delegate?.authorizationCompleted(withStatus: .failed)
                    return
                }
                
                log("✅✅ paymentAuthorization link:\(paymentAuthorizationLink)")
                self?.handlePaymentTypeUpdate(paymentLink : paymentAuthorizationLink)
                let apiInteractor = PaymentAuthorizationApiInteractor()
                self?.delegate?.authorizationStarted()
                apiInteractor.doAuthorization(with: paymentAuthorizationLink)
                {
                    (status, orderData) in
                    
                    guard let cards = orderData?.paymentMethods.card,
                        let paymentLink = orderData?.embedded.payment.first?.links.card?.href,
                        let orderLink = apiInteractor.orderLink else {
                            self?.delegate?.authorizationCompleted(withStatus: .failed)
                            completion(nil)
                            return
                    }
                    self?.mapAcceptableCards(cards)
                    self?.currentPaymentLink = PaymentAuthorizationService.PaymentLink(href: paymentLink,
                                                                                       accessToken: orderLink.token)
                    self?.delegate?.authorizationCompleted(withStatus: .success)
                    completion(orderLink)
                }
                
//                PaymentAuthorizationService.fetchOrderLink(using: paymentAuthorizationLink) { orderLink in
//                    guard let orderLink = orderLink else
//                    {
//                        return
//                    }
//                    PaymentAuthorizationService.getOrderDetails(using: orderLink)
//                    {
//                        [weak self] order in
//                        guard let cards = order?.paymentMethods.card else { return }
//                        self?.mapAcceptableCards(cards)
//                        guard let paymentLink = order?.embedded.payment.first?.links.card?.href else { return }
//                        self?.currentPaymentLink = PaymentAuthorizationService.PaymentLink(href: paymentLink, accessToken: orderLink.token)
//                        completion(orderLink)
//                    }
//                }
        })
        
    }
    
    func mapAcceptableCards(_ cards: [String]) {
        let acceptableCards = PaymentConfigurationHandler.getCards().filter{
            cards.contains(($0.cardType?.rawValue)!)
        }
        self.acceptedCards = acceptableCards
    }
    
    
    private func handlePaymentTypeUpdate(paymentLink : PaymentSDK.PaymentAuthorizationLink)
    {
        log("not implemented")
		log("cache payment link:\(paymentLink)")
        self.paymentAuthorizationLink = paymentLink
    }
    
    private class func paymentMethod(from identity: CardIdentity?) -> PaymentMethod
    {
        guard let cardIdentity = identity, let description = cardIdentity.description
            else {  return PaymentMethod(system: .card, displayName: nil, network: nil, type: .unknown, paymentPass: nil) }
        
        
        return PaymentMethod(system     : .card,
                             displayName: description.displayName,
                             network    : description.network,
                             type       : description.type,
                             paymentPass: nil)
    }
    
    // MARK: - Payment -
    
    func attemptPayment()
    {
        log("")
        // Use token and link from order creation response to pay
        guard let link = self.currentPaymentLink else
        {
            log("❌ Inform user of failed payment. No link available for payment!")
            self.failedPaymentAction?()
            return
        }
        
        log("Attempt payment using the Card Payment Service and cached link and token(from payment type update)")
        log("card: \(self.card.debugDescription)")
        
        CardPaymentService.pay(with : self.card,
							   paymentLink : link,
							   verificationAction: cardVerificationAction!,
							   completion:
        {
            [weak self] (result)  in
            
            guard result.status == .success else
            {
                log("❌ failed payment!")
                self?.failedPaymentAction?()
                self?.delegate?.paymentCompleted(with: .failed)
                return
            }
            
            log("✅ payment success!")
            self?.delegate?.paymentCompleted(with: .success)
            guard let action = self?.paymentSuccessAction else { return }
            action()
        })
    }
}
