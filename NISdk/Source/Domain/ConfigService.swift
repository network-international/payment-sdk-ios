//
//  ConfigService 2.swift
//  NISdk
//
//  Created by Prasath R on 11/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//



//
//  ConfigService.swift
//  Pods
//
//  Created by Prasath R on 10/02/26.
//

import Foundation
import PassKit

@objc protocol ConfigService {
    @objc func getInvoiceConfig(for url: String,
                        using accessToken: String,
                        with completion: @escaping (HttpResponseCallback))
}