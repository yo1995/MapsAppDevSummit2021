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

class MapViewController: UIViewController {
    // MARK: UI Outlets
    @IBOutlet weak var mapView: AGSMapView!
    
    @IBOutlet weak var controlsView: UIStackView!
    @IBOutlet weak var gpsButton: UIButton!
    
    @IBOutlet weak var prevNextModeView: UIView!
    @IBOutlet weak var prevModeButton: UIButton!
    @IBOutlet weak var nextModeButton: UIButton!
    
    // MARK: Keyboard Tracking
    @IBOutlet weak var keyboardSpacer: UIView!
    @IBOutlet weak var keyboardSpacerHeightConstraint: NSLayoutConstraint!
    var keyboardObservers: [NSObjectProtocol] = []
    
    var attributeAnchor: NSLayoutConstraint?
    var keyboardAnchor: NSLayoutConstraint?
    
    // MARK: Map feedback layers
    var graphicsOverlays: [String: AGSGraphicsOverlay] = [:]
    
    // MARK: MapView Mode
    var mode: MapViewMode = .none {
        didSet {
            switch mode {
            case .routeResult, .geocodeResult:
                undoableMode = mode
            default:
                break
            }

            updateMapViewForMode()

            // Announce that the mode has changed (the Feedback Panel UI listens to this)
            MapsAppNotifications.postModeChangeNotification(oldMode: oldValue, newMode: mode)
        }
    }
    
    // MARK: Mode History
    var modeHistory: [MapViewMode] = []
    var modeIndex: Int = -1 {
        didSet {
            let newMode = modeHistory[modeIndex]
            mode = newMode
        }
    }
    
    var undoableMode: MapViewMode? {
        didSet {
            updateModeHistory(newMode: undoableMode)
            
            setModeHistoryUI()
        }
    }
    
    // MARK: View initialization
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        // Set up a default map
        mapView.map = AGSMap(basemapType: .topographicVector, latitude: 40.7128, longitude: -74.0059, levelOfDetail: 10)
        
        // Read any preferences and set up hooks to automatically store preferences.
        setupAppPreferences()

        // Set up some UI.
        setupRouting()
        setupSearch()
        setupLocationDisplay()
        
        // Set up handlers for events that could change the map.
        setupBasemapChangeHandler()
        setupCurrentItemChangeHandler()

        // Set up some other UX related handlers.
        setupTouchEventsHandler()
        setupFeedbackPanelResizeHandler()
        setupMapViewAttributeBarTracking(activate: true)
        setupKeyboardTracking(activate: false)
        
        // Setup the mode history behaviour.
        setModeHistoryUI()

        MapsAppNotifications.observeMapViewExtentNotifications(
            owner: self,
            resetExtentHandler: { [weak self] in
                self?.updateMapViewExtentForMode()
            }, focusOnExtentHandler: { [weak self] requestedExtent in
                self?.mapView.setViewpoint(AGSViewpoint(targetExtent: requestedExtent), completion: nil)
            }
        )
        
        mapsAppContext.currentMapView = mapView
        
        // And start off in Search Mode.
        mode = .search
    }
    
    deinit {
        MapsAppNotifications.deregisterNotificationBlocks(forOwner: self)
        teardownAppPreferences()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Start caring about the keyboard display when the view appears.
        activateKeyboardTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop caring about the keyboard display when the view disappears.
        deactivateKeyboardTracking()
    }
    
    // MARK: Dark Mode Adaption
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Make some basemaps Dark Mode adaptive by replacing them with their
        // light/dark style counterpart when the userInterfaceStyle changes.
        if let itemID = mapsAppContext.currentBasemap?.itemID,
           let style = idStyleMapping[itemID],
           let pair = basemapStyleMappings[style] {
            currentBasemapStylePair = pair
        }
    }
    
    private let idStyleMapping: [String: Styles] = [
        "a343955125bf4002987c400ad6d0346c": .arcGISGray,
        "de45b9cad20141ebb82fae0da8b3e2c6": .arcGISGray,
        "f81bc478e12c4f1691d0d7ab6361f5a6": .streets,
        "1c8ddaba2ee9498cb0025554351e5475": .streets,
        "61ffcf610f314933916e4b2c0e477b29": .navigation,
        "459cc334740944d38580455a0a777a24": .navigation
    ]
    
    private let basemapStyleMappings: [Styles: (AGSBasemapStyle, AGSBasemapStyle)] = [
        .arcGISGray: (.arcGISLightGray, .arcGISDarkGray),
        .streets: (.arcGISStreets, .arcGISStreetsNight),
        .navigation: (.arcGISNavigation, .arcGISNavigationNight)
    ]
    
    private var currentBasemapStylePair: (AGSBasemapStyle, AGSBasemapStyle) = (.arcGISLightGray, .arcGISDarkGray) {
        didSet {
            mapView.map?.basemap = AGSBasemap(style: currentBasemapStyle)
        }
    }
    
    private var currentBasemapStyle: AGSBasemapStyle {
        traitCollection.userInterfaceStyle == .light ? currentBasemapStylePair.0 : currentBasemapStylePair.1
    }
    
    private enum Styles: CaseIterable {
        case streets, arcGISGray, navigation
    }
}
