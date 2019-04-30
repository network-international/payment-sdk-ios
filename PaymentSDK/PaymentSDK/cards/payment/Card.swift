import Foundation

struct Card
{
    let PAN     : String
    let expiry  : String
    let CVV     : String
    let holder  : String
}

extension Card
{
    static func card(byUpdating card: Card, newPAN: String) ->  Card
    {
        return Card(PAN     : newPAN,
                    expiry  : card.expiry,
                    CVV     : card.CVV,
                    holder  : card.holder)
    }
    
    static func card(byUpdating card: Card, newExpiry: String) ->  Card
    {
        return Card(PAN     : card.PAN,
                    expiry  : newExpiry,
                    CVV     : card.CVV,
                    holder  : card.holder)
    }
    
    static func card(byUpdating card: Card, newCVV: String) ->  Card
    {
        return Card(PAN     : card.PAN,
                    expiry  : card.expiry,
                    CVV     : newCVV,
                    holder  : card.holder)
    }
    
    static func card(byUpdating card: Card, newHolderName: String) ->  Card
    {
        return Card(PAN     : card.PAN,
                    expiry  : card.expiry,
                    CVV     : card.CVV,
                    holder  : newHolderName)
    }
}
