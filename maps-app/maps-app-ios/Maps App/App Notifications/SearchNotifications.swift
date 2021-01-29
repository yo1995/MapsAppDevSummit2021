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
    static func observeSearchNotifications(owner: Any, searchResultHandler:@escaping ((AGSGeocodeResult?) -> Void), suggestionsAvailableHandler: (([AGSSuggestResult]?) -> Void)? = nil) {
        let ref = NotificationCenter.default.addObserver(forName: MapsAppNotifications.Names.searchCompleted, object: mapsApp, queue: OperationQueue.main) { notification in
            searchResultHandler(notification.searchResult)
        }
        MapsAppNotifications.registerBlockHandler(blockHandler: ref, forOwner: owner)
        
        if let suggestionsAvailableHandler = suggestionsAvailableHandler {
            let ref = NotificationCenter.default.addObserver(forName: MapsAppNotifications.Names.searchSuggestionsAvailable, object: mapsApp, queue: OperationQueue.main) { notification in
                suggestionsAvailableHandler(notification.searchSuggestions)
            }
            MapsAppNotifications.registerBlockHandler(blockHandler: ref, forOwner: owner)
        }
    }
}

// MARK: Internals
extension MapsAppNotifications {
    static func postSearchSuggestionsAvailableNotification(suggestions: [AGSSuggestResult]) {
        // Notify that we'd like to get search suggestions based off a SearchBar's text.
        var userInfo: [AnyHashable: Any] = [:]
        
        if !suggestions.isEmpty {
            userInfo[SearchNotificationKeys.suggestions] = suggestions
        }
        
        NotificationCenter.default.post(name: MapsAppNotifications.Names.searchSuggestionsAvailable, object: mapsApp, userInfo: userInfo)
    }
    
    static func postSearchCompletedNotification(result: AGSGeocodeResult? = nil) {
        // Notify that we're no longer searching and it's time to hide any related UI (e.g. the suggestion panel)
        var userInfo: [AnyHashable: Any] = [:]
        
        if let result = result {
            userInfo[SearchNotificationKeys.searchResult] = result
        }
        
        NotificationCenter.default.post(name: MapsAppNotifications.Names.searchCompleted, object: mapsApp, userInfo: userInfo)
    }
}

// MARK: Typed Notification Pattern
extension MapsAppNotifications.Names {
    static let searchSuggestionsAvailable = Notification.Name("MapsAppSearchSuggestionsAvailableNotification")
    static let searchCompleted = Notification.Name("MapsAppSearchCompletedNotification")
}

extension Notification {
    var searchSuggestions: [AGSSuggestResult]? {
        guard self.name == MapsAppNotifications.Names.searchSuggestionsAvailable else {
            return nil
        }
        
        return self.userInfo?[SearchNotificationKeys.suggestions] as? [AGSSuggestResult]
    }

    var searchResult: AGSGeocodeResult? {
        guard self.name == MapsAppNotifications.Names.searchCompleted else {
            return nil
        }
        
        return self.userInfo?[SearchNotificationKeys.searchResult] as? AGSGeocodeResult
    }
}

// MARK: Internal Constants
private struct SearchNotificationKeys {
    static let searchResult = "result"
    static let suggestions = "suggestions"
}
