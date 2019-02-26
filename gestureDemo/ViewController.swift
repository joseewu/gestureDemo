//
//  ViewController.swift
//  gestureDemo
//
//  Created by joseewu on 2019/2/21.
//  Copyright © 2019 com. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var tapOnScreen:UITapGestureRecognizer = UITapGestureRecognizer()
    var imageStack:[UIImageView] = [UIImageView]()
    var lastScale:CGFloat = 1.0
    var lastRotation: CGFloat = 0
    var trashCanFrame:CGRect = CGRect.zero
    var activeRecognizers:Set<UIGestureRecognizer> = Set<UIGestureRecognizer>.init()
    @IBOutlet weak var trashCan: UIImageView! {
        didSet{
            trashCanFrame = trashCan.frame
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        renderUi()
    }
    func renderUi() {
        tapOnScreen = UITapGestureRecognizer.init(target: self, action: #selector(addPhoto))
        view.addGestureRecognizer(tapOnScreen)
    }
    @objc func addPhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        present(imagePicker, animated: true) {

        }
    }
    @objc func handleGesture(with gesture:UIGestureRecognizer) {
        guard let touchedView = gesture.view else {return}
        switch gesture.state {
        case .began:
            if (activeRecognizers.count == 0) {

                if let _ = (gesture as? UIPinchGestureRecognizer) {
                    touchedView.transform = CGAffineTransform(scaleX: lastScale, y: lastScale)
                    activeRecognizers.insert(gesture)
                    return
                }
                if let _ = (gesture as? UIRotationGestureRecognizer)  {
                    touchedView.transform = CGAffineTransform(rotationAngle: lastRotation)
                    activeRecognizers.insert(gesture)
                    return
                }
            }
        case .changed:
            for item in activeRecognizers {
                switch item {
                case is UIPinchGestureRecognizer:
                    if let pinch = (item as? UIPinchGestureRecognizer) {
                        let originalScale = CGFloat.init()
                        let newScale = pinch.scale + originalScale
                        touchedView.transform =  CGAffineTransform(scaleX: newScale, y: newScale)
                    }
                case is UIRotationGestureRecognizer:
                    if let rotate = (item as? UIRotationGestureRecognizer) {
                        let originalRotation = CGFloat.init()
                        let newRotation = rotate.rotation + originalRotation
                        touchedView.transform =  CGAffineTransform(rotationAngle: newRotation)
                    }
                default:
                    break
                }
            }
        case .ended:
            if let pinch = (gesture as? UIPinchGestureRecognizer) {
                lastScale = pinch.scale
                activeRecognizers.remove(gesture)
                return
            }
            if let rotate = (gesture as? UIRotationGestureRecognizer)  {
                activeRecognizers.remove(gesture)
               lastRotation = rotate.rotation
                return
            }
        default:
            break
        }
    }
    func applyRecognizer(_ gesture:UIGestureRecognizer) -> CGAffineTransform {
        if let pinch = (gesture as? UIPinchGestureRecognizer) {
            let originalScale = CGFloat.init()
            let newScale = pinch.scale + originalScale
            return CGAffineTransform(rotationAngle: newScale)
        }
        if let rotate = (gesture as? UIRotationGestureRecognizer)  {
            let originalRotation = CGFloat.init()
            let newRotation = rotate.rotation + originalRotation
            return CGAffineTransform(rotationAngle: newRotation)
        }
        return CGAffineTransform(scaleX: 0, y: 0)
    }
    @objc func pinchRecognized(_ sender:UIPinchGestureRecognizer) {
        guard sender.view != nil else { return }
        if sender.state == .began || sender.state == .changed {
            sender.view?.transform = sender.view!.transform.scaledBy(x: sender.scale, y: sender.scale)
            sender.scale = 1
        }
    }
    @objc func rotate(_ sender:UIRotationGestureRecognizer) {
        guard sender.view != nil else { return }
        if sender.state == .began || sender.state == .changed {
            sender.view?.transform = sender.view!.transform.rotated(by: sender.rotation)
            sender.rotation = 0
        }
    }
    @objc func pan(_ sender:UIPanGestureRecognizer) {
        guard let touchedView = sender.view else {return}
        let translation = sender.translation(in: self.view)
        touchedView.center = CGPoint(x: touchedView.center.x + translation.x, y: touchedView.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: self.view)
        let dragPoint = sender.location(in: self.view)
        let hitView = self.view.hitTest(dragPoint, with: nil)
        if let didHitTrashCan = hitView?.frame.intersects(trashCan.frame) {
            if didHitTrashCan {
                trashCan.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                UIView.animate(withDuration: 2, animations: {
                    hitView?.alpha = 0.0
                    hitView?.center = self.trashCan.center
                    hitView?.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                }) { (isFinished) in
                    hitView?.removeFromSuperview()
                    self.trashCan.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }
            } else {
                trashCan.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
        }

    }
}

extension ViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {

        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let img = info[.originalImage] as? UIImage else {return}
        let imageView = UIImageView(image: img)
        imageView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        imageView.center = view.center
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageStack.append(imageView)
        imageView.tag = imageStack.count

        addPinchGesture(with: imageView)
        addRotationGesture(with: imageView)
        addPangesture(with: imageView)
        picker.dismiss(animated: true) {
            self.view.addSubview(imageView)
        }
    }
    func addRotationGesture(with image:UIImageView) {
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(rotate(_:)))
        rotate.delegate = self
        image.addGestureRecognizer(rotate)
    }
    func addPinchGesture(with image:UIImageView) {
        let pinch = UIPinchGestureRecognizer(target: self, action:#selector(pinchRecognized(_:)))
        pinch.delegate = self
        image.addGestureRecognizer(pinch)
    }
    func addPangesture(with image:UIImageView) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        panGesture.delegate = self
        image.addGestureRecognizer(panGesture)
    }
}

extension ViewController:UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
