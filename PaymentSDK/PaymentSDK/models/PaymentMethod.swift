import Foundation
import PassKit

public struct PaymentMethod
{
    public let system      : System
    public let displayName : String?
    public let network     : PKPaymentNetwork?
    public let type        : PKPaymentMethodType
    public let paymentPass : PKPaymentPass?
    
    public enum System
    {
        case card
        case applePay
    }
}

public extension PaymentMethod
{
    public static func method(fromPK paymentMethod: PKPaymentMethod) -> PaymentMethod
    {
        return PaymentMethod(system     : .applePay,
                             displayName: paymentMethod.displayName,
                             network    : paymentMethod.network,
                             type       : paymentMethod.type,
                             paymentPass: paymentMethod.paymentPass)
    }
}
