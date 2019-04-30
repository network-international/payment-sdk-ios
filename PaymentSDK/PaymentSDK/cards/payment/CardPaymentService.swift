import Foundation
import PassKit

enum CardPaymentService
{
    static func pay(with card   			 : Card,
                    paymentLink              : PaymentAuthorizationService.PaymentLink,
					verificationAction       : @escaping CardVerificationAction,
                    completion  			 : @escaping (PKPaymentAuthorizationResult) -> Void)
    {
        log("pay with card:\(card) \n|| \npaymentAuthorizationLink:\(paymentLink)\n")
		// fetch cookie and payment link using paymentAuthorizationLink url and code
        
        pay(with: card,
            link: paymentLink,
            verificationAction: verificationAction,
            completion: completion)
        
//        PaymentAuthorizationService.fetchPaymentLink(using: paymentAuthorizationLink,
//                                                     completion:
//            { paymentLink in pay(with: card,
//                                 link: paymentLink,
//                                 verificationAction: verificationAction,
//                                 completion: completion) })
    }

	private static func pay(with card	: Card,
							link 		: PaymentAuthorizationService.PaymentLink?,
							verificationAction : @escaping CardVerificationAction,
							completion  : @escaping (PKPaymentAuthorizationResult) -> Void)
	{
		log("🔎 pay with card:\(card) \n|| link:\(String(describing: link))")
		guard let paymentLink = link else
		{
			showFailure(using: completion)
			return
		}

		// use payment link to attemp payment
		guard let request = self.request(forIdentityToken: paymentLink.accessToken,
										 link            : paymentLink.href,
										 card            : card) else
		{
			//TODO: inform merchant of issue
			showFailure(using: completion)
			return
		}
		let session = URLSessionUtility.sharedInstance.defaultSession
		let task = session.dataTask(with: request)
		{
			(data, response, error) in
			handleResponse(response, data:data,
						   error:error,
						   verificationAction: verificationAction,
						   completion:completion)
		}
		task.resume()
	}
    
    private static func request(forIdentityToken token  : String,
                                link                    : String,
                                card                    : Card) -> URLRequest?
    {
        guard var request = RequestHeaders.customJSONTypeRequestWithRequiredHeaders(forURL: link, token: token) else
        {
            return nil
        }
        let requestBody = self.requestBody(for: card)
        do {
            let json = try JSONEncoder().encode(requestBody)
            request.httpBody = json
            request.httpMethod = Header.HttpMethod.put
            return request
        }
        catch { return nil }
    }
    
    private static func requestBody(for card: Card) -> RequestBody
    {
        let expiry = card.expiry.split(separator: "/")
        let date = "20" + String(expiry.last!) + "-" + String(expiry.first!)
        
        return RequestBody(pan           : card.PAN,
                           expiry        : date,//"2025-02",
                           cvv           : card.CVV,
                           cardholderName: card.holder)
    }
    
    private struct RequestBody : Codable
    {
        let pan             : String
        let expiry          : String
        let cvv             : String
        let cardholderName  : String
    }
    
    static func handleResponse(_ response   : URLResponse?,
                               data         : Data?,
                               error        : Error?,
							   verificationAction : @escaping CardVerificationAction,
                               completion   : @escaping (PKPaymentAuthorizationResult)->Void)
    {
        let code = Response.codeValiditiy(response)
        log("payment attempt code:\(code.value) valid:\(code.valid ? "true" : "false")")
        guard code.valid else
        {
            if let theData = data
            {
                log("\n\n👉 Data: \(String(data: theData, encoding: .utf8)?.description ?? "")\n\n")
            }
            
            if let theError = error
            {
                log("Error: \( theError.localizedDescription )")
            }
            
            //TODO: inform merchant of issuelet errors = error != nil ? [error!] : nil
            showFailure(using: completion)
            return
        }

		guard let payloadData = data  else {
			// make no data error type
			showFailure(using: completion)
			return
		}

		handleCardPaymentSuccess(data: payloadData,
								 verificationAction: verificationAction,
								 completion: completion)
    }

	static func handleCardPaymentSuccess(data: Data,
										 verificationAction : @escaping CardVerificationAction,
										 completion: @escaping (PKPaymentAuthorizationResult)->Void)
	{
		let status = CardPaymentParser.cardPaymentStatus(from: data)
		log("\(status)")
		switch status {
		case .success					: showSuccess(using: completion)
		case .failure					: showFailure(using: completion)
		case .requires3DS(let payload)  : show3DSFlow(using: payload,
													  verificationAction: verificationAction,
													  completion: completion)

		}
	}

	static func show3DSFlow(using payload: CardPaymentStatus.Payload3DS,
							verificationAction : @escaping CardVerificationAction,
							completion: @escaping (PKPaymentAuthorizationResult)->Void)
	{
		log("payload:\(payload)")

		verificationAction(payload, { success in
			guard success else {
				showFailure(using: completion)
				return
			}
			showSuccess(using: completion)
		})
	}

	static func showFailure(using completion: @escaping (PKPaymentAuthorizationResult)->Void)
	{
		log("")
		completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
	}

	static func showSuccess(using completion: @escaping (PKPaymentAuthorizationResult)->Void)
	{
		log("")
		completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
	}
}
