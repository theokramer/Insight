//
//  HandleBoxClick.swift
//  Insight
//
//  Created by Theo Kramer on 12.05.24.
//

import Foundation
import UIKit

extension ViewController {
        
        // Function to handle button tap
        @objc func buttonTapped(_ sender: UIButton) {
            
            if viewController {
                let tag = sender.tag
                
                // Remove any existing overlay view
                if let existingOverlay = view.viewWithTag(9999) {
                    existingOverlay.removeFromSuperview()
                }
                
                // Create overlay view
                let overlayView = UIView(frame: CGRect(x: sender.frame.minX, y: sender.frame.minY - 50, width: 100, height: 50))
                overlayView.backgroundColor = .white
                overlayView.layer.cornerRadius = 5
                overlayView.layer.borderColor = UIColor.gray.cgColor
                overlayView.layer.borderWidth = 1
                overlayView.tag = 9999 // Assign a unique tag to identify the overlay view
                
                // Create delete button
                let deleteButton = UIButton(frame: CGRect(x: 5, y: 5, width: 40, height: 40))
                deleteButton.setTitle("Del", for: .normal)
                deleteButton.setTitleColor(.red, for: .normal)
                deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
                deleteButton.tag = tag // Pass the tag to the delete button
                
                // Create edit button
                let editButton = UIButton(frame: CGRect(x: 55, y: 5, width: 40, height: 40))
                editButton.setTitle("Edit", for: .normal)
                editButton.setTitleColor(.blue, for: .normal)
                editButton.addTarget(self, action: #selector(editButtonTapped(_:)), for: .touchUpInside)
                editButton.tag = tag // Pass the tag to the edit button
                
                // Add buttons to overlay view
                overlayView.addSubview(deleteButton)
                overlayView.addSubview(editButton)
                
                // Add overlay view to main view
                view.addSubview(overlayView)
            } else {
                for layer in sender.layer.sublayers ?? [] {
                    guard let shapeLayer = layer as? CAShapeLayer else {
                        continue
                    }
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
                                        shapeLayer2.fillColor = toggleColor.cgColor
                                        
                                    } else {
                                        shapeLayer2.fillColor = UIColor.clear.cgColor
                                    }
                                    
                                }
                            }
                            
                            //}
                            
                        }
                    }
                    
                    if shapeLayer.fillColor == UIColor.clear.cgColor {
                        shapeLayer.fillColor = toggleColor.cgColor
                        
                    } else {
                        shapeLayer.fillColor = UIColor.clear.cgColor
                    }
                }
            }
            
        }
        
        // Function to handle delete button tap
        @objc func deleteButtonTapped(_ sender: UIButton) {
            // Handle delete action here
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            
            let tag = sender.tag
        
            
            for i in 0..<selectedImages[imageIndex].boxes.count {
                if selectedImages[imageIndex].boxes[i].tag == tag {
                    selectedImages[imageIndex].boxes.remove(at: i)
                }
            }
            
             ViewController.fetchCoreDataBoxes {items in
             if let items = (items ?? []) as [ImageBoxes]? {
             for item in items {
                 print("Dieser Tag ist drin: ", item.tag)
             if tag == item.tag {
                 print("Dieser Tag wird gelöscht: ", tag)
             context.delete(item)
             do {
             try context.save()
             print("Single Success")
                 
             } catch {
             print("error-Deleting data")
             }
             
             }
             }
             } else {
             print("FEHLER")
             }
             }
            
            if let buttonView = view.viewWithTag(tag) {
                buttonView.removeFromSuperview()
            }
            
            // Remove the overlay view
            if let overlayView = view.viewWithTag(9999) {
                overlayView.removeFromSuperview()
            }
        }
        
        // Function to handle edit button tap
        @objc func editButtonTapped(_ sender: UIButton) {
            let tag = sender.tag
            // Handle edit action here
            print("Edit button tapped for tag: \(tag)")
            
            // Remove the overlay view
            if let overlayView = view.viewWithTag(9999) {
                overlayView.removeFromSuperview()
            }
        }

    
    
    
    //Is called, when a box is clicked
    /*@objc func buttonTapped(_ sender: UIButton) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
         
         ViewController.fetchCoreDataBoxes {items in
         if let items = (items ?? []) as [ImageBoxes]? {
         for item in items {
         if sender.tag == item.tag {
         context.delete(item)
         do {
         try context.save()
         print("Single Success")
         } catch {
         print("error-Deleting data")
         }
         
         }
         }
         } else {
         print("FEHLER")
         }
         }*/
        
        /*for layer in sender.layer.sublayers ?? [] {
         guard let shapeLayer = layer as? CAShapeLayer else {
         continue
         }
         if editMode {
         //Wenn der User einen weißen Button anklickt werden alle weißen Buttons mit dem gleichen Tag rot. Wenn der User einen roten Button anklickt wird nur dieser blau. Wenn der User einen blauen Button anklickt wird dieser weiß. Alle roten Buttons bekommen bei Klick auf den Save Button den gleichen Tag, alle blauen bekommen ebenfalls den gleichen Tag, aber einen anderen als die roten und alle weißen Buttons bekommen einen einzigartigen Tag
         if shapeLayer.fillColor == toggleColor.cgColor {
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
         if shapeLayer2.fillColor == toggleColor.cgColor {
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
         shapeLayer2.fillColor = toggleColor.cgColor
         
         } else {
         shapeLayer2.fillColor = UIColor.clear.cgColor
         }
         
         }
         }
         
         //}
         
         }
         }
         
         if shapeLayer.fillColor == UIColor.clear.cgColor {
         shapeLayer.fillColor = toggleColor.cgColor
         
         } else {
         shapeLayer.fillColor = UIColor.clear.cgColor
         }
         }
         }
         // Entferne den Button von der Ansicht und füge ihn wieder hinzu, um die Änderungen anzuzeigen
         sender.removeFromSuperview()
         view.addSubview(sender)
         }
    }*/
}
