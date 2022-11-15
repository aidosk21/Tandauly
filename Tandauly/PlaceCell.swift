//
//  PlaceTableViewCell.swift
//  Tandauly
//
//  Created by Aidos on 27.10.2022.
//

import UIKit
import Cosmos

class PlaceCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var placeImage: UIImageView! {
        didSet {
            placeImage?.layer.cornerRadius = (placeImage.frame.size.height) / 2
            placeImage?.clipsToBounds = true
            placeImage.contentMode = .scaleAspectFill
        }
    }
    @IBOutlet weak var cosmosView: CosmosView! {
        didSet {
            cosmosView.settings.updateOnTouch = false
        }
    }
    
    func setup(place: Place) {
        nameLabel.text = place.name
        locationLabel.text = place.location
        typeLabel.text = place.type
        cosmosView.rating = place.rating
        placeImage.image = UIImage(data: place.imageData!)
    }
    

    
   
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
