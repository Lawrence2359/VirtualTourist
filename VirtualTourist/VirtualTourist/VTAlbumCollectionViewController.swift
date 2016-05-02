//
//  VTAlbumCollectionViewController.swift
//  VirtualTourist
//
//  Created by 2359 Lawrence on 2/5/16.
//  Copyright © 2016 2359 Media Pte Ltd. All rights reserved.
//

import UIKit
import MapKit

private let reuseIdentifier = "VTMapCollectionViewCell"

class VTAlbumCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var centerCoordinate: CLLocationCoordinate2D?
    var images: [FlickrImage]?
    var addToList = [FlickrImage]()
    
    override func viewDidLoad() {
        let backBarBtn = UIBarButtonItem(title: "Ok", style: .Plain, target: self, action: #selector(VTAlbumCollectionViewController.onBack))
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = backBarBtn
    }
    
    func onBack() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: UICollectionViewDelegateFlowLayout 
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(5, 5, 5, 5)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(110, 110)
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        addToList.append(images![indexPath.row])
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! VTMapCollectionViewCell
        if !cell.isChosen {
            cell.layer.borderWidth = 8.0
            cell.layer.borderColor = UIColor.grayColor().CGColor
            cell.isChosen = true
        }else{
            let imageObj = images![indexPath.row]
            let idxOfObj = addToList.indexOf(imageObj)
            addToList.removeAtIndex(idxOfObj!)
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! VTMapCollectionViewCell
            cell.layer.borderWidth = 0.0
            cell.layer.borderColor = UIColor.clearColor().CGColor
            cell.isChosen = false
        }
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        var reusableview: UICollectionReusableView = UICollectionReusableView()
        
        if kind == UICollectionElementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "VTCollectionHeaderView", forIndexPath: indexPath) as! VTCollectionHeaderView
                        
            let latitude = centerCoordinate?.latitude
            let longitude = centerCoordinate?.longitude
            if latitude != nil && longitude != nil {
                let centerCoord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
                let latDelta:CLLocationDegrees = 0.01
                let longDelta:CLLocationDegrees = 0.01
                let theSpan:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, longDelta)
                let region = MKCoordinateRegion(center: centerCoord, span: theSpan)
                headerView.mapView.setRegion(region, animated: false)
                let annotation = MKPointAnnotation()
                annotation.coordinate = centerCoord
                headerView.mapView.addAnnotation(annotation)
            }
            
            reusableview = headerView
        }else if kind == UICollectionElementKindSectionFooter {
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier: "VTCollectionFooterView", forIndexPath: indexPath) as! VTCollectionFooterView
            reusableview = headerView
        }
        
        
        return reusableview
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images!.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as? VTMapCollectionViewCell
    
        var photoImage = UIImage(named: "sampleno")
        
        var currImg = images![indexPath.row]
        
        cell?.imgView!.image = nil
        
        if currImg.imagePath == nil || currImg.imagePath == "" {
            photoImage = UIImage(named: "sampleno")
        } else if currImg.photoImage != nil {
            photoImage = currImg.photoImage
        }
            
        else {
            
            // Start the task that will eventually download the image
            let task = FlickrClient.sharedInstance().taskForImageWithSize(currImg.imagePath!) { data, error in
                
                if let error = error {
                    print("Image download error: \(error.localizedDescription)")
                }
                
                if let data = data {
                    // Craete the image
                    let image = UIImage(data: data)
                    
                    // update the model, so that the infrmation gets cashed
                    currImg.photoImage = image
                    
                    // update the cell later, on the main thread
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        cell?.imgView!.image = image
                    }
                }
            }
            
            cell!.taskToCancelifCellIsReused = task

        }
        
        cell?.imgView!.image = photoImage
    
        return cell!
    }
    
    func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
    
    func downloadImage(url: NSURL, cell: VTMapCollectionViewCell, imageView: UIImageView) {
        cell.activityIndicator?.startAnimating()
        getDataFromUrl(url) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else { return }
                imageView.image = UIImage(data: data)
                imageView.contentMode = .ScaleAspectFill
                cell.activityIndicator?.stopAnimating()
            }
        }
    }


    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        var i = -1;
        for view in views {
            i += 1;
            let mkView = view as! MKAnnotationView
            if view.annotation is MKUserLocation {
                continue;
            }
            
            // Check if current annotation is inside visible map rect, else go to next one
            let point:MKMapPoint  =  MKMapPointForCoordinate(mkView.annotation!.coordinate);
            if (!MKMapRectContainsPoint(mapView.visibleMapRect, point)) {
                continue;
            }
            
            
            let endFrame:CGRect = mkView.frame;
            
            // Move annotation out of view
            mkView.frame = CGRectMake(mkView.frame.origin.x, mkView.frame.origin.y - self.view.frame.size.height, mkView.frame.size.width, mkView.frame.size.height);
            
            // Animate drop
            let delay = 0.03 * Double(i)
            UIView.animateWithDuration(0.5, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations:{() in
                mkView.frame = endFrame
                // Animate squash
                }, completion:{(Bool) in
                    UIView.animateWithDuration(0.05, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations:{() in
                        mkView.transform = CGAffineTransformMakeScale(1.0, 0.6)
                        
                        }, completion: {(Bool) in
                            UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations:{() in
                                mkView.transform = CGAffineTransformIdentity
                                }, completion: nil)
                    })
                    
            })
        }
    }

}
