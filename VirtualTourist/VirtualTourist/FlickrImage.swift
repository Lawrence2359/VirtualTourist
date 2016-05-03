//
//  FlickrImage.swift
//  VirtualTourist
//
//  Created by 2359 Lawrence on 29/4/16.
//  Copyright © 2016 2359 Media Pte Ltd. All rights reserved.
//

import UIKit
import CoreData

class FlickrImage : NSManagedObject {

    struct Keys {
        static let Farm = "farm"
        static let ID = "id"
        static let Secret = "secret"
        static let Server = "server"
    }
    
    @NSManaged var farm: NSNumber!
    @NSManaged var photoID: String!
    @NSManaged var secret: String!
    @NSManaged var server: String!
    @NSManaged var imagePath: String!
    @NSManaged var filePath: String!
    @NSManaged var album: FlickrAlbum?
    @NSManaged var selected: NSNumber!
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("FlickrImage", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        farm = dictionary[Keys.Farm] as? NSNumber ?? 1
        photoID = dictionary[Keys.ID] as? String ?? ""
        secret = dictionary[Keys.Secret] as? String ?? ""
        server = dictionary[Keys.Server] as? String ?? ""
        imagePath = flickrImageURL()
        filePath = filePathURL()
        selected = 0
    }

    func flickrImageURL(size:String = "m") -> String {
        return "http://farm\(farm!).staticflickr.com/\(server!)/\(photoID!)_\(secret!)_m.jpg"
    }
    
    func filePathURL() -> String {
        return "\(photoID!)\(secret!).jpg"
    }
    
    var photoImage: UIImage? {
        
        
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(filePath)
        }
        
        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: filePath!)
        }
    }
    
}