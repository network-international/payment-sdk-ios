//
//  Collection+Pairs.swift
//  NISdk
//
//  Created by Johnny Peter on 25/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

extension Collection {
    var pairs: [SubSequence] {
        var startIndex = self.startIndex
        let count = self.count
        let n = count/2 + count % 2
        return (0..<n).map { _ in
            let endIndex = index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer { startIndex = endIndex }
            return self[startIndex..<endIndex]
        }
    }
}
