import Foundation

struct PaymentAuthorizationParser
{
	// MARK: - Order -

	//TODO: return result type (value, error)
	static func cardPaymentLink(from data: Data?) -> Link?
	{
		guard let response = orderResponseObject(from: data) else
		{
			return nil
		}

		return response.embedded.payment.first?.links.card
	}

    static func orderResponseObject(from data: Data?) -> Order?
	{
		guard let theData = data else {
			return nil
		}

		let decoder = JSONDecoder()
		do {
			let response = try decoder.decode(Order.self, from: theData)
			return response
		}
		catch
		{
			return nil
		}
	}

	private static func token(from headers: [AnyHashable: Any]?) -> String?
	{
		guard let httpHeaders = headers else { return nil }
		guard httpHeaders.count > 0 else { return nil }
		for (key, value) in httpHeaders
		{
			if  let keyString = key as? String,
				let valueString = value as? String
			{
				if keyString == "Set-Cookie" && valueString.starts(with: "payment")
				{
					return valueString
				}
			}
		}
		return nil
	}

	// MARK: - Payment Authorization -

	//TODO: return result type (value, error)
	static func orderLink(from data: Data?, response: URLResponse? ) -> PaymentAuthorizationService.OrderLink?
	{
		guard let responseObject = responseObject(from: data) else
		{
			return nil
		}

		let httpHeaders = headers(from: response)
		guard let orderLink = orderLink(from: responseObject, headers: httpHeaders) else
		{
			return nil
		}

		return orderLink
	}

	private static func headers(from response: URLResponse?) -> [AnyHashable: Any]?
	{
		guard let urlResponse = response as? HTTPURLResponse else { return nil }
		return urlResponse.allHeaderFields
	}

	private static func orderLink(from response: PaymentAuthorizationResponse,
								  headers	   : [AnyHashable: Any]? ) -> PaymentAuthorizationService.OrderLink?
	{
		guard let token = token(from: headers) else { return nil }
		return .init(href: response.links.order.href,
					 token: token)

	}

	private static func responseObject(from data: Data?) -> PaymentAuthorizationResponse?
	{
		guard let theData = data else {
			return nil
		}

		let decoder = JSONDecoder()
		do {
			let response = try decoder.decode(PaymentAuthorizationResponse.self, from: theData)
			return response
		}
		catch
		{
			return nil
		}
	}
}

private struct PaymentAuthorizationResponse : Codable
{
	let links : TransactionLinks

	enum CodingKeys: String, CodingKey
	{
		case links = "_links"
	}

	struct TransactionLinks: Codable
	{
		let order  : Link

		enum CodingKeys: String, CodingKey
		{
			case order = "cnp:order"
		}
	}
}


