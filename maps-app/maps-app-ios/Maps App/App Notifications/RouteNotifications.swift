// Copyright 2017 Esri.
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

import ArcGIS

// MARK: External Notification API
extension MapsAppNotifications {
    // MARK: Register Listeners
    static func observeRouteSolvedNotification(owner: Any, routeSolvedHandler: @escaping ((AGSRoute) -> Void)) {
        let ref = NotificationCenter.default.addObserver(forName: MapsAppNotifications.Names.routeSolved, object: mapsApp, queue: OperationQueue.main) { notification in
            if let routeResult = notification.routeResult {
                routeSolvedHandler(routeResult)
            }
        }
        MapsAppNotifications.registerBlockHandler(blockHandler: ref, forOwner: owner)
    }
}

// MARK: Internals
extension MapsAppNotifications {
    static func postRouteSolvedNotification(result: AGSRoute) {
        NotificationCenter.default.post(name: MapsAppNotifications.Names.routeSolved, object: mapsApp, userInfo: [RouteNotificationKeys.route: result])
    }
}

// MARK: Typed Notification Pattern
extension MapsAppNotifications.Names {
    static let routeSolved = Notification.Name("MapsAppRouteSolvedNotification")
}

extension Notification {
    var routeResult: AGSRoute? {
        guard self.name == MapsAppNotifications.Names.routeSolved else {
            return nil
        }

        return self.userInfo?[RouteNotificationKeys.route] as? AGSRoute
    }
}

// MARK: Internal Constants
private struct RouteNotificationKeys {
    static let route = "route"
}
