import Foundation

struct Link : Codable
{
    let href : String
}

struct Response
{
    static func codeValiditiy(_ response: URLResponse?) -> Code
    {
        guard let urlResponse = response as? HTTPURLResponse
            else
        {
            return Code(value: 0, valid: false)
        }
        
        let statusCode = urlResponse.statusCode
        
        if statusCode < 200 || statusCode > 299
        {
            return Code(value: statusCode, valid: false)
        }
        return Code(value: statusCode, valid: true)
    }
    
    struct Code
    {
        let value : Int
        let valid : Bool
    }
}

extension Link: CustomStringConvertible
{
    var description: String
    {
        return "<\(type(of: self)): href: \(href)"
    }
}
