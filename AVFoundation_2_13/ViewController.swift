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
import MediaPlayer

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
//
//        let url = URL(fileReferenceLiteralResourceName: "https://music.apple.com/ru/album/uno/1502390329?i=1502390336.m4a")
//        let av = try? AVAudioPlayer(contentsOf: url)
//        av?.play()

        let controller = AVPlayerViewController()
        controller.player = player

        present(controller, animated: true) {
            player.play()
        }
    }

    
    @IBAction func addMedia(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentVideoPicker(sourceType: .savedPhotosAlbum)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let chooseAudio = UIAlertAction(title: "Choose Audio", style: .default) { [unowned self] _ in
            self.presentAudioPicker(mediaType: .music)
        }
        let chooseVideo = UIAlertAction(title: "Choose Video", style: .default) { [unowned self] _ in
            self.presentVideoPicker(sourceType: .savedPhotosAlbum)
        }
        
        photoSourcePicker.addAction(chooseAudio)
        photoSourcePicker.addAction(chooseVideo)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true)
        
    }
    
    
    
    @IBAction func play(_ sender: Any) {
        media.addMusic(from: URL(string: "https:www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!)
        play(media: media.compose())
    }

}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, MPMediaPickerControllerDelegate {
    func presentVideoPicker(sourceType: UIImagePickerController.SourceType) {
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
    
    func presentAudioPicker(mediaType: MPMediaType) {
        let mediaPicker = MPMediaPickerController(mediaTypes: mediaType)
        mediaPicker.allowsPickingMultipleItems = false
        mediaPicker.showsCloudItems = false // MPMediaItems stored in the cloud don't have an assetURL
        mediaPicker.delegate = self
        mediaPicker.prompt = "Pick a track"
        present(mediaPicker, animated: true, completion: nil)
    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        guard let item = mediaItemCollection.items.first else {
            print("no item")
            return
        }
        
//        print("picking \(item.title!)")
        guard let url = item.assetURL else {
            return print("no url")
        }

//        let url = Bundle.main.url(forResource: "\(item.persistentID)", withExtension: "m4a")!
        
        media.addMusic(from: url)
        
        dismiss(animated: true, completion: nil)
    }
}


//https:www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3
//https:www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3
//https:www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3
//https:www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3
//https:www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3
//https:www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3
//https:www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3
//https:www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3
//https:www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3
//https:www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3
