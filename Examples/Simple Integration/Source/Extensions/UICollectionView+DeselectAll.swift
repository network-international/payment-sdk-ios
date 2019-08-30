//
//  uicollectionView+DeselectAll.swift
//  Simple Integration
//
//  Created by Johnny Peter on 23/08/19.
//  Copyright © 2019 Network International. All rights reserved.
//

import Foundation
import UIKit

typealias resetHandler = (UICollectionViewCell?) -> Void

extension UICollectionView {
    func deselectAllItems(animated: Bool, resetHandler: resetHandler?) {
        guard let selectedItems = indexPathsForSelectedItems else { return }
        for indexPath in selectedItems {
            deselectItem(at: indexPath, animated: animated)
            if let resetHandler = resetHandler {
                let cell = cellForItem(at: indexPath) ?? nil
                resetHandler(cell)
            }
        }
    }
}
