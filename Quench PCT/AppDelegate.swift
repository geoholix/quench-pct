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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        configCredentialCacheAutoSyncToKeychain()
        configOAuthRedirectURL()
//        attemptLoginToPortalFromCredentials()
        
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {

        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), urlComponents.scheme == "pctguide", urlComponents.host == "auth" {
            AGSApplicationDelegate.shared().application(app, open: url, options: options)
        }
        return true
    }

    func configCredentialCacheAutoSyncToKeychain() {
        AGSAuthenticationManager.shared().credentialCache.enableAutoSyncToKeychain(withIdentifier: "pctguide.keychainID",
                                                                                   accessGroup: nil,
                                                                                   acrossDevices: false)
    }
    
    func configOAuthRedirectURL() {
        let oauthConfig = AGSOAuthConfiguration(portalURL: URL(string: "www.arcgis.com")!,
                                                clientID: "3Rn33c2oN4mpiGFE",
                                                redirectURL: "pctguide://auth")
        AGSAuthenticationManager.shared().oAuthConfigurations.add(oauthConfig)
    }
    
    func attemptLoginToPortalFromCredentials() {
        let authenticationRequiredPortal = AGSPortal(url: AppSettings.mapURL, loginRequired: true)
        let authenticationRequiredPortalRequestConfiguration = authenticationRequiredPortal.requestConfiguration
        let slientAuthenticationRequestConfiguration = (authenticationRequiredPortalRequestConfiguration ?? AGSRequestConfiguration.global()).copy() as? AGSRequestConfiguration
        slientAuthenticationRequestConfiguration?.shouldIssueAuthenticationChallenge = { _ in return false }
        authenticationRequiredPortal.requestConfiguration = slientAuthenticationRequestConfiguration
        authenticationRequiredPortal.load() { error in
            authenticationRequiredPortal.requestConfiguration = authenticationRequiredPortalRequestConfiguration
            if let error = error {
                print("[Error] loading the new fake portal, user is not authenticated: \(error.localizedDescription)")
                appSettings.portal = AGSPortal(url: AppSettings.mapURL, loginRequired: false)
            }
            else {
                appSettings.portal = AGSPortal(url: AppSettings.mapURL, loginRequired: false)
            }
        }
        appSettings.portal = AGSPortal(url: AppSettings.mapURL, loginRequired: false)
    }

}

