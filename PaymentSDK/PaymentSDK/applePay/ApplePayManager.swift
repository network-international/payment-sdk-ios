import Foundation
import PassKit

@objc class ApplePayManager : NSObject, PKPaymentAuthorizationViewControllerDelegate
{
    weak var delegate : PaymentDelegate?
    weak var applePayDelegate : ApplePayDelegate?
    var apiInteractor : PaymentAuthorizationApiInteractor?
    
    //MARK: - Cancel/Close -
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController)
    {
        log("paymentAuthorizationViewControllerDidFinish")
        controller.dismiss(animated: true) {
            log("dismissed")
        }
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didAuthorizePayment payment: PKPayment,
                                            handler completion: @escaping (PKPaymentAuthorizationResult) -> Void)
    {
        guard let applePayLink = apiInteractor?.applePayLink else {
            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
            return
        }
        log("Making apple pay request")
        ApplePayPaymentService.pay(withPayment                : payment,
                                   paymentLink : applePayLink,
                                   completion: {
                                    [weak self]
                                    status in
                                    let isPaymentSuccess = PKPaymentAuthorizationStatus.success.rawValue == status.status.rawValue
                                    if(isPaymentSuccess){
                                        self?.apiInteractor?.getOrder(){
                                            (order, token) in
                                            guard let state = order?.embedded.payment.first?.state, state == "FAILED" else {
                                                self?.delegate?.paymentCompleted(with: .success)
                                                completion(status)
                                                return
                                            }
                                            self?.delegate?.paymentCompleted(with: .failed)
                                            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
                                        }
                                    }else{
                                        self?.delegate?.paymentCompleted(with: .failed)
                                        completion(status)
                                    }
                                    
        })
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didSelect paymentMethod: PKPaymentMethod,
                                            handler completion: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void)
    {
        log("did update payment method:\(paymentMethod)")
        let method = PaymentMethod.method(fromPK: paymentMethod)
        self.applePayDelegate?.applePayPaymentMethodUpdated(didSelect: method, handler: {
            updatedPaymentMethod in completion(updatedPaymentMethod)
        })
        
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didSelect shippingMethod: PKShippingMethod,
                                            handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void)
    {
        log("did update shipping method:\(shippingMethod)")
        self.applePayDelegate?.applePayShippingMethodUpdated(didSelect: shippingMethod, handler: {
            updatedShippingMethod in completion(updatedShippingMethod)
        })
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didSelectShippingContact contact: PKContact,
                                            handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void)
    {
        log("did update shipping contact:\(contact)")
        self.applePayDelegate?.applePayContactUpdated(didSelect: contact, handler: {
            updatedContact in completion(updatedContact)
        })
    }
}
