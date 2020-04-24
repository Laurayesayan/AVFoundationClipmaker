//
//  ViewController.swift
//  AVFoundation_2_13
//
//  Created by Лаура Есаян on 22.04.2020.
//  Copyright © 2020 LY. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import MobileCoreServices

class ViewController: UIViewController {
    private var media = MediaModel()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func play(media: AVAsset) {
        let playerItem = AVPlayerItem(asset: media)
        let player = AVPlayer(playerItem: playerItem)
//        let playerLayer = AVPlayerLayer(player: player)
//        playerLayer.frame = view.bounds
//        view.layer.addSublayer(playerLayer)
//        player.play()

        let controller = AVPlayerViewController()
        controller.player = player

        present(controller, animated: true) {
            player.play()
        }
    }
    
    @IBAction func addMedia(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .savedPhotosAlbum)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhoto = UIAlertAction(title: "Take Video", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        let choosePhoto = UIAlertAction(title: "Choose Video", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .savedPhotosAlbum)
        }
        
        photoSourcePicker.addAction(takePhoto)
        photoSourcePicker.addAction(choosePhoto)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true)
        
    }
    
    @IBAction func play(_ sender: Any) {
        play(media: media.compose())
    }

}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = sourceType
        pickerController.mediaTypes = [kUTTypeMovie as String]
        present(pickerController, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
            return
        }

        media.addVideo(from: url)

        dismiss(animated: true, completion: nil)
    }
}
