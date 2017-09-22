//
//  ViewController.swift
//  CICropFilterExample
//
//  Created by TKang on 2017. 9. 22..
//  Copyright © 2017년 TKang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    // Label indicating max values
    @IBOutlet weak var originXMax: UILabel!
    @IBOutlet weak var originYMax: UILabel!
    @IBOutlet weak var widthMax: UILabel!
    @IBOutlet weak var heightMax: UILabel!
    // text field for cropping
    @IBOutlet weak var originXTextField: UITextField!
    @IBOutlet weak var originYTextField: UITextField!
    @IBOutlet weak var widthTextField: UITextField!
    @IBOutlet weak var heightTextField: UITextField!
    var textFields : [UITextField]!
    // CI Context
    var context : CIContext = CIContext(options: [kCIContextWorkingColorSpace:CGColorSpaceCreateDeviceRGB()])
    // Image View
    @IBOutlet weak var originalImageView: UIImageView!
    @IBOutlet weak var croppedImageView: UIImageView!
    // Constraint
    @IBOutlet weak var originalImageViewTopConstraint: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        textFields = [originXTextField, originYTextField, widthTextField, heightTextField]
        for textField in textFields {
            textField.delegate = self
            textField.keyboardType = .decimalPad
        }
        
        originXMax.text = "\(originalImageView.image!.size.width)"
        originYMax.text = "\(originalImageView.image!.size.height)"
        widthMax.text = "\(originalImageView.image!.size.width)"
        heightMax.text = "\(originalImageView.image!.size.height)"
        
        originXTextField.text = "0"
        originYTextField.text = "0"
        widthTextField.text = "\(originalImageView.image!.size.width)"
        heightTextField.text = "\(originalImageView.image!.size.height)"
        
        configureGestureRecognizer()
        
        //Notification for getting keyboard frame
        NotificationCenter.default.addObserver(self, selector: #selector(moveContentsUp(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(moveContentDown(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCroppedImage(_:)), name: NSNotification.Name.UITextFieldTextDidChange, object: nil)
    }

    func configureGestureRecognizer() {
        let tapGestureForDismissingKeyboard = UITapGestureRecognizer(target: self, action: #selector(dissmissKeyboard))
        self.view.addGestureRecognizer(tapGestureForDismissingKeyboard)
    }
    
    @objc func dissmissKeyboard() {
        for textField in textFields {
            textField.resignFirstResponder()
        }
        
        originalImageViewTopConstraint.constant = 0
    }

    func crop(image: UIImage) -> UIImage {
        let imageCIForm = CIImage(image: image)!
        let originX = CGFloat(Float(originXTextField.text!)!)
        let originY = CGFloat(Float(originYTextField.text!)!)
        let width = CGFloat(Float(widthTextField.text!)!) <= 0 ? CGFloat(1.0) : CGFloat(Float(widthTextField.text!)!)
        let height = CGFloat(Float(heightTextField.text!)!) <= 0 ? CGFloat(1.0) : CGFloat(Float(heightTextField.text!)!)
        
        let cropRect = CGRect(x: originX, y: originY, width: width, height: height)
        // Transform for changing coordinate system
        let scale = CGAffineTransform(scaleX: 1, y: -1)
        let translation = CGAffineTransform(translationX: 0, y: originalImageView.image!.size.height)
        let concatenated = scale.concatenating(translation)
        let transformedCropRect = cropRect.applying(concatenated)
        let cropFilter = CIFilter(name: "CICrop", withInputParameters: [kCIInputImageKey: imageCIForm,
                                                                        "inputRectangle": transformedCropRect])
        let croppedCIImage = (cropFilter?.outputImage)!
        
        let croppedCGImage = context.createCGImage(croppedCIImage, from: croppedCIImage.extent)!
        
        return UIImage(cgImage: croppedCGImage)
    }
    
    @objc func updateCroppedImage(_ notification: Notification) {
        croppedImageView.image = crop(image: originalImageView.image!)
    }
    
    @objc func moveContentsUp(_ notification : Notification) {
        let userInfo = notification.userInfo!
        let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as! CGRect
        
        originalImageViewTopConstraint.constant = -keyboardFrame.height
    }
    
    @objc func moveContentDown(_ notification : Notification) {
        originalImageViewTopConstraint.constant = 0
    }
}

extension ViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var textFieldText = textField.text ?? ""
        textFieldText.replaceSubrange(Range(range, in: textField.text ?? "")!, with: string)
        
        if let number = Float(textFieldText) {
            print("number is \(number)")
            switch textField {
            case originXTextField:
                if number > Float(originXMax.text!)! {
                    originXTextField.text = originXMax.text
                    widthMax.text = "0"
                    widthTextField.text = "0"
                    return false
                } else if number < 0 {
                    originXTextField.text = "0"
                    widthMax.text = "\(originalImageView.image!.size.width)"
                    return false
                } else {
                    widthMax.text = "\(Float(originalImageView.image!.size.width) - number)"
                    if Float(widthTextField.text!)! > Float(widthMax.text!)! {
                        widthTextField.text = widthMax.text
                    }
                    // remove '0' if it is ahead of number
                    if (originXTextField.text!).hasPrefix("0") {
                        let range = originXTextField.text!.range(of: "0")!
                        originXTextField.text?.replaceSubrange(range, with: "")
                    }
                    return true
                }
            case originYTextField:
                if number > Float(originYMax.text!)! {
                    originYTextField.text = originYMax.text
                    heightMax.text = "0"
                    heightTextField.text = "0"
                    return false
                } else if number < 0 {
                    originYTextField.text = "0"
                    heightMax.text = "\(originalImageView.image!.size.height)"
                    return false
                } else {
                    heightMax.text = "\(Float(originalImageView.image!.size.height) - number)"
                    if Float(heightTextField.text!)! > Float(heightMax.text!)! {
                        heightTextField.text = heightMax.text
                    }
                    // remove '0' if it is ahead of number
                    if (originYTextField.text!).hasPrefix("0") {
                        let range = originYTextField.text!.range(of: "0")!
                        originYTextField.text?.replaceSubrange(range, with: "")
                    }
                    return true
                }
            case widthTextField:
                if number > Float(widthMax.text!)! {
                    widthTextField.text = widthMax.text
                    return false
                } else if number < 0 {
                    widthTextField.text = "0"
                    return false
                } else {
                    // remove '0' if it is ahead of number
                    if (widthTextField.text!).hasPrefix("0") {
                        let range = widthTextField.text!.range(of: "0")!
                        widthTextField.text?.replaceSubrange(range, with: "")
                    }
                    return true
                }
            case heightTextField:
                if number > Float(heightMax.text!)! {
                    heightTextField.text = heightMax.text
                    return false
                } else if number < 0 {
                    heightTextField.text = "0"
                    return false
                } else {
                    // remove '0' if it is ahead of number
                    if (heightTextField.text!).hasPrefix("0") {
                        let range = heightTextField.text!.range(of: "0")!
                        heightTextField.text?.replaceSubrange(range, with: "")
                    }
                    return true
                }
            default:
                break
            }
        } else {
            switch textField {
            case originXTextField:
                originXTextField.text = "0"
                widthMax.text = "\(originalImageView.image!.size.width)"
                return false
            case originYTextField:
                originYTextField.text = "0"
                heightMax.text = "\(originalImageView.image!.size.height)"
                return false
            case widthTextField:
                widthTextField.text = "0"
                return false
            case heightTextField:
                heightTextField.text = "0"
                return false
            default:
                break
            }
        }
        
        return true
    }
}

