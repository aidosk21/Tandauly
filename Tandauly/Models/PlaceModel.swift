//
//  PlaceModel.swift
//  Tandauly
//
//  Created by Aidos on 27.10.2022.
//

import RealmSwift

class Place: Object {
     @objc dynamic var name: String = ""
     @objc dynamic var location: String?
     @objc dynamic var type: String?
     @objc dynamic var imageData: Data?
     @objc dynamic var rating = 0.0
    
    


    convenience init(name: String, location: String? = nil, type: String? = nil, imageData: Data? = nil, rating: Double) {
        self.init()
        self.name = name
        self.location = location
        self.type = type
        self.imageData = imageData
        self.rating = rating
    }
    
}


