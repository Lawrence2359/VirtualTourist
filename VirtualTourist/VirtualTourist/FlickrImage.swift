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
    
    @NSManaged var farm: String?
    @NSManaged var photoID: String?
    @NSManaged var secret: String?
    @NSManaged var server: String?
    @NSManaged var image_url: String?
    @NSManaged var album: FlickrAlbum?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("FlickrImage", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        farm = dictionary[Keys.Farm] as? String ?? "1"
        photoID = dictionary[Keys.ID] as? String ?? ""
        secret = dictionary[Keys.Secret] as? String ?? ""
        server = dictionary[Keys.Server] as? String ?? ""
        image_url = ""
        //image_url = flickrImageURL(farm, photoID: photoID, secret: secret, server: server)
    }
    
    func flickrImageURL(farm: String?, photoID: String?, secret: String?, server: String?) -> String {
        return "http://farm\(farm).staticflickr.com/\(server)/\(photoID)_\(secret)_m.jpg"
    }
    
    var photoImage: UIImage? {
        
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(image_url)
        }
        
        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: image_url!)
        }
    }
    
}