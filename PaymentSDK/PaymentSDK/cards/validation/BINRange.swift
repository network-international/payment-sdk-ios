import Foundation


/// Structure that represents a BIN range (the first 6 digits of a Payment Card PAN). This range is enough to know the
/// type of card including the issuer, the brand, cred/debit, the possible PAN length values. The digits count is
/// used as a optimisation, for deciding the match strenght, it is just the number of digits of the start and end ints.
struct BINRange : Equatable
{
    /// The start of the range. Inclusive. Visa start could be 4 and end would also be 4.
    let start       : Int
    
    /// The end of the range. Inclusive. If visa was defined as start 40, the end would be 49. As 5 would not be visa.
    let end         : Int
    
    /// The number of digits that the start and end property have. Used as a convenience for finding the most accurate match.
    let digitsCount : Int
    
    /// The valid PAN lengths for the BIN range. Must contain one value, but could have as many as 3(visa).
    let PANLengths  : [Int]
    
    /// Optional label that describes a range. Visa Credit, Visa Debit, etc...
    let label       : String?
    
    /// Convenince init method, that sets the optional label to nil.
    ///
    /// - Parameters:
    ///   - start: The start of the range. Inclusive. Visa start could be 4 and end would also be 4.
    ///   - end: The end of the range. Inclusive. If visa was defined as start 40, the end would be 49. As 5 would not be visa.
    ///   - digitsCount: The number of digits that the start and end property have. Used as a convenience for finding the most accurate match.
    ///   - PANLengths: The valid PAN lengths for the BIN range. Must contain one value, but could have as many as 3(visa).
    init(start      : Int,
         end        : Int,
         digitsCount: Int,
         PANLengths : [Int])
    {
        self.start          = start
        self.end            = end
        self.digitsCount    = digitsCount
        self.PANLengths     = PANLengths
        self.label          = nil
    }
    
    
    /// Init method for the BIN range struct.
    ///
    /// - Parameters:
    ///   - start: The start of the range. Inclusive. Visa start could be 4 and end would also be 4.
    ///   - end: The end of the range. Inclusive. If visa was defined as start 40, the end would be 49. As 5 would not be visa.
    ///   - digitsCount: The number of digits that the start and end property have. Used as a convenience for finding the most accurate match.
    ///   - PANLengths: The valid PAN lengths for the BIN range. Must contain one value, but could have as many as 3(visa).
    ///   - label: Optional label that describes a range. Visa Credit, Visa Debit, etc...
    init(start       : Int,
         end         : Int,
         digitsCount : Int,
         PANLengths  : [Int],
         label       : String?)
    {
        self.start          = start
        self.end            = end
        self.digitsCount    = digitsCount
        self.PANLengths     = PANLengths
        self.label          = label
    }
}

