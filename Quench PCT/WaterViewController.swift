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

import Foundation
import UIKit
import ArcGIS

protocol WaterViewControllerProtocol {
    func waterViewController(_: WaterViewController, didSelect waterFeature: AGSArcGISFeature)
}

class WaterViewController: UITableViewController {
    
    var featureLayer: AGSFeatureLayer?
    
    var waterSources = [AGSFeature]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    var delegate: WaterViewControllerProtocol?
    
    var mileMarker: AGSArcGISFeature?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let map = appSettings.currentMap {
            for layer in map.operationalLayers {
                if let waterSources = layer as? AGSFeatureLayer, waterSources.name == "Water Sources" {
                    self.featureLayer = waterSources
                    break
                }
            }
            self.featureLayer?.load(completion: { (error) in

            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let map = appSettings.currentMap {
            for layer in map.operationalLayers {
                if let waterLayer = layer as? AGSFeatureLayer, waterLayer.name == "Water Sources", let table = waterLayer.featureTable as? AGSServiceFeatureTable, let mile = self.mileMarker?.attributes["MileMarker"] as? Double {
                    let query = AGSQueryParameters()
                    query.maxFeatures = 24
                    let ordered = AGSOrderBy(fieldName: "Mile_Marker", sortOrder: appSettings.direction.sortOrder)
                    query.orderByFields = [ordered]
                    query.whereClause = "Mile_Marker \(appSettings.direction.queryOperator) \(mile)"
                    table.queryFeatures(with: query, queryFeatureFields: .loadAll, completion: { (results, error) in
                        guard error == nil else {
                            print("[Error]", error!.localizedDescription)
                            return
                        }
                        if let results = results {
                            print("results n", results.featureEnumerator().allObjects.count)
                            if let features = results.featureEnumerator().allObjects as? [AGSArcGISFeature] {
                                self.waterSources = features
                            }
                        }
                    })
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return waterSources.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rid = "settingsCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: rid) ?? UITableViewCell(style: .subtitle, reuseIdentifier: rid)
        let feature = waterSources[indexPath.row]
        if let locDesc = feature.attributes["Location_Descriptor"] as? String {
            cell.textLabel?.text = locDesc
        }
        if let dist = feature.attributes["Mile_Marker"] as? Double, let myloc = mileMarker?.attributes["MileMarker"] as? Double {
            let dist = fabs(myloc - dist).truncate(places: 1)
            cell.detailTextLabel?.text = "\(dist) miles away"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let feature = waterSources[indexPath.row] as? AGSArcGISFeature{
            self.delegate?.waterViewController(self, didSelect: feature)
        }
        navigationController?.popViewController(animated: true)
    }
}

extension Double
{
    func truncate(places : Int)-> Double
    {
        return Double(floor(pow(10.0, Double(places)) * self)/pow(10.0, Double(places)))
    }
}
