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
        
        arrayOfCells.append(mapCell)
        tableView.reloadData()
        
        editBarButton = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: #selector(VTMapTableViewController.onEdit))
        
        doneBarButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(VTMapTableViewController.onDone))
        
        self.navigationItem.rightBarButtonItem = editBarButton
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(MKMapView.addAnnotation(_:)))
        longPress.delegate = self
        longPress.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPress)
        
        do {
            try albumPinsFetchedResultsController.performFetch()
        } catch {}
        
        albumPinsFetchedResultsController.delegate = self
                
        loadMap()
    }
    
    func loadMap() {

        mapView.removeAnnotations(mapView.annotations)
        
        let albumPins = albumPinsFetchedResultsController.fetchedObjects
        
        if albumPins != nil && albumPins?.count > 0 {
        
            for pin in albumPins! {
                
                let pinData = pin as! FlickrAlbum
                let annotationCoordinate = CLLocationCoordinate2DMake(Double(pinData.latitude), Double(pinData.longitude))
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
                
        if isEdit == false {
            
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("VTAlbumCollectionViewController") as! VTAlbumCollectionViewController
            vc.centerCoordinate = CLLocationCoordinate2D(latitude: Double(view.annotation!.coordinate.latitude), longitude: Double(view.annotation!.coordinate.longitude))
            self.navigationController?.pushViewController(vc, animated: true)
            mapView.deselectAnnotation(view.annotation, animated: false)
        
        }else{
            
            let name = String(format: "%.6fN%.6f", (view.annotation?.coordinate.latitude)!, (view.annotation?.coordinate.longitude)!)
            
            let fetchRequest = NSFetchRequest(entityName: "FlickrAlbum")
            
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            fetchRequest.predicate = NSPredicate(format: "name = %@", name)
            
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
            
            do {
                try fetchedResultsController.performFetch()
            } catch {}
            
            fetchedResultsController.delegate = self
            
            if let albumPin = fetchedResultsController.fetchedObjects?.first as?FlickrAlbum
            {
                sharedContext.deleteObject(albumPin)
                CoreDataStackManager.sharedInstance().saveContext()
            }
            
            do {
                try albumPinsFetchedResultsController.performFetch()
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
    
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            mapView.addAnnotation(annotation)
            
            let name = String(format: "%.6fN%.6f", annotation.coordinate.latitude, annotation.coordinate.longitude)
            
            let dictionary: [String : AnyObject] = [
                FlickrAlbum.Keys.Latitude : annotation.coordinate.latitude,
                FlickrAlbum.Keys.Longitude : annotation.coordinate.longitude,
                FlickrAlbum.Keys.Name : name
            ]
            
            _ = FlickrAlbum(dictionary: dictionary, context: sharedContext)
            
            self.saveContext()
        }
    }
    
    lazy var albumPinsFetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "FlickrAlbum")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
        
    }()
    

}
