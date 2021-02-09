import UIKit
import ArcGIS

/// The URL of the portal with which to authenticate.
private let portalURL = URL(string: "https://www.arcgis.com")!
/// The Client ID for an app registered with the server. The provided ID is for
/// a public app created by the ArcGIS Runtime team.
private let portalItemID = "fb788308ea2e4d8682b9c05ef641f273"

/// The identifier with which this application was registered with the portal.
private let clientID = "lgAdHkYZYlwwfAhC"
/// The URL for redirecting after a successful authorization (this must be
/// configured in the Info plist).
private let redirectURLString = "my-ags-app://auth"

class ViewController: UIViewController, AGSGeoViewTouchDelegate, AGSPopupsViewControllerDelegate {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    
    var featureLayer: AGSFeatureLayer!
    
    func makeMap() -> AGSMap {
        let portal = AGSPortal(url: portalURL, loginRequired: true)
        let portalItem = AGSPortalItem(portal: portal, itemID: portalItemID)
        let map = AGSMap(item: portalItem)
        map.load { [unowned self] error in
            guard error == nil else { return }
            mapView.setViewpoint(AGSViewpoint(latitude: 37.79, longitude: -122.50, scale: 5e4))
            mapView.touchDelegate = self
            featureLayer = map.operationalLayers.firstObject as? AGSFeatureLayer
            featureLayer.definitionExpression =
                """
                req_Type <> 'Graffiti Complaint - Public Property' AND
                req_Type <> 'Graffiti Complaint – Private Property' AND
                req_Type <> 'Sewer Issues'
                """
        }
        return map
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        featureLayer.clearSelection()
        mapView.identifyLayer(featureLayer, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [unowned self] (result: AGSIdentifyLayerResult) in
            guard result.error == nil else { return }
            if let selectedFeature = result.geoElements.first as? AGSFeature {
                if !result.popups.isEmpty {
                    // Show the popup for the selected feature.
                    featureLayer.select(selectedFeature)
                    let popupsViewController = AGSPopupsViewController(popups: result.popups)
                    popupsViewController.modalPresentationStyle = .formSheet
                    popupsViewController.delegate = self
                    present(popupsViewController, animated: true)
                }
            } else {
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
    }
    
    // MARK: - OAuth configuration
    /// The OAuth configuration provided to the authentication manager.
    let oAuthConfiguration = AGSOAuthConfiguration(portalURL: portalURL, clientID: clientID, redirectURL: redirectURLString)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        AGSAuthenticationManager.shared().delegate = self
        AGSAuthenticationManager.shared().oAuthConfigurations.add(oAuthConfiguration)
    }
    
    deinit {
        AGSAuthenticationManager.shared().oAuthConfigurations.remove(oAuthConfiguration)
        AGSAuthenticationManager.shared().credentialCache.removeAllCredentials()
    }
    
    // MARK: - AGSPopupsViewControllerDelegate
    
    func popupsViewControllerDidFinishViewingPopups(_ popupsViewController: AGSPopupsViewController) {
        dismiss(animated: true)
    }
}

// MARK: - AGSAuthenticationManagerDelegate
extension ViewController: AGSAuthenticationManagerDelegate {
    func authenticationManager(_ authenticationManager: AGSAuthenticationManager, wantsToShow viewController: UIViewController) {
        viewController.modalPresentationStyle = .formSheet
        present(viewController, animated: true)
    }
    
    func authenticationManager(_ authenticationManager: AGSAuthenticationManager, wantsToDismiss viewController: UIViewController) {
        dismiss(animated: true)
    }
}
