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

enum Section {
    
    case southernCalifornia
    case centralCalifornia
    case northernCalifornia
    case oregon
    case washington
    
    var title: String {
        switch self {
        case .southernCalifornia:
            return "Southern California"
        case .centralCalifornia:
            return "Central California"
        case .northernCalifornia:
            return "Northern California"
        case .oregon:
            return "Oregon"
        case .washington:
            return "Washington"
        }
    }
    
    var extent: AGSViewpoint {
        switch self {
        case .southernCalifornia:
            let point = AGSPoint(clLocationCoordinate2D: CLLocationCoordinate2D(latitude: 33.557126, longitude: -116.654358))
            let viewpoint = AGSViewpoint(center: point, scale:  2311162.217155)
            return viewpoint
        case .centralCalifornia:
            let point = AGSPoint(clLocationCoordinate2D: CLLocationCoordinate2D(latitude: 35.837571, longitude: -118.390198))
            let viewpoint = AGSViewpoint(center: point, scale: 2311162.217155)
            return viewpoint
        case .northernCalifornia:
            let point = AGSPoint(clLocationCoordinate2D: CLLocationCoordinate2D(latitude: 38.785932, longitude: -121.079102))
            let viewpoint = AGSViewpoint(center: point, scale: 4622324.434309)
            return viewpoint
        case .oregon:
            let point = AGSPoint(clLocationCoordinate2D: CLLocationCoordinate2D(latitude: 44.055267, longitude: -121.408691))
            let viewpoint = AGSViewpoint(center: point, scale: 4622324.434309)
            return viewpoint
        case .washington:
            let point = AGSPoint(clLocationCoordinate2D: CLLocationCoordinate2D(latitude: 47.091860, longitude: -121.042709))
            let viewpoint = AGSViewpoint(center: point, scale: 4622324.434309)
            return viewpoint
        }
    }
    
    static var all: [Section] {
        return [southernCalifornia, centralCalifornia, northernCalifornia, oregon, washington]
    }
}

protocol SectionViewControllerDelegate {
    func sectionViewController(_: SectionViewController, didSelect viewpoint: AGSViewpoint)
}

class SectionViewController: UITableViewController {
    
    var delegate: SectionViewControllerDelegate?
    
    let sections = Section.all
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rid = "settingsCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: rid) ?? UITableViewCell(style: .default, reuseIdentifier: rid)
        cell.textLabel?.text = sections[indexPath.row].title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.sectionViewController(self, didSelect: sections[indexPath.row].extent)
        navigationController?.popViewController(animated: true)
    }
}
