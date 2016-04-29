//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by 2359 Lawrence on 29/4/16.
//  Copyright © 2016 2359 Media Pte Ltd. All rights reserved.
//

import Foundation

extension FlickrClient {

    // MARK: Constants
    struct Constants {
        
        // MARK: URLs
        static let BaseURLSecure : String = "https://api.flickr.com/services/rest/?method="
        
        // MARK: Keys
        static let ApplicationKey : String = "6611f3566c8347a83aa1247223a6cd5f"
        static let SecretKey : String = "9ee2568d135d32e5"
        
        //sample     let URLString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&text=\(escapedTerm)&per_page=20&format=json&nojsoncallback=1"
        
    }
    
    // MARK: Methods
    struct Methods {
        
        // MARK: Account
        static let SearchPhotos = "flickr.photos.search"
        
    }
    
    // MARK: JSON Response Keys
    struct JSONResponseKeys {
        
        // MARK: Photos
        static let Photos = "photos"
        static let Photo = "photo"
        
    }

}