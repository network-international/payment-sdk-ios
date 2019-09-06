//
//  JsonPrettyprint.swift
//  NISdk
//
//  Created by Johnny Peter on 23/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation

extension Encodable {
    func prettyPrint() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let prettyPrintedOutput = try! encoder.encode(self)
        print(String(data: prettyPrintedOutput, encoding: .utf8)!)
    }
}
