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

let maxPageDisplayCount: Int = 10

class DirectionsDisplayViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet weak var maneuversView: UICollectionView!
    @IBOutlet weak var roundedContainerView: RoundedView!
    @IBOutlet weak var pageControl: FlexiblePageControl!
    
    var directions: AGSRoute? {
        didSet {
            pageControl.displayCount = maxPageDisplayCount
            pageControl.numberOfPages = directions?.directionManeuvers.count ?? 0
            
            if directions == nil {
                currentCellIndex = nil
            }
            
            maneuversView.reloadData()
            
            configureCollectionViewLayout()

            UIView.animate(withDuration: 0.25, animations: {
                self.view.superview?.isHidden = (self.directions == nil)
            })
            
            setCurrentCell()
        }
    }
    
    var currentCellIndex: IndexPath? {
        didSet {
            pageControl.currentPage = currentCellIndex?.row ?? 0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        maneuversView.decelerationRate = .normal
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        MapsAppNotifications.observeModeChangeNotification(owner: self) { [weak self] _, newMode in
            switch newMode {
            case .routeResult(let route):
                self?.directions = route
            default:
                self?.directions = nil
            }
        }
        
        // Workaround to ensure the UICollectionView doesn't extend beyond the RoundedView container.
        maneuversView.layer.masksToBounds = true
        maneuversView.layer.cornerRadius = roundedContainerView.layer.cornerRadius

        directions = nil
    }
    
    deinit {
        MapsAppNotifications.deregisterNotificationBlocks(forOwner: self)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setCurrentCell()
    }
    
    func setCurrentCell() {
        guard directions != nil else {
            currentCellIndex = nil
            return
        }
        
        if let cell = maneuversView.cellAtVisibleCenter as? DirectionManeuverCell,
            let cellIndex = maneuversView.indexPath(for: cell),
            currentCellIndex != cellIndex,
            let maneuver = cell.maneuver {
            currentCellIndex = cellIndex
            MapsAppNotifications.postManeuverFocusNotification(maneuver: maneuver)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // Handle the view orientation changing (or any resize for that matter)
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { context in
            guard !context.isCancelled else {
                return
            }
            
            guard !self.maneuversView.isHidden else {
                return
            }

            // Figure out what the cell size should be for the new size
            self.configureCollectionViewLayout()
            
            // If we have a current cell, make sure it's displayed.
            if let cellIndex = self.currentCellIndex {
                self.maneuversView.scrollToItem(at: cellIndex, at: .centeredHorizontally, animated: false)
            }
        }
    }
    
    private func configureCollectionViewLayout() {
        if let layout = maneuversView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(width: maneuversView.frame.size.width - layout.minimumInteritemSpacing, height: maneuversView.frame.size.height)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return directions?.directionManeuvers.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "maneuverCell", for: indexPath)
        
        if let cell = cell as? DirectionManeuverCell, let maneuvers = directions?.directionManeuvers, indexPath.row < maneuvers.count {
            let maneuver = maneuvers[indexPath.row]
            cell.index = indexPath.row
            cell.maneuver = maneuver
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? DirectionManeuverCell, let maneuver = cell.maneuver {
            MapsAppNotifications.postManeuverFocusNotification(maneuver: maneuver)
        }
    }
}
