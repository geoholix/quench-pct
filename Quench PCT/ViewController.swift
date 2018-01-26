//// Copyright 2018 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class ViewController: UIViewController, SectionViewControllerDelegate {

    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var directionBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var waterButton: UIBarButtonItem!
    
    var mapObserver: NSKeyValueObservation?
    var offlineMapTask: AGSOfflineMapTask?
    var offlineMapJob: AGSGenerateOfflineMapJob?
    var mileMarkers: AGSFeatureLayer?
    var locationObserver: NSKeyValueObservation?
    
    var tmpMileMarker: AGSArcGISFeature? {
        didSet {
            waterButton.isEnabled = tmpMileMarker != nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.map = appSettings.mapFromPortal
        mapView.locationDisplay.showLocation = true
        mapView.touchDelegate = self
        mapView.locationDisplay.start { (err) in
            if let error = err {
                print("[Error] Cannot display user location: \(error.localizedDescription)")
            }
        }
        mapView.locationDisplay.autoPanMode = .recenter
        mapView.locationDisplay.autoPanModeChangedHandler = { newAutoPanMode in
            guard self.mapView.locationDisplay.autoPanMode == .off else {
                self.mapView.locationDisplay.autoPanMode = .off
                self.zoomToUsersLocation(self)
                return
            }
        }
        
        mapView.map?.load(completion: { (error) in
            guard error == nil else {
                print("[Error]", error!.localizedDescription)
                return
            }
            for layer in self.mapView.map!.operationalLayers {
                if let mileMarkers = layer as? AGSFeatureLayer, mileMarkers.name == "Mile_Markers" {
                    self.mileMarkers = mileMarkers
                    break
                }
            }
            self.mileMarkers?.load(completion: { (error) in
                guard error == nil else {
                    print("[Error]", error!.localizedDescription)
                    return
                }
                guard let table = self.mileMarkers!.featureTable as? AGSServiceFeatureTable,
                    let location = self.mapView.locationDisplay.location?.position,
                    let buffer = AGSGeometryEngine.bufferGeometry(location, byDistance: 1)
                    else {
                    return
                }
                
                let query = AGSQueryParameters()
                
                query.geometry = buffer
                query.spatialRelationship = .intersects
                
                table.queryFeatures(with: query, queryFeatureFields: .loadAll, completion: { (results, error) in
                    
                    if let results = results {
                        print("results n", results.featureEnumerator().allObjects.count)
                        if let features = results.featureEnumerator().allObjects as? [AGSArcGISFeature] {

                            self.tmpMileMarker = features.nearestTo(mapPoint: location)
                            
                        }
                    }
                })
            })
        })
    }

    
    @IBAction func zoomToUsersLocation(_ sender: Any) {
        guard mapView.locationDisplay.showLocation == true, let location = mapView.locationDisplay.location, let position = location.position else {
            return
        }
        let viewpoint = AGSViewpoint(center: position, scale: 100000)
        mapView.setViewpoint(viewpoint, duration: 1.0, completion: nil)
    }
    
    @IBAction func queryWater(_ sender: Any) {
        performSegue(withIdentifier: "mapToWater", sender: nil)
    }
    
    @IBAction func downloadForOffline(_ sender: Any) {
        
        guard let map = mapView.map, let area = mapView.visibleArea else {
            return
        }
        
        offlineMapTask = AGSOfflineMapTask(onlineMap: map)
        
        offlineMapTask?.defaultGenerateOfflineMapParameters(withAreaOfInterest: area, completion: { (parameters, error) in
            if let error = error {
                print(error)
                return
            }
            guard parameters != nil else {
                print("No parameters")
                return
            }
            // Update the parameters if needed
            parameters?.maxScale = 5000
            parameters?.attachmentSyncDirection = .upload
            parameters?.returnLayerAttachmentOption = .editableLayers
            // Request the table schema only (existing features won’t be included)
            parameters?.returnSchemaOnlyForEditableLayers = true
            // Update the title to contain the region
            if let title = parameters?.itemInfo?.title.appending(" (Central)") {
                parameters?.itemInfo?.title = title
            }
            
            //create the parameters
            //create the job
            self.offlineMapJob = self.offlineMapTask?.generateOfflineMapJob(with: parameters!, downloadDirectory: AppSettings.docsDir)
            //start the job
            self.offlineMapJob?.start(statusHandler: { [weak self] (status) in
                print("Status [\(String(describing: self?.offlineMapJob?.progress.fractionCompleted))]: \(status)")
                }, completion: { (result, error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    guard let result = result else { return }
                    if result.hasErrors {
                        result.layerErrors.forEach{(layerError) in
                            print((layerError.key.name), " Error be taking this layer offline")
                        }
                        result.tableErrors.forEach{(tableError) in
                            print((tableError.key.tableName), " Error be taking this table offline")
                        }
                    }
                    else {
                        //display the offline map
                        self.mapView.map = result.offlineMap
                    }
            })
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SectionViewController {
            destination.delegate = self
        }
        else if let destination = segue.destination as? WaterViewController {
            destination.mileMarker = self.tmpMileMarker
            destination.delegate = self
        }
    }
    
    func sectionViewController(_: SectionViewController, didSelect viewpoint: AGSViewpoint) {
        mapView.setViewpoint(viewpoint, duration: 1.0, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        directionBarButtonItem.image = appSettings.direction.image
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension Sequence where Iterator.Element == AGSArcGISFeature {
    // NOTE this derived result in the Docs
    func nearestTo(mapPoint: AGSPoint) -> AGSArcGISFeature? {
        let sorted = self.sorted(by: { (featureA, featureB) -> Bool in
            let deltaA = AGSGeometryEngine.distanceBetweenGeometry1(mapPoint, geometry2: featureA.geometry!)
            let deltaB = AGSGeometryEngine.distanceBetweenGeometry1(mapPoint, geometry2: featureB.geometry!)
            return deltaA < deltaB
        })
        return sorted.first
    }
}

extension ViewController: WaterViewControllerProtocol {
    
    func waterViewController(_: WaterViewController, didSelect waterFeature: AGSArcGISFeature) {
        if let layers = mapView.map?.operationalLayers {
            for layer in layers {
                if let waterLayer = layer as? AGSFeatureLayer, waterLayer.name == "Water Sources" {
                    waterLayer.clearSelection()
                    waterLayer.select(waterFeature)
                }
            }
        }
        guard
            let userLocation = self.mapView.locationDisplay.location?.position,
            let waterLocation = waterFeature.geometry,
            let newref = AGSSpatialReference(wkid: 4326),
            let waterLocationwgs84 = AGSGeometryEngine.projectGeometry(waterLocation, to: newref),
            let envelope = AGSGeometryEngine.combineExtents(ofGeometries: [userLocation, waterLocationwgs84])
            else {
            return
        }
        let envbuilder = AGSEnvelopeBuilder(envelope: envelope)
        let widerenvelope = envbuilder.expand(byFactor: 1.2)
        let viewpoint = AGSViewpoint(targetExtent: widerenvelope.toGeometry())
        mapView.setViewpoint(viewpoint, duration: 1.0, completion: nil)
        
    }
}

extension ViewController: AGSGeoViewTouchDelegate {
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        
        if let layers = mapView.map?.operationalLayers {
            for layer in layers {
                if let waterLayer = layer as? AGSFeatureLayer, waterLayer.name == "Water Sources" {
                    
                    waterLayer.clearSelection()
                    
                    geoView.identifyLayer(waterLayer, screenPoint: screenPoint, tolerance: 7, returnPopupsOnly: false, completion: { (results) in
                        
                        if let features = results.geoElements as? [AGSArcGISFeature], let feature = features.first {
                            waterLayer.select(feature)
                        }
                        
                        let popupcontroller = AGSPopupsViewController(popups: results.popups)
                        popupcontroller.modalPresentationStyle = .pageSheet
                        popupcontroller.delegate = self
                        self.present(popupcontroller, animated: true, completion: nil)

                    })
                }
            }
        }
    }
}

extension ViewController: AGSPopupsViewControllerDelegate {
    
    func popupsViewControllerDidFinishViewingPopups(_ popupsViewController: AGSPopupsViewController) {
        popupsViewController.dismiss(animated: true, completion: nil)
    }
}
