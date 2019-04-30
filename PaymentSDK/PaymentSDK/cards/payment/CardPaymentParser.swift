import Foundation

struct CardPaymentParser
{
	static func cardPaymentStatus(from data: Data) -> CardPaymentStatus
	{
		guard let response = responseObject(from: data) else { return .failure }
		return cardPaymentStatus(from: response)
	}

	private static func responseObject(from data: Data) -> CardPaymentResponse?
	{
		let decoder = JSONDecoder()
		do {
			let response = try decoder.decode(CardPaymentResponse.self, from: data)
			return response
		}
		catch
		{
			return nil
		}
	}

	private static func cardPaymentStatus(from response: CardPaymentResponse) -> CardPaymentStatus
	{
		switch response.state
		{
		case .AUTHORISED: return .success
		case .CAPTURED	: return .success
		case .FAILED	: return .failure
		case .AWAIT_3DS	: return cardPaymentStatusFor3DS(from: response)
		}
	}

	private static func cardPaymentStatusFor3DS(from response: CardPaymentResponse) -> CardPaymentStatus
	{
		guard let values3DS = response.threeDS else { return .failure }
		guard let termURL = response.links.termURL else { return .failure }
        guard let payload = payload3DS(from: values3DS, termURL: termURL.href) else {
            return .failure
        }
		return .requires3DS(payload: payload)
	}


	private static func payload3DS(from threeDS: CardPaymentResponse.ThreeDS, termURL: String) -> CardPaymentStatus.Payload3DS?
	{
        guard let url = threeDS.url,
        let paReq = threeDS.paReq,
        let md = threeDS.md
        else {
            log("3DS URL Missing")
            return nil
        }
        
		return .init(url:     url,
					 paReq:   paReq,
					 md:      md,
					 termURL: termURL)
	}
}

enum CardPaymentStatus
{
	case failure
	case success
	case requires3DS(payload: Payload3DS)

	struct Payload3DS {
		let url     : String
		let paReq   : String
		let md      : String
		let termURL : String
	}
}

private struct CardPaymentResponse: Codable
{
	let state   : State
	let threeDS : ThreeDS?
	let links   : Links

	struct ThreeDS: Codable
	{
		let url   : String?
		let paReq : String?
		let md    : String?

		enum CodingKeys: String, CodingKey
		{
			case url 	= "acsUrl"
			case paReq 	= "acsPaReq"
			case md 	= "acsMd"
		}
	}


	struct Links: Codable
	{
		let termURL: Link?

		enum CodingKeys: String, CodingKey
		{
			case termURL = "cnp:3ds"
		}
	}

	enum CodingKeys: String, CodingKey
	{
		case state
		case threeDS = "3ds"
		case links = "_links"
	}

	enum State: String, Codable {
		case AUTHORISED
		case CAPTURED
		case AWAIT_3DS
		case FAILED
	}
}
