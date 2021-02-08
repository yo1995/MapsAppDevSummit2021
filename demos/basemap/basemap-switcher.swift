import UIKit
import ArcGIS

class ViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: currentBasemapStyle)
            mapView.setViewpoint(
                AGSViewpoint(
                    latitude: 34.05,
                    longitude: -118.24,
                    scale: 1e5
                )
            )
        }
    }
    
    private var currentBasemapStylePair: (AGSBasemapStyle, AGSBasemapStyle) = (.arcGISLightGray, .arcGISDarkGray) {
        didSet {
//            mapView.map?.basemap = AGSBasemap(style: currentBasemapStyle)
            mapView.map?.basemap = makeBasemap(style: currentBasemapStyle)
        }
    }
    
    private var currentBasemapStyle: AGSBasemapStyle {
        traitCollection.userInterfaceStyle == .light ? currentBasemapStylePair.0 : currentBasemapStylePair.1
    }
    
    private let basemapStyleMappings: [Styles: (AGSBasemapStyle, AGSBasemapStyle)] = [
        .arcGISGray: (.arcGISLightGray, .arcGISDarkGray),
        .navigation: (.arcGISNavigation, .arcGISNavigationNight),
        .streets: (.arcGISStreets, .arcGISStreetsNight),
        .osmGray: (.osmLightGray, .osmDarkGray)
    ]
    
    private var basemapCaches: [AGSBasemapStyle: AGSBasemap] = [:]
    
    private enum Styles: CaseIterable {
        case streets, navigation, osmGray, arcGISGray
        
        var label: String {
            switch self {
            case .streets:
                return "Streets"
            case .navigation:
                return "Navigation"
            case .osmGray:
                return "Open Street Map Gray"
            case .arcGISGray:
                return "ArcGIS Gray"
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
//        mapView.map?.basemap = AGSBasemap(style: currentBasemapStyle)
        mapView.map?.basemap = makeBasemap(style: currentBasemapStyle)
    }
    
    private func setupUI() {
        navigationController?.navigationBar.isHidden = true
        navigationController?.setToolbarHidden(false, animated: false)
        let items: [UIBarButtonItem] = [
            .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            .init(title: "Choose Basemap Style", style: .plain, target: self, action: #selector(chooseBasemap)),
            .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        ]
        setToolbarItems(items, animated: true)
    }
    
    @objc
    private func chooseBasemap(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "Choose a basemap.",
            message: nil,
            preferredStyle: .actionSheet
        )
        basemapStyleMappings.forEach { style, pair in
            let action = UIAlertAction(title: style.label, style: .default) { [self] _ in
                currentBasemapStylePair = pair
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = sender
        present(alertController, animated: true)
    }
    
    private func setUpCaches() {
        for (light, dark) in basemapStyleMappings.values {
            let b1 = AGSBasemap(style: light)
            let b2 = AGSBasemap(style: dark)
            b1.load()
            b2.load()
            basemapCaches[light] = b1
            basemapCaches[dark] = b2
        }
    }
    
    private func makeBasemap(style: AGSBasemapStyle) -> AGSBasemap {
        if let basemap = basemapCaches[style] {
            return basemap
        }
        return AGSBasemap(style: style)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setUpCaches()
    }
}
