//
//  MapCollectionViewCell.swift
//  VirtualTourist
//
//  Created by 2359 Lawrence on 2/5/16.
//  Copyright © 2016 2359 Media Pte Ltd. All rights reserved.
//

import UIKit

class VTMapCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imgView: UIImageView!
    
    var activityIndicator: UIActivityIndicatorView?
    var isChosen = false
    
    override func awakeFromNib() {
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator?.center = self.center
        self.contentView.addSubview(activityIndicator!)
    }
    
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
    
}
