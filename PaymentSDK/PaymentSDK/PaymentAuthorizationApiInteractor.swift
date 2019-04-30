import Foundation

class PaymentAuthorizationApiInteractor {
    
    private(set) var orderLink : PaymentAuthorizationService.OrderLink?
    private(set) var applePayLink : PaymentAuthorizationService.PaymentLink?
    private(set) var cardPayLink : PaymentAuthorizationService.PaymentLink?
    
    func doAuthorization(with authorizationLink: PaymentAuthorizationLink,
                         handler completion : @escaping (AuthorizationStatus, Order?) -> Void){
        PaymentAuthorizationService.fetchOrderLink(using: authorizationLink)
        { [weak self]
            orderLink in
            guard let orderLink = orderLink else
            {
                completion(.failed, nil)
                return
            }
            self?.orderLink = orderLink
            self?.getOrder(){
                (order, token) in
                
                if let cardPayLink = order?.embedded.payment.first?.links.card {
                    self?.cardPayLink = PaymentAuthorizationService.PaymentLink(href: cardPayLink.href, accessToken: orderLink.token)
                }
                if let applePayLink = order?.embedded.payment.first?.links.applePay {
                    self?.applePayLink = PaymentAuthorizationService.PaymentLink(href: applePayLink.href, accessToken: orderLink.token)
                }
                completion(.success, order)
            }
        }
    }
    
    func getOrder(completion: @escaping (Order?, String) -> Void){
        guard let orderLink = self.orderLink else {
            completion(nil, "")
            return
        }
        PaymentAuthorizationService.getOrderDetails(using: orderLink)
        {
            order in
            completion(order, orderLink.token)
        }
    }
}
