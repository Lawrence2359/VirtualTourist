//
//  VTAlbumCollectionViewController.swift
//  VirtualTourist
//
//  Created by 2359 Lawrence on 2/5/16.
//  Copyright © 2016 2359 Media Pte Ltd. All rights reserved.
//

import UIKit
import MapKit
import CoreData

private let reuseIdentifier = "VTMapCollectionViewCell"

class VTAlbumCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
    
    var emptyLabel: UILabel?
    
    let kHeightOfButton: CGFloat = 66.0
    var albumName: String?
    
    var centerCoordinate: CLLocationCoordinate2D?
    var images = [FlickrImage]()
    var addToList = [FlickrImage]()
    var indexPathsList = [NSIndexPath]()
    
    var overlay: UIView?
    var activityView: UIActivityIndicatorView?
    
    var newCollectionBtn: UIButton?
    var deleteBtn: UIButton?
    
    let flickrAgent = FlickrClient.sharedInstance()
    
    var album: FlickrAlbum?
    
    // MARK: - Core Data Convenience
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    override func viewDidLoad() {
        let backBarBtn = UIBarButtonItem(title: "Ok", style: .Plain, target: self, action: #selector(VTAlbumCollectionViewController.onBack))
        
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = backBarBtn
        
        albumName = String(format: "%.6fN%.6f", self.centerCoordinate!.latitude, self.centerCoordinate!.longitude)
        
        overlay = UIView(frame: view.frame)
        overlay!.backgroundColor = UIColor.blackColor()
        overlay!.alpha = 0.3
        
        activityView = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityView!.center = view.center
        
        emptyLabel = UILabel(frame: CGRectMake(0,0, UIScreen.mainScreen().bounds.size.width, 44))
        emptyLabel?.textAlignment = .Center
        emptyLabel?.center = view.center
        emptyLabel?.text = "No photos found :("
        emptyLabel?.textColor = UIColor.blackColor()
        emptyLabel?.hidden = true
        view.addSubview(emptyLabel!)
        
        newCollectionBtn = UIButton(frame: CGRectMake(0, UIScreen.mainScreen().bounds.size.height-kHeightOfButton, UIScreen.mainScreen().bounds.size.width, kHeightOfButton))
        newCollectionBtn?.setTitle("New Collection", forState: .Normal)
        newCollectionBtn?.backgroundColor = UIColor.lightGrayColor()
        newCollectionBtn?.addTarget(self, action: #selector(VTAlbumCollectionViewController.onNew), forControlEvents: .TouchUpInside)
        view.addSubview(newCollectionBtn!)
        
        deleteBtn = UIButton(frame: CGRectMake(0, UIScreen.mainScreen().bounds.size.height-kHeightOfButton, UIScreen.mainScreen().bounds.size.width, kHeightOfButton))
        deleteBtn?.setTitle("Remove Selected Pictures", forState: .Normal)
        deleteBtn?.backgroundColor = UIColor.lightGrayColor()
        deleteBtn?.addTarget(self, action: #selector(VTAlbumCollectionViewController.onDelete), forControlEvents: .TouchUpInside)
        deleteBtn?.hidden = true
        view.addSubview(deleteBtn!)
        
        album = getAlbum()
        images = (album?.images)!
    }
    
    func getAlbum() -> FlickrAlbum {
        
        let fetchRequest = NSFetchRequest(entityName: "FlickrAlbum")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "name = %@", self.albumName!)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
        fetchedResultsController.delegate = self
        
        let album = fetchedResultsController.fetchedObjects?.first as? FlickrAlbum
        
        return album!
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadPhotos()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        for image in images {
            image.selected = 0
        }
        self.saveContext()
    }
    
    func onNew() {
        for image in images {
            self.sharedContext.deleteObject(image)
        }
        loadPhotosFromFlickr()
    }
    
    func onDelete() {
        for image in addToList {
            self.sharedContext.deleteObject(image)
        }
        album = getAlbum()
        images = (album?.images)!
        loadPhotos()
        deleteBtn?.hidden = true
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
        return CGSizeMake(115, 115)
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let currItem = images[indexPath.row]
        if currItem.selected == 0 {
            addToList.append(currItem)
            if addToList.count == 0 {
                deleteBtn?.hidden = true
            }else{
                deleteBtn?.hidden = false
            }
            currItem.selected = 1
            indexPathsList.append(indexPath)
        }else{
            let imageObj = images[indexPath.row]
            let idxOfObj = addToList.indexOf(imageObj)
            addToList.removeAtIndex(idxOfObj!)
            if addToList.count == 0 {
                deleteBtn?.hidden = true
            }else{
                deleteBtn?.hidden = false
            }
            currItem.selected = 0
        }
        self.saveContext()
        collectionView.reloadItemsAtIndexPaths([indexPath])
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        var reusableview: UICollectionReusableView = UICollectionReusableView()
        
        if kind == UICollectionElementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "VTCollectionHeaderView", forIndexPath: indexPath) as! VTCollectionHeaderView
            
            headerView.mapView.removeAnnotations(headerView.mapView.annotations)
                        
            let latitude = centerCoordinate?.latitude
            let longitude = centerCoordinate?.longitude
            if latitude != nil && longitude != nil {
                let centerCoord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
                let region = MKCoordinateRegionMakeWithDistance(centerCoord, 500, 500)
                let adjustedRegion = headerView.mapView.regionThatFits(region)
                headerView.mapView.setRegion(adjustedRegion, animated: false)
                headerView.mapView.userInteractionEnabled = false
                let annotation = MKPointAnnotation()
                annotation.coordinate = centerCoord
                headerView.mapView.addAnnotation(annotation)
            }
            
            reusableview = headerView
        }
        
        return reusableview
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as? VTMapCollectionViewCell
    
        var photoImage = UIImage(named: "sampleno")
        
        let currImg = images[indexPath.row]
        
        cell?.imgView!.image = nil
        
        if currImg.imagePath == nil || currImg.imagePath == "" {
            photoImage = UIImage(named: "sampleno")
        } else if currImg.photoImage != nil {
            photoImage = currImg.photoImage
        }
            
        else {
            
            cell?.activityIndicator?.startAnimating()
            
            // Start the task that will eventually download the image
            let task = FlickrClient.sharedInstance().taskForImageWithSize(currImg.imagePath!) { data, error in
                
                if let error = error {
                    print("Image download error: \(error.localizedDescription)")
                }
                
                if let data = data {
                    // Craete the image
                    let image = UIImage(data: data)
                    
                    self.sharedContext.performBlockAndWait({
                    // update the model, so that the infrmation gets cashed
                        currImg.photoImage = image
                    })
                    
                    // update the cell later, on the main thread
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        cell?.imgView!.image = image
                        cell?.activityIndicator?.stopAnimating()
                    }
                }
            }
            
            cell!.taskToCancelifCellIsReused = task

        }
        
        cell?.imgView!.image = photoImage
        
        if currImg.selected == 1 {
            cell!.layer.borderWidth = 8.0
            cell!.layer.borderColor = UIColor.grayColor().CGColor
        }else{
            cell!.layer.borderWidth = 0.0
            cell!.layer.borderColor = UIColor.clearColor().CGColor
        }
    
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
    
    func loadPhotos() {
        
        if images.count == 0 {
        
            loadPhotosFromFlickr()
            
        }else{
            
            self.images = (album?.images)!
            dispatch_async(dispatch_get_main_queue(), {
                self.collectionView?.reloadData()
            })
            
        }
        
    }
    
    
    func loadPhotosFromFlickr() {
        
        showLoading()
        
        flickrAgent.getPhotosFromLocation(centerCoordinate!.latitude, longtitude: centerCoordinate!.longitude, completionHandler: { (result, error) in
            
            if result != nil {
                
                if let photos = result![FlickrClient.JSONResponseKeys.Photos]![FlickrClient.JSONResponseKeys.Photo] as? NSArray {
                    
                    if photos.count == 0 {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.emptyLabel?.hidden = false
                        })
                    }else{
                        dispatch_async(dispatch_get_main_queue(), {
                            self.emptyLabel?.hidden = true
                        })
                    }
                    
                    self.sharedContext.performBlockAndWait({
                        
                        for photo in photos {
                            let currPhoto = photo as? [String : AnyObject]
                            let _ = currPhoto.map() { (dictionary: [String : AnyObject]) -> FlickrImage in
                                let currPhotoItem = FlickrImage(dictionary: dictionary, context: self.sharedContext)
                                
                                currPhotoItem.album = self.album
                                
                                return currPhotoItem
                            }
                        }
                        
                        self.saveContext()
                    })
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.stopLoading()
                        self.images = self.album!.images
                        self.collectionView?.reloadData()
                    })
                    
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.stopLoading()
                        let alert = UIAlertView()
                        alert.title = "Error"
                        alert.message = "Request Timeout"
                        alert.addButtonWithTitle("Ok")
                        alert.show()
                    })
                }
                
            }else{
                dispatch_async(dispatch_get_main_queue(), {
                    self.stopLoading()
                    let alert = UIAlertView()
                    alert.title = "Error"
                    alert.message = "Request Timeout"
                    alert.addButtonWithTitle("Ok")
                    alert.show()
                })
            }
            
        })
        
    }
    
    // MARK: Loading View
    
    func showLoading() {
        view.addSubview(overlay!)
        view.addSubview(activityView!)
        activityView?.startAnimating()
    }
    
    func stopLoading() {
        activityView?.stopAnimating()
        overlay?.removeFromSuperview()
        activityView?.removeFromSuperview()
    }

}
