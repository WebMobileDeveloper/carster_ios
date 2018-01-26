//
//  itemCell.swift
//  Mycarster
//
//  Created by Shanbo on 1/17/18.
//  Copyright © 2018 Mycarster. All rights reserved.
//

import UIKit

class itemCell: UITableViewCell {

    @IBOutlet weak var itemLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var backView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
