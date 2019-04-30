import Foundation
import PassKit

public final class Interface
{
    public static let sharedInstance = Interface()
    private(set) public var paymentAuthorizationHandler : PaymentAuthorizationHandler?
    private(set) var configuration: Configuration?
    
    private init() {}
    
    public func configure(with configuration: Configuration?)
    {
        self.configuration = configuration
        self.configure()
    }
    
    public func configure(){
        PaymentConfigurationHandler.configure
            {
                (paymentHandler) in
                self.paymentAuthorizationHandler = paymentHandler
        }
    }
}

extension Interface
{
    public struct Configuration
    {
        let merchantIdentifier   : String?
        let merchantCapabilities : PKMerchantCapability?
        
        public init(merchantIdentifier: String?, merchantCapabilities: PKMerchantCapability?)
        {
            self.merchantIdentifier = merchantIdentifier
            self.merchantCapabilities = merchantCapabilities
        }
        
        
    }
}

public struct PaymentAuthorizationLink : Codable
{
    let href : String
    let code : String
    
    public init(href : String, code : String)
    {
        self.href = href
        self.code = code
    }
}
