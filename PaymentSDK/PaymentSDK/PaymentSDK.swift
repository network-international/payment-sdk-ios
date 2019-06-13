import Foundation
import PassKit

@objc public final class Interface: NSObject
{
    @objc public static let sharedInstance = Interface()
    @objc public var paymentAuthorizationHandler : PaymentAuthorizationHandler?
    private(set) var configuration: Configuration?
    
    private override init() { super.init() }
    
    @objc public func configure(with configuration: Configuration?)
    {
        self.configuration = configuration
        self.configure()
    }
    
    @objc public func configure(){
        PaymentConfigurationHandler.configure
            {
                (paymentHandler) in
                self.paymentAuthorizationHandler = paymentHandler
        }
    }
}


extension Interface
{
    @objc public class Configuration: NSObject
    {
        @objc public var merchantIdentifier: String?
        
        @objc public init(merchantIdentifier: String?)
        {
            self.merchantIdentifier = merchantIdentifier
        }

    }
}

@objc public class PaymentAuthorizationLink : NSObject
{
    let href : String
    let code : String
    
    @objc public init(href : String, code : String)
    {
        self.href = href
        self.code = code
    }
}
