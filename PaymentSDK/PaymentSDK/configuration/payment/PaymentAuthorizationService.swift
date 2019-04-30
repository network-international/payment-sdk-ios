import Foundation

struct PaymentAuthorizationService
{

	struct OrderLink {
		let href: String
		let token: String
	}

	struct PaymentLink {
		let href		: String
		let accessToken : String
	}

	static func fetchPaymentLink(using paymentAuthorizationLink : PaymentAuthorizationLink,
								 completion						: @escaping (PaymentLink?) -> Void)
	{
		fetchOrderLink(using: paymentAuthorizationLink,
					   completion:
		{
			orderLink in fetchPaymentLink(using: orderLink, completion: completion)
		})
	}

	private static func fetchPaymentLink(using orderLink : OrderLink?,
										 completion		 : @escaping (PaymentLink?) -> Void)
	{

		log("orderLink:\(String(describing: orderLink))")
		guard let order = orderLink else
		{
			completion(nil)
			return
		}

		guard let request = self.request(for: order) else
		{
			//TODO: inform merchant of issue
			completion(nil)
			return
		}
		let session = URLSessionUtility.sharedInstance.defaultSession
		let task = session.dataTask(with: request)
		{
			(data, response, error) in
			handleResponse(response, data:data, error:error, token: order.token, completion:completion)
		}
		task.resume()
	}


    static func fetchOrderLink(using paymentAuthorizationLink : PaymentAuthorizationLink,
									   completion					  : @escaping (OrderLink?) -> Void)
	{
		log("paymentAuthorizationLink:\(String(describing: paymentAuthorizationLink))")
		guard let request = self.request(for: paymentAuthorizationLink) else
		{
			//TODO: inform merchant of issue
			completion(nil)
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

	private static func request(for orderLink : OrderLink) -> URLRequest?
	{
		guard let request = RequestHeaders.orderInfoRequest(forURL: orderLink.href, token: orderLink.token) else
		{
			return nil
		}
		return request
	}

	private static func request(for paymentAuthorizationLink : PaymentAuthorizationLink) -> URLRequest?
	{
		let link = paymentAuthorizationLink.href
		let code = paymentAuthorizationLink.code
		guard let request = RequestHeaders.paymentAuthorizationRequest(forURL: link, code: code) else
		{
			return nil
		}
		return request
	}

	static func handleResponse(_ response   : URLResponse?,
							   data         : Data?,
							   error        : Error?,
							   completion   : @escaping (OrderLink?)->Void)
	{
		let code = Response.codeValiditiy(response)
		log("payment attempt code:\(code.value) valid:\(code.valid ? "true" : "false")")
		guard code.valid else
		{
			if let theData = data
			{
				log("Data: \(String(data: theData, encoding: .utf8)?.description ?? "")")
			}

			if let theError = error
			{
				log("Error: \( theError.localizedDescription )")
			}

			completion(nil)
			return
		}

		guard let orderLink = PaymentAuthorizationParser.orderLink(from: data, response: response) else
		{
			completion(nil)
			return
		}
		completion(orderLink)
	}

	// MARK: - Order Info -

	static func handleResponse(_ response   : URLResponse?,
							   data         : Data?,
							   error        : Error?,
							   token		: String,
							   completion   : @escaping (PaymentLink?) -> Void)
	{
		let code = Response.codeValiditiy(response)
		log("payment attempt code:\(code.value) valid:\(code.valid ? "true" : "false")")
		guard code.valid else
		{
			if let theData = data
			{
				log("Data: \(String(data: theData, encoding: .utf8)?.description ?? "")")
			}

			if let theError = error
			{
				log("Error: \( theError.localizedDescription )")
			}

			completion(nil)
			return
		}

		guard let paymentLink = PaymentAuthorizationParser.cardPaymentLink(from: data) else
		{
			completion(nil)
			return
		}
		let cardPayment = paymentLink.href
		let link = PaymentLink(href: cardPayment, accessToken: token)
		log("link:\(String(describing: link))")
		completion(link)
	}
    
    
    static func getOrderDetails(using orderLink: OrderLink, completion: @escaping (Order?) -> Void) {
        let session = URLSessionUtility.sharedInstance.defaultSession
        guard let url = URL(string: orderLink.href) else { return }
        let task = session.dataTask(with: url)
        {
            (data, response, error) in
            
            guard let order = PaymentAuthorizationParser.orderResponseObject(from: data) else
            {
                completion(nil)
                return
            }
            completion(order)
        }
        task.resume()
    }
    
}
