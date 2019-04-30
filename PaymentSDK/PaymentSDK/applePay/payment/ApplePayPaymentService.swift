import Foundation
import PassKit

struct ApplePayPaymentService
{
    static func pay(withPayment payment 	 : PKPayment,
                    paymentLink              : PaymentAuthorizationService.PaymentLink,
                    completion          	 : @escaping (PKPaymentAuthorizationResult) -> Void)
    {
        log("pay with payment:\(payment) \n|| link:\(link)")
        guard let request = self.request(forIdentityToken: paymentLink.accessToken, //TODO: update to use code
                                         link            : paymentLink.href, payment: payment) else
        {
            //TODO: inform merchant of issue
            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
            return
        }
        let session = URLSessionUtility.sharedInstance.defaultSession
        let task = session.dataTask(with: request)
        {
            (data, response, error) in
            handleResponse(response, data:data, error:error, completion:completion)
        }
        task.resume()
    }
    
    static func request(forIdentityToken token  : String,
                        link                    : String,
                        payment                 : PKPayment) -> URLRequest?
    {
        guard var request = RequestHeaders.customJSONTypeRequestWithRequiredHeaders(forURL: link, token: token) else
        {
            return nil
        }

        request.httpBody = payment.token.paymentData
        request.httpMethod = Header.HttpMethod.put
        return request
    }
    
    
    static func handleResponse(_ response   : URLResponse?,
                               data         : Data?,
                               error        : Error?,
                               completion   : @escaping (PKPaymentAuthorizationResult)->Void)
    {
        let code = Response.codeValiditiy(response)
        log("payment attempt code:\(code.value) valid:\(code.valid ? "true" : "false")")
        guard code.valid else
        {
            //TODO: inform merchant of issue
            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
            return
        }
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }
}
