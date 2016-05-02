//
//  FlickrImageHelper.swift
//  VirtualTourist
//
//  Created by 2359 Lawrence on 2/5/16.
//  Copyright © 2016 2359 Media Pte Ltd. All rights reserved.
//

import UIKit

struct FlickrImageHelper {
    
    var farm: String! = ""
    var photoID: String! = ""
    var secret: String! = ""
    var server: String! = ""
    var imagePath: String? = ""
    
    init(farm: String, photoID: String, secret: String, server: String) {
        
        self.farm = farm
        self.photoID = photoID
        self.secret = secret
        self.server = server
        self.imagePath = flickrImageURL()
    }
    
    
    func flickrImageURL(size:String = "m") -> String {
        return "http://farm\(farm).staticflickr.com/\(server)/\(photoID)_\(secret)_m.jpg"
    }
    
    var photoImage: UIImage? {
        
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(imagePath)
        }
        
        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: imagePath!)
        }
    }
    
}