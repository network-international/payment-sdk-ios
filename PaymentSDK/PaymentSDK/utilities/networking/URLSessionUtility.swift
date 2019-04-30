import Foundation

final class URLSessionUtility
{
    static let sharedInstance = URLSessionUtility()
    
    let defaultSession : URLSession
    
    private init()
    {
        self.defaultSession = URLSession(configuration: URLSessionUtility.defaultConfiguration())
    }
    
    private class func defaultConfiguration() -> URLSessionConfiguration
    {
        return URLSessionConfiguration.ephemeral
    }
}

struct RequestHeaders
{
    static func requestByAddingAuthorizationHeader(toRequest request: URLRequest,
                                                   token            : String) -> URLRequest
    {
        var updatedRequest = request
        let tokenValue = Header.value.bearer + token
        updatedRequest.addValue(tokenValue, forHTTPHeaderField: Header.key.authorization)
        return updatedRequest
    }
    
    static func requestWithRequiredHeaders(forURL urlString : String,
                                           token            : String) -> URLRequest?
    {
        let urlObj = URL(string: urlString)
        guard let url = urlObj  else
        {
            return nil
        }
        
        var request = URLRequest(url: url)
        request = requestByAddingAuthorizationHeader(toRequest  : request,
                                                     token      : token)
        request.addValue(Header.value.appJSON_UTF8,     forHTTPHeaderField: Header.key.contentType)
        request.addValue(Header.value.OSName,           forHTTPHeaderField: Header.key.clientOsName)
        return request
    }
    
    static func customJSONTypeRequestWithRequiredHeaders(forURL urlString : String,
                                                         token            : String) -> URLRequest?
    {
        let urlObj = URL(string: urlString)
        guard let url = urlObj  else
        {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.addValue(Header.value.JSON_2_VND_NI,   forHTTPHeaderField: Header.key.accept)
		request.addValue(Header.value.JSON_2_VND_NI,   forHTTPHeaderField: Header.key.contentType)
		request.addValue(token, 					   forHTTPHeaderField: Header.key.cookie)
        request.addValue(Header.value.OSName,          forHTTPHeaderField: Header.key.clientOsName)
        return request
    }

	static func paymentAuthorizationRequest(forURL urlString : String,
											code             : String) -> URLRequest?
	{
		let urlObj = URL(string: urlString)
		guard let url = urlObj  else
		{
			return nil
		}

		var request = URLRequest(url: url)

		request.addValue(Header.value.appFormURLEncoded,	forHTTPHeaderField: Header.key.contentType)
		request.addValue(Header.value.JSON_2_VND_NI,        forHTTPHeaderField: Header.key.accept)
		request.addValue(Header.value.OSName,          		forHTTPHeaderField: Header.key.clientOsName)
		request.httpMethod = Header.HttpMethod.post
		request.httpBody   = "code=\(percentEscape(code))".data(using: .utf8)
		return request
	}

	static func percentEscape(_ string: String) -> String
	{
		var validCharacters = CharacterSet.alphanumerics
		validCharacters.insert(charactersIn: "-._* ")
		return string.addingPercentEncoding(withAllowedCharacters: validCharacters)!.replacingOccurrences(of: " ", with: "+")
	}

	static func orderInfoRequest(forURL urlString : String,
								 token            : String) -> URLRequest?
	{
		let urlObj = URL(string: urlString)
		guard let url = urlObj  else
		{
			return nil
		}

		var request = URLRequest(url: url)

		request.addValue(token,				  forHTTPHeaderField: Header.key.setCookie)
		request.addValue(Header.value.OSName, forHTTPHeaderField: Header.key.clientOsName)
		request.httpMethod = Header.HttpMethod.get
		return request
	}
}

struct Header
{
    struct key
    {
        static let authorization    = "Authorization"
        static let contentType      = "Content-Type"
        static let clientOsName     = "clientOsName"
        static let currency         = "currencyCode"
		static let accept           = "Accept"
		static let setCookie        = "Set-Cookie"
		static let cookie           = "Cookie"
    }
    
    struct value
    {
        static let OSName       		= "iOS"
        static let bearer       		= "Bearer "
        static let appJSON_UTF8 		= "application/json; charset=utf-8"
		static let JSON_2_VND_NI  		= "application/vnd.ni-payment.v2+json"
		static let appFormURLEncoded 	= "application/x-www-form-urlencoded"
    }
    
    struct HttpMethod
    {
        static let get    = "GET"
        static let post   = "POST"
        static let patch  = "PATCH"
        static let put    = "PUT"
        static let delete = "DELETE"
    }
}
