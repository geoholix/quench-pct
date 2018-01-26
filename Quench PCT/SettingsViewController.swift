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

enum Setting: String {
    
    case direction
    case section
    
    var title: String {
        switch self {
        case .direction:
            return "Set Direction"
        case .section:
            return "Zoom to PCT Section"
        }
    }
    
    var subtitle: String? {
        switch self {
        case .direction:
            return "currently: \(appSettings.direction.title)"
        case .section:
            return nil
        }
    }
    
    var segue: String {
        switch self {
        case .direction:
            return "setDirectionSegue"
        case .section:
            return "chooseSectionSegue"
        }
    }
    
    static var all: [Setting] {
        return [.direction, .section]
    }
}
class SettingsViewController: UITableViewController {
    
    let settings = Setting.all
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rid = "settingsCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: rid) ?? UITableViewCell(style: .subtitle, reuseIdentifier: rid)
        cell.textLabel?.text = settings[indexPath.row].title
        cell.detailTextLabel?.text = settings[indexPath.row].subtitle
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: settings[indexPath.row].segue, sender: nil) 
    }
}
