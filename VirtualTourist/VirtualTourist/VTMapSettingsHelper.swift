//
//  VTMapSettingsHelper.swift
//  VirtualTourist
//
//  Created by 2359 Lawrence on 29/4/16.
//  Copyright © 2016 2359 Media Pte Ltd. All rights reserved.
//

import Foundation

let kCoordinatesLatKey = "coordinatesLatKey"
let kCoordinatesLonKey = "coordinatesLonKey"
let kSpanCoordinatesLatKey = "spanLatKey"
let kSpanCoordinatesLonKey = "spanLonKey"

class VTMapSettingsHelper {
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    static let singleton = VTMapSettingsHelper()
    
    class func sharedInstance() -> VTMapSettingsHelper {
        return singleton
    }
    
    func updateCoordinatesAndZoomLevel(latitude: NSNumber, longitude: NSNumber, spanLatitude: NSNumber, spanLongitude: NSNumber) {
        
        userDefaults.setObject(latitude, forKey: kCoordinatesLatKey)
        userDefaults.setObject(longitude, forKey: kCoordinatesLonKey)
        userDefaults.setObject(spanLatitude, forKey: kSpanCoordinatesLatKey)
        userDefaults.setObject(spanLongitude, forKey: kSpanCoordinatesLonKey)
        
    }
    
    func loadCoordinatesAndZoomLevel() -> [String:AnyObject?] {
        
        let latitude = userDefaults.objectForKey(kCoordinatesLatKey)
        let longitude = userDefaults.objectForKey(kCoordinatesLonKey)
        let spanLatitude = userDefaults.objectForKey(kSpanCoordinatesLatKey)
        let spanLongitude = userDefaults.objectForKey(kSpanCoordinatesLatKey)
        let mapData = [kCoordinatesLatKey:latitude, kCoordinatesLonKey:longitude, kSpanCoordinatesLatKey:spanLatitude, kSpanCoordinatesLonKey:spanLongitude]
        return mapData
    }
    
}