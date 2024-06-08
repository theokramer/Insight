//
//  HandleBoxClick.swift
//  Insight
//
//  Created by Theo Kramer on 12.05.24.
//

import Foundation
import UIKit

extension ViewController {
    //Is called, when a box is clicked
    @objc func buttonTapped(_ sender: UIButton) {
        
        for layer in sender.layer.sublayers ?? [] {
            guard let shapeLayer = layer as? CAShapeLayer else {
                continue
            }
            if editMode {
                //Wenn der User einen weißen Button anklickt werden alle weißen Buttons mit dem gleichen Tag rot. Wenn der User einen roten Button anklickt wird nur dieser blau. Wenn der User einen blauen Button anklickt wird dieser weiß. Alle roten Buttons bekommen bei Klick auf den Save Button den gleichen Tag, alle blauen bekommen ebenfalls den gleichen Tag, aber einen anderen als die roten und alle weißen Buttons bekommen einen einzigartigen Tag
                if shapeLayer.fillColor == UIColor.white.cgColor {
                    shapeLayer.fillColor = UIColor.red.cgColor
                    
                }
                else if shapeLayer.fillColor == UIColor.blue.cgColor {
                    sender.tag = Int.random(in: 1..<10000000)
                    shapeLayer.fillColor = UIColor.white.cgColor
                }
                
                else {
                    sender.tag = Int.random(in: 1..<10000000)
                    shapeLayer.fillColor = UIColor.blue.cgColor
                }
                
                for view in view.subviews {
                                    if let button = view as? UIButton {
                                        
                                        if sender.tag == button.tag && sender.frame != button.frame {
                                            
                                            for layer2 in button.layer.sublayers ?? [] {
                                                print(sender)
                                                print(button)
                                                print("")
                                                guard let shapeLayer2 = layer2 as? CAShapeLayer else {
                                                    continue
                                                }
                                                if shapeLayer2.fillColor == UIColor.white.cgColor {
                                                    shapeLayer2.fillColor = UIColor.red.cgColor
                                                    
                                                }

                                            }
                                                                                    }
                                    
                                    }
                                }
                
                
            } else {
                
                
                
                for view in view.subviews {
                                    if let button = view as? UIButton {
                                        
                                        
                                        /*let distanceX = abs(sender.frame.midX - button.frame.midX)
                                         let distanceY = abs(sender.frame.midY - button.frame.midY)
                                         let minXDistance = (sender.frame.width + button.frame.width) / 2
                                         let minYDistance = (sender.frame.height + button.frame.height) / 2
                                        
                                        if ((sender.tag == button.tag) || (sender.frame.intersects(button.frame) || distanceX <= CGFloat(slider.value) + minXDistance && distanceY <=  CGFloat(slider.value) + minYDistance)) && sender.frame != button.frame {*/
                                        if sender.tag == button.tag && sender.frame != button.frame {
                                            for layer2 in button.layer.sublayers ?? [] {
                                                guard let shapeLayer2 = layer2 as? CAShapeLayer else {
                                                    continue
                                                }
                                                if shapeLayer2.fillColor == UIColor.clear.cgColor {
                                                    shapeLayer2.fillColor = UIColor.white.cgColor
                                                    
                                                } else {
                                                    shapeLayer2.fillColor = UIColor.clear.cgColor
                                                }

                                            }
                                        }
                                            
                                        //}
                                        
                                    }
                                }
                
                if shapeLayer.fillColor == UIColor.clear.cgColor {
                    shapeLayer.fillColor = UIColor.white.cgColor
                    
                } else {
                    shapeLayer.fillColor = UIColor.clear.cgColor
                }
            }
        }
        // Entferne den Button von der Ansicht und füge ihn wieder hinzu, um die Änderungen anzuzeigen
        sender.removeFromSuperview()
        view.addSubview(sender)
    }
}
