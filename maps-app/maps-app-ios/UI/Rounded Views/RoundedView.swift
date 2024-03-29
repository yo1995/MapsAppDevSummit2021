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

@IBDesignable
public class RoundedView: UIView {
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            setLayerProperties()
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }
    
    @IBInspectable var circular: Bool = false {
        didSet {
            setLayerProperties()
        }
    }
    
    @IBInspectable var shadow: Bool = false {
        didSet {
            setLayerProperties()
        }
    }
    
    private func setLayerProperties() {
        layer.cornerRadius = circular ? self.bounds.width / 2 : cornerRadius
        
        if shadow {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.3
            layer.shadowRadius = 3
            layer.shadowOffset = CGSize(width: 0, height: 0)
            layer.masksToBounds = false
        } else {
            layer.shadowColor = UIColor.clear.cgColor
            layer.shadowOpacity = 1
            layer.shadowRadius = 0
            layer.masksToBounds = layer.cornerRadius > 0
        }
    }
}
