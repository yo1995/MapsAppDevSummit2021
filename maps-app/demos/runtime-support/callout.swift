import UIKit
import ArcGIS

class ViewController: UIViewController, AGSGeoViewTouchDelegate {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            let map = AGSMap(basemapStyle: .arcGISTopographic)
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
            mapView.setViewpoint(AGSViewpoint(latitude: 34, longitude: -117, scale: 4e7))
            mapView.touchDelegate = self
        }
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if mapView.callout.isHidden {
            // Show the callout with the coordinates of the tapped location.
            mapView.callout.title = "Location"
            let projectedPoint = AGSGeometryEngine.projectGeometry(mapPoint, to: .wgs84()) as! AGSPoint
            mapView.callout.detail = String(format: "x: %.2f, y: %.2f", projectedPoint.x, projectedPoint.y)
            mapView.callout.isAccessoryButtonHidden = true
            mapView.callout.show(at: mapPoint, screenOffset: .zero, rotateOffsetWithMap: false, animated: true)
        } else {
            // Hide the callout.
            mapView.callout.dismiss()
        }
    }
}
