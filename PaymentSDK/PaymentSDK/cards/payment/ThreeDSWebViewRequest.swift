import Foundation

enum ThreeDSWebViewRequest
{
	static func request(from payload: CardPaymentStatus.Payload3DS) -> URLRequest?
	{
		guard let url = URL(string: payload.url) else
		{
			return nil
		}

		return paymentAuthorizationRequest(forURL: url, payload: payload)
	}

	private static func paymentAuthorizationRequest(forURL url : URL,
													payload	   : CardPaymentStatus.Payload3DS) -> URLRequest?
	{
		var request = URLRequest(url: url)
		let body = httpBody(from: payload)

		request.addValue(Header.value.appFormURLEncoded,	forHTTPHeaderField: Header.key.contentType)
		request.httpMethod = Header.HttpMethod.post
		request.httpBody   = body
		return request
	}

	private static func httpBody(from payload: CardPaymentStatus.Payload3DS) -> Data?
	{

		var body = "PaReq"   + "=" + RequestHeaders.percentEscape(payload.paReq) + "&"
		body +=    "TermUrl" + "=" + RequestHeaders.percentEscape(payload.termURL) + "&"
		body +=    "MD"		 + "=" + RequestHeaders.percentEscape(payload.md)

		return body.data(using: .utf8)
	}
}
