//
//  LocationPickerViewController.swift
//  Chatting Application
//
//  Created by Sagar Baloch on 01/11/2020.
//  Copyright © 2020 Sagar Baloch. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class LocationPickerViewController: UIViewController {
    
    public var completion: ((CLLocationCoordinate2D)->Void)?
    private var coordinates: CLLocationCoordinate2D?
    public var isPickable = true
    
    private let map: MKMapView = {
        let m = MKMapView()
        return m
    }()
    
    init(coordinates: CLLocationCoordinate2D?) {
        self.coordinates = coordinates
        isPickable = coordinates == nil
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        if isPickable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendButtonTapped))
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            map.addGestureRecognizer(gesture)
        }else{
            //Just Showing Location
            guard let coordinates = self.coordinates else { return }
            // drop a pin on that location
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            map.addAnnotation(pin)
        }
        view.addSubview(map)
        map.frame = view.bounds
        map.isUserInteractionEnabled = true
    }
    
    @objc func sendButtonTapped(){
        guard let coordinates = coordinates else { return }
        completion?(coordinates)
        navigationController?.popViewController(animated: true)
    }
    
    @objc func didTapMap(_ gesture: UITapGestureRecognizer){
        let locationInView = gesture.location(in: map)
        let coordinates = map.convert(locationInView, toCoordinateFrom: map)
        self.coordinates = coordinates
        for annotation in map.annotations {
            map.removeAnnotation(annotation)
        }
        // drop a pin on that location
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        map.addAnnotation(pin)
    }
}
