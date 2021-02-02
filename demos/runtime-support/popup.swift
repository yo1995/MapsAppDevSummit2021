import UIKit
import ArcGIS

class ViewController: UIViewController, AGSGeoViewTouchDelegate, AGSPopupsViewControllerDelegate {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    
    var featureLayer: AGSFeatureLayer!
    
    func makeMap() -> AGSMap {
        let map = AGSMap(url: URL(string: "https://arcgisruntime.maps.arcgis.com/home/item.html?id=fb788308ea2e4d8682b9c05ef641f273")!)!
        map.load { [unowned self] error in
            guard error == nil else { return }
            mapView.setViewpoint(AGSViewpoint(latitude: 37.79, longitude: -122.50, scale: 5e4))
            mapView.touchDelegate = self
            featureLayer = map.operationalLayers.firstObject as? AGSFeatureLayer
        }
        return map
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        featureLayer.clearSelection()
        mapView.identifyLayer(featureLayer, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [unowned self] (result: AGSIdentifyLayerResult) in
            guard result.error == nil, let selectedFeature = result.geoElements.first as? AGSFeature else { return }
            if !result.popups.isEmpty {
                featureLayer.select(selectedFeature)
                let popupsViewController = AGSPopupsViewController(popups: result.popups)
                popupsViewController.modalPresentationStyle = .formSheet
                popupsViewController.delegate = self
                present(popupsViewController, animated: true)
            }
        }
    }
    
    // MARK: - AGSPopupsViewControllerDelegate
    
    func popupsViewControllerDidFinishViewingPopups(_ popupsViewController: AGSPopupsViewController) {
        dismiss(animated: true)
    }
}
