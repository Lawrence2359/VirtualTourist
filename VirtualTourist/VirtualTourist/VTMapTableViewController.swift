//
//  MainMapTableViewController.swift
//  VirtualTourist
//
//  Created by 2359 Lawrence on 29/4/16.
//  Copyright © 2016 2359 Media Pte Ltd. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class VTMapTableViewController: UITableViewController, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {
    
    let kMapCell = "MapTableViewCell"
    let kTapCell = "TapTableViewCell"
    
    @IBOutlet weak var tapCell: UITableViewCell!
    @IBOutlet weak var mapCell: UITableViewCell!
    @IBOutlet var mapView: MKMapView!
    
    var isEdit = false
    
    var arrayOfCells = [UITableViewCell]()
    
    let mapSettingsHelper = VTMapSettingsHelper.sharedInstance()
    let flickrAgent = FlickrClient.sharedInstance()
    
    var overlay: UIView?
    var activityView: UIActivityIndicatorView?
    
    var currentPinLatitude: NSNumber = 0.0
    var currentPinLongitude: NSNumber = 0.0
    
    var editBarButton: UIBarButtonItem?
    
    var doneBarButton: UIBarButtonItem?
    
    // MARK: - Core Data Convenience
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: kMapCell)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: kTapCell)
        tableView.rowHeight = UITableViewAutomaticDimension
        
        overlay = UIView(frame: view.frame)
        overlay!.backgroundColor = UIColor.blackColor()
        overlay!.alpha = 0.3
        
        activityView = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityView!.center = mapView.center
        
        arrayOfCells.append(mapCell)
        tableView.reloadData()
        
        editBarButton = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: #selector(VTMapTableViewController.onEdit))
        
        doneBarButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(VTMapTableViewController.onDone))
        
        self.navigationItem.rightBarButtonItem = editBarButton
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(MKMapView.addAnnotation(_:)))
        longPress.delegate = self
        longPress.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPress)
        
        do {
            try albumsFetchedResultsController.performFetch()
        } catch {}
        
        albumsFetchedResultsController.delegate = self
                
        loadMap()
    }
    
    func loadMap() {

        mapView.removeAnnotations(mapView.annotations)
        
        let albums = albumsFetchedResultsController.fetchedObjects as? [FlickrAlbum]
        for album in albums! {
            
            let annotationCoordinate = CLLocationCoordinate2DMake(Double(album.latitude), Double(album.longitude))
            let dropPin = MKPointAnnotation()
            dropPin.coordinate = annotationCoordinate
            mapView.addAnnotation(dropPin)
        }
        
        let mapData = mapSettingsHelper.loadCoordinatesAndZoomLevel()
        let latitude = mapData[kCoordinatesLatKey] as? Double
        let longitude = mapData[kCoordinatesLonKey] as? Double
        let spanLatitude = mapData[kSpanCoordinatesLatKey] as? Double
        let spanLongitude = mapData[kSpanCoordinatesLonKey] as? Double
        if latitude != nil && longitude != nil {
            let centerCoord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
            if spanLatitude != nil && spanLongitude != nil {
                let spanCoord: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: spanLatitude!, longitudeDelta: spanLongitude!)
                let region = MKCoordinateRegion(center: centerCoord, span: spanCoord)
                mapView.setRegion(region, animated: true)
                
            }
        }
        
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfCells.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = arrayOfCells[indexPath.row]
        cell.selectionStyle = .None
        return cell
        
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return UIScreen.mainScreen().bounds.size.height - (navigationController?.navigationBar.frame.size.height)! - 105
        }
        return 88
    }
    
    // MARK: - Actions
    
    func onEdit() {
        arrayOfCells.append(tapCell)
        self.navigationItem.rightBarButtonItem = doneBarButton
        isEdit = true
        tableView.reloadData()
    }
    
    func onDone(){
        arrayOfCells.removeLast()
        self.navigationItem.rightBarButtonItem = editBarButton
        isEdit = false
        tableView.reloadData()
    }
    
    // MARK: - Map View
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let mapLatitude = mapView.centerCoordinate.latitude
        let mapLongitude = mapView.centerCoordinate.longitude
        let spanLatitude = mapView.region.span.latitudeDelta
        let spanLongitude = mapView.region.span.longitudeDelta
        mapSettingsHelper.updateCoordinatesAndZoomLevel(mapLatitude, longitude: mapLongitude, spanLatitude: spanLatitude, spanLongitude: spanLongitude)
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        let albumName = String(format: "%.6fN%.6f", view.annotation!.coordinate.latitude, view.annotation!.coordinate.longitude)
        
        if isEdit == false {
            
            showLoading()
            
            flickrAgent.getPhotosFromLocation(view.annotation!.coordinate.latitude, longtitude: view.annotation!.coordinate.longitude, completionHandler: { (result, error) in
                
                if result != nil {
                    
                    let currPhotoAlbum = FlickrAlbum(dictionary: ["latitude": view.annotation!.coordinate.latitude, "longitude": view.annotation!.coordinate.longitude, "name": albumName], context: self.sharedContext)
                    
                    if let photos = result![FlickrClient.JSONResponseKeys.Photos]![FlickrClient.JSONResponseKeys.Photo] as? NSArray {
                        
                        for photo in photos {
                            let currPhoto = photo as? [String : AnyObject]
                            let _ = currPhoto.map() { (dictionary: [String : AnyObject]) -> FlickrImage in
                                let currPhotoItem = FlickrImage(dictionary: dictionary, context: self.sharedContext)
                                
                                currPhotoItem.album = currPhotoAlbum
                                
                                return currPhotoItem
                            }
                        }
                        
                        // Save the context
                        self.saveContext()
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            self.stopLoading()
                        })
                        
                        let fetchRequest = NSFetchRequest(entityName: "FlickrAlbum")
                        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                        fetchRequest.predicate = NSPredicate(format: "name = %@", albumName)
                        
                        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                            managedObjectContext: self.sharedContext,
                            sectionNameKeyPath: nil,
                            cacheName: nil)
                        do {
                            try fetchedResultsController.performFetch()
                        } catch {}
                        
                        
                        let results = fetchedResultsController.fetchedObjects
                        if results != nil && results?.count > 0 {
                            let album = results![0] as! FlickrAlbum
                            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("VTAlbumCollectionViewController") as! VTAlbumCollectionViewController
                            
                            vc.images = album.images
                            vc.centerCoordinate = CLLocationCoordinate2D(latitude: Double(album.latitude), longitude: Double(album.longitude))
                            dispatch_async(dispatch_get_main_queue(), {
                                self.navigationController?.pushViewController(vc, animated: true)
                            })
                        }
                        
                    } else {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.stopLoading()
                        })
                    }
                    
                }else{
                    dispatch_async(dispatch_get_main_queue(), {
                        self.stopLoading()
                    })
                }
                
            })
        
        }else{
            
            do {
                try albumsFetchedResultsController.performFetch()
            } catch {}
            
            
            let results = albumsFetchedResultsController.fetchedObjects
            let album = results![0] as! FlickrAlbum
            sharedContext.deleteObject(album)
            CoreDataStackManager.sharedInstance().saveContext()
            
            do {
                try albumsFetchedResultsController.performFetch()
            } catch {}
            
            loadMap()
        }
        
    }
    
    func mapView(mapView: MKMapView,
                   didDeselectAnnotationView view: MKAnnotationView)
    {
        
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
            if (!MKMapRectContainsPoint(self.mapView.visibleMapRect, point)) {
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
    
    func reverseGeocode(latitude: Double, longitude: Double) -> String {
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        let geoCoder = CLGeocoder()
        let _: AnyObject
        let _: NSError
        var albumNameByLocation = ""
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemark, error) -> Void in
            if error != nil {
                print("Error: \(error!.localizedDescription)")
                return
            }
            if placemark!.count > 0 {
                let pm = placemark![0] as CLPlacemark
                albumNameByLocation = "\(pm.name!)-\(pm.postalCode!)"
            } else {
                print("Error with data")
                return
            }
        })
        return albumNameByLocation
    }
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            mapView.addAnnotation(annotation)
        }
    }
    
    // MARK: Loading View
    
    func showLoading() {
        mapView.addSubview(overlay!)
        mapView.addSubview(activityView!)
        activityView?.startAnimating()
    }
    
    func stopLoading() {
        activityView?.stopAnimating()
        overlay?.removeFromSuperview()
        activityView?.removeFromSuperview()
    }
    
    lazy var albumsFetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "FlickrAlbum")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        
        return fetchedResultsController
        
    }()

}
