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
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    private var media = MediaModel()
    lazy var musicLibrory = createMusicLibrory()
    private let picker = UIPickerView()

    override func viewDidLoad() {
        super.viewDidLoad()
        playButton.layer.cornerRadius = playButton.frame.width / 2
        addButton.layer.cornerRadius = addButton.frame.width / 2
    }
    
    func play(asset: (AVAsset, AVVideoComposition?)) {
        let playerItem = AVPlayerItem(asset: asset.0)
        if let videoComposition = asset.1 {
            playerItem.videoComposition = videoComposition
        }
        
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
        let videoSourcePicker = UIAlertController()
        let chooseAudio = UIAlertAction(title: "Choose Audio", style: .default) { [unowned self] _ in
            self.presentAudioPicker()
        }
        let chooseVideo = UIAlertAction(title: "Choose Video", style: .default) { [unowned self] _ in
            self.presentVideoPicker(sourceType: .savedPhotosAlbum)
        }
        
        videoSourcePicker.addAction(chooseAudio)
        videoSourcePicker.addAction(chooseVideo)
        videoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(videoSourcePicker, animated: true)
    }
    
    func createMusicLibrory() -> [String] {
        var result = [String]()
        for i in 1...10 {
            result.append("https:www.soundhelix.com/examples/mp3/SoundHelix-Song-\(i).mp3")
        }
        
        return result
    }
    
    @IBAction func playComposition(_ sender: Any) {
        play(asset: media.compose(withAnimation: true))
    }

}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
}

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return musicLibrory.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let url = URL(string: musicLibrory[row]) {
            media.addMusic(from: url)
        }
        
        if picker.selectedRow(inComponent: component) != -1 {
            showSuccess(picker.selectedRow(inComponent: component) + 1)
        }
    }
    
    func showSuccess(_ number: Int) {
        let successAlert = UIAlertController(title: "Done!", message: "Audio_\(number) successfully added", preferredStyle: .alert)
        present(successAlert, animated: true) { [weak self] in
            self!.picker.removeFromSuperview()
            successAlert.dismiss(animated: true, completion: nil)
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "Audio_\(row + 1)"
    }
    
    func presentAudioPicker() {
        picker.frame = CGRect(x: 0.0, y: self.view.frame.height - self.view.frame.height / 5, width: self.view.frame.width, height: self.view.frame.height / 5)
        picker.alpha = 1.0
        picker.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        picker.layer.cornerRadius = 12
        picker.delegate = self
        picker.dataSource = self
        picker.isHidden = false

        self.view.addSubview(picker)
    }
}
