//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by 2359 Lawrence on 29/4/16.
//  Copyright © 2016 2359 Media Pte Ltd. All rights reserved.
//

import Foundation

// MARK: - FlickrClient (Convenient Resource Methods)

extension FlickrClient {
    
    // MARK: GET Convenience Methods
    
    func getPhotosFromLocation(latitude: Double, longtitude: Double, completionHandler: (result: [String: AnyObject]?, error: NSError?) -> Void) {
        
        let randomPage = Int(arc4random_uniform(UInt32(10)))
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters = ["api_key": Constants.ApplicationKey, "lat": latitude, "lon": longtitude, "format": "json", "nojsoncallback": 1, "page": randomPage, "per_page": 25]
        let mutableMethod : String = Methods.SearchPhotos
            
        
        /* 2. Make the request */
        taskForGETMethod(mutableMethod, parameters: parameters as! [String : AnyObject]) { JSONResult, error in
            
            /* 3. Send the desired value(s) to completion handler */
            if let error = error {
                completionHandler(result: nil, error: error)
            } else {
                if JSONResult != nil {
                    let photos = JSONResult as? [String : AnyObject]
                    completionHandler(result: photos, error: nil)
                }else{
                    completionHandler(result: nil, error: NSError(domain: "getPhotosFromLocation parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getPhotosFromLocation"]))
                }
            }
        }
    }
    
    // MARK: - All purpose task method for images
    
    func taskForImageWithSize(filePath: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        let url = NSURL(string: filePath)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                completionHandler(imageData: nil, error: NSError(domain: "Image Download Error", code: 1, userInfo: nil))
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        
        task.resume()
        
        return task
    }
    

}