import Foundation
import PassKit

@objc public class PaymentMethod: NSObject
{
    public var system      : System
    public var displayName : String? = nil
    public var network     : PKPaymentNetwork? = nil
    public var type        : PKPaymentMethodType
    public var paymentPass : PKPaymentPass? = nil
    
    public enum System
    {
        case card
        case applePay
    }
    
    init(system: System,
         displayName: String?,
         network: PKPaymentNetwork?,
         type: PKPaymentMethodType,
         paymentPass: PKPaymentPass?) {
        
        self.system = system
        self.displayName = displayName
        self.network = network
        self.type = type
        self.paymentPass = paymentPass
    }
    
}

public extension PaymentMethod
{
    static func method(fromPK paymentMethod: PKPaymentMethod) -> PaymentMethod
    {
        return PaymentMethod(system     : .applePay,
                             displayName: paymentMethod.displayName,
                             network    : paymentMethod.network,
                             type       : paymentMethod.type,
                             paymentPass: paymentMethod.paymentPass)
    }
}
