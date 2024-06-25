

import UIKit
import MapKit
import CoreData

class MapVC: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextView!
    
    var locationManager = CLLocationManager()
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    var annoLatitude = Double()
    var annoLongitude = Double()
    var annoSubtitle = ""
    var annoTitle = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setData()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    
        // Long Press for Choose Location
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation))
        gesture.minimumPressDuration = 3
        mapView.addGestureRecognizer(gesture)
        
    }
    
    @objc func setData(){
        
        if selectedTitle != ""{

            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleID!.uuidString
            fetchReq.predicate = NSPredicate(format: "id = %@", idString)
            
            do{
                let results = try context.fetch(fetchReq)
                if results.count > 0{
                    for item in results as! [NSManagedObject]{
                        
                        if let title = item.value(forKey: "title") as? String{
                            selectedTitle = title
                            
                            if let subtitle = item.value(forKey: "subtitle") as? String{
                                annoSubtitle = subtitle
                                
                                if let latitude = item.value(forKey: "latitude") as? Double{
                                    annoLatitude = latitude
                                    
                                    if let longitude = item.value(forKey: "longitude") as? Double{
                                        annoLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        let coordinate = CLLocationCoordinate2D(latitude: annoLatitude, longitude: annoLongitude)
                                        annotation.title = annoTitle
                                        annotation.subtitle = annoSubtitle
                                        annotation.coordinate = coordinate
                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annoTitle
                                        commentText.text = annoSubtitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            }catch{
                print("error")
            }
        }
    }
     
     func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        
         if annotation is MKUserLocation {
             return nil
         }
         
         let reuseID = "myAnnotation"
         var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKMarkerAnnotationView
         
         if pinView == nil {
             pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
             pinView?.canShowCallout = true
             pinView?.tintColor = UIColor.blue
             
             let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
             pinView?.rightCalloutAccessoryView = button
             
         }else{
             pinView?.annotation = annotation
         }
         
         return pinView
     }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != ""{
            
            let requestLocation = CLLocation(latitude: annoLatitude, longitude: annoLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
                
                if let placemark = placemarks{
                    if placemark.count > 0{
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annoTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }
    }
    
    @objc func chooseLocation(gesture: UILongPressGestureRecognizer){
        
        if gesture.state == .began{
            
            let touchPoint = gesture.location(in: self.mapView)
            let touchedCoordinates = mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            mapView.addAnnotation(annotation)
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if selectedTitle == ""{     // Not update location for saved data/annotation
            
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    @IBAction func saveButton(_ sender: Any) {
        let appDel = UIApplication.shared.delegate as! AppDelegate
        let context = appDel.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        /*
        if nameText.text == "" {
            let alert = UIAlertController(title: "Error", message: "Name area is empty", preferredStyle: UIAlertController.Style.alert)
            let okButton =
        }*/
        do{
            try context.save()
        }catch{
            print("error")
        }
      
        // Show other VC
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
    
    }
    
    
    
    
}

