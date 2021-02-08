import UIKit
import ArcGIS

class ViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemap: makeBasemap(for: traitCollection.userInterfaceStyle))
            mapView.setViewpoint(
                AGSViewpoint(
                    latitude: 33.96,
                    longitude: -118.81,
                    scale: 1e7
                )
            )
        }
    }
    
    func makeBasemap(for userInterfaceStyle: UIUserInterfaceStyle) -> AGSBasemap {
        let basemap: AGSBasemap
        switch userInterfaceStyle {
        case .light:
            basemap = AGSBasemap(style: .arcGISLightGray)
        case .dark:
            basemap = AGSBasemap(style: .arcGISDarkGray)
        default:
            fatalError("Unknown interface style.")
        }
        return basemap
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        mapView.map?.basemap = makeBasemap(for: traitCollection.userInterfaceStyle)
    }
}
