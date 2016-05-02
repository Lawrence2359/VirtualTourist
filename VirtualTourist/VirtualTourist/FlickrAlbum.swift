//
//  FlickrAlbums.swift
//  VirtualTourist
//
//  Created by 2359 Lawrence on 29/4/16.
//  Copyright © 2016 2359 Media Pte Ltd. All rights reserved.
//

import UIKit
import CoreData

class FlickrAlbum : NSManagedObject {
    
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let Name = "name"
    }
    
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var name: String
    @NSManaged var images: [FlickrImage]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("FlickrAlbum", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        latitude = dictionary[Keys.Latitude] as! NSNumber
        longitude = dictionary[Keys.Longitude] as! NSNumber
        name = dictionary[Keys.Name] as! String
        
    }
    
}
