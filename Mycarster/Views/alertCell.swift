//
//  alertCell.swift
//  Mycarster
//
//  Created by Shanbo on 1/17/18.
//  Copyright © 2018 Mycarster. All rights reserved.
//

import UIKit

class alertCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var msgLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
