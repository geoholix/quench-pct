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

enum Direction: String {
    case northbound
    case southbound
    
    var title: String {
        return self.rawValue.capitalized
    }
    
    static var all: [Direction] {
        return [.northbound, .southbound]
    }
    
    var queryOperator: String {
        switch self {
        case .northbound:
            return ">="
        case .southbound:
            return "<="
        }
    }
    
    var sortOrder: AGSSortOrder {
        switch self {
        case .northbound:
            return .ascending
        case .southbound:
            return .descending
        }
    }
    
    var image: UIImage? {
        switch self {
        case .northbound:
            return UIImage(named: "Northbound")
        case .southbound:
            return UIImage(named: "Southbound")
        }
    }
}
class DirectionViewController: UITableViewController {
    
    let directions = Direction.all
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return directions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rid = "settingsCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: rid) ?? UITableViewCell(style: .default, reuseIdentifier: rid)
        cell.textLabel?.text = directions[indexPath.row].title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        appSettings.direction = directions[indexPath.row]
        navigationController?.popViewController(animated: true)
    }
}
