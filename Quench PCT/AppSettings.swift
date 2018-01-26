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
import ArcGIS

var appSettings: AppSettings {
    return AppSettings.shared
}

@objcMembers class AppSettings: NSObject {
    
    static let shared = AppSettings()
    
    static let itemID: String = "801096aef6b746c284007c34a5940d1f"
    static let mapURL = URL(string: "https://www.arcgis.com/")!
    
    static var docsDir: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        var documentsDirectory = paths[0]
        documentsDirectory.appendPathComponent("downloadDirectory")
        return documentsDirectory
    }()
    
    var direction: Direction = {
        let defaults = UserDefaults.standard
        if let directionString = defaults.string(forKey: "UserDirectionKey"), let direction = Direction(rawValue: directionString) {
            return direction
        }
        return .northbound
        }() {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(direction.rawValue, forKey: "UserDirectionKey")
            defaults.synchronize()
        }
    }
    
    var portal: AGSPortal = AGSPortal(url: AppSettings.mapURL, loginRequired: false) {
        didSet {
            portal.load { (error: Error?) in
                if let error = error {
                    print("[Error: Portal Load]", error.localizedDescription)
                    self.currentMap = nil
                    return
                }
            }
        }
    }
    
    var mapFromPortal: AGSMap {
        let portalItem = AGSPortalItem(portal: portal, itemID: AppSettings.itemID)
        let map = AGSMap(item: portalItem)
        currentMap = map
        return map
    }
    
    var currentMap: AGSMap?
}
