//
//  CartItemTableViewCell.swift
//  merchant-sample-app
//
//  Created by Niraj Chauhan on 4/23/19.
//  Copyright © 2019 Niraj Chauhan. All rights reserved.
//

import UIKit

class CartItemTableViewCell: UITableViewCell {

    
    @IBOutlet weak var productImage: UIImageView!
    
    @IBOutlet weak var productTitle: UILabel!
    @IBOutlet weak var productQuantity: UILabel!
    @IBOutlet weak var productPrice: UILabel!
    @IBOutlet weak var stepper: UIStepper!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
