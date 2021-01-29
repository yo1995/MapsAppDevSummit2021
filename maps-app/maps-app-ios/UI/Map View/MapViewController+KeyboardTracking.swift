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

import UIKit

extension MapViewController {
    func setupMapViewAttributeBarTracking(activate: Bool) {
        // Set up a constraint between the MapView's attribution panel and the bottom of our UI.
        attributeAnchor = controlsView.bottomAnchor.constraint(lessThanOrEqualTo: mapView.attributionTopAnchor, constant: -12)
        attributeAnchor?.isActive = activate
    }
    
    func setupKeyboardTracking(activate: Bool) {
        // Set up a constraint between the a special view used to align with the keyboard, and our UI.
        keyboardAnchor = controlsView.bottomAnchor.constraint(equalTo: keyboardSpacer.topAnchor, constant: -12)
        keyboardAnchor?.isActive = activate
    }
    
    func activateKeyboardTracking() {
        // Listen to keyboard notifications.
        for notificationName in [UIResponder.keyboardWillShowNotification, UIResponder.keyboardWillHideNotification] {
            keyboardObservers.append(NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) { notification in
                // Set our special view that tracks the keyboard. Either display or hide.
                self.setKeyboardSpacerFromKeyboardNotification(notification: notification)
            })
        }
    }
    
    func deactivateKeyboardTracking() {
        // Stop listening to keyboard notifications.
        for observer in keyboardObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        
        keyboardObservers.removeAll()
    }
    
    private func setKeyboardSpacerFromKeyboardNotification(notification: Notification) {
        // If we got information about the keyboard position (shown or hidden), animate our special tracking UIView
        // to follow the keyboard. Constraints between that view and the rest of our UI will ensure our UI also animates
        // to avoid being hidden by the keyboard.
        // Derived from code found at https://stackoverflow.com/questions/8704137/keeping-object-on-top-of-keyboard-in-the-event-of-becomefirstresponder-or-resign
        if let userInfo = notification.userInfo,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let endFrameInContext = view.convert(endFrame, to: self.view)
            let newHeight = view.bounds.maxY - endFrameInContext.minY
            
            UIView.animate(withDuration: duration) {
                if notification.name == UIResponder.keyboardWillShowNotification {
                    self.attributeAnchor?.isActive = false
                    self.keyboardAnchor?.isActive = true
                } else if notification.name == UIResponder.keyboardWillHideNotification {
                    self.attributeAnchor?.isActive = true
                    self.keyboardAnchor?.isActive = false
                }
                
                self.keyboardSpacerHeightConstraint.constant = newHeight
                self.view.layoutIfNeeded()
            }
        }
    }
}
