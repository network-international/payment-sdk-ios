import Foundation

struct ThreeDSURLUtility
{

	enum K
	{
		static let status3DSKey = "3ds_status"
	}

	static func result(from url: URL?) -> String?
	{
		guard let resultURL = url else { return nil }
		guard let components = URLComponents(url: resultURL, resolvingAgainstBaseURL: false) else { return nil }

		guard let items = components.queryItems else {
			log("no items for:\(components)")
			return resultFromFragment(components.fragment, host: components.host)
		}
		return resultFromQueryItems(items)
	}

	static func resultFromQueryItems(_ items: [URLQueryItem]) -> String?
	{
		let value = items.first(where: { $0.name == K.status3DSKey })?.value
		log("value:\(String(describing: value))")
		return value
	}

	static func resultFromFragment(_ fragment: String?, host: String?) -> String?
	{
		guard let fragment = fragment, let host = host else {
			return nil
		}

		guard let noFragmentUrl = URL(string: host + fragment) else { return nil }
		log("noFragmentUrl value:\( noFragmentUrl)")
		return result(from: noFragmentUrl)
	}
}
