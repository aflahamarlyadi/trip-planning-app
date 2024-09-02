//
//  LocationTableViewCell.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 24/4/2024.
//

import UIKit

class LocationTableViewCell: UITableViewCell {

    @IBOutlet weak var locationImageView: UIImageView!
    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var locationAddressLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
