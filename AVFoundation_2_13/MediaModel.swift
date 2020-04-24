//
//  MediaModel.swift
//  AVFoundation_2_13
//
//  Created by Лаура Есаян on 24.04.2020.
//  Copyright © 2020 LY. All rights reserved.
//

import Foundation
import AVFoundation


class MediaModel {
    var video: [AVAsset] = []
    var audio: [AVAsset] = []
    
    func addVideo(from url: URL) {
        video.append(AVAsset(url: url))
    }
    
    func addMusic(from url: URL) {
        audio.append(AVAsset(url: url))
    }
    
    func compose() -> AVAsset {
        let composition = AVMutableComposition()
        
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
            fatalError()
        }
        
        guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
            fatalError()
        }
        
        func insert(video: AVAsset, at moment: CMTime) {
            try? videoTrack.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video.duration), of: video.tracks(withMediaType: .video)[0], at: moment)
        }
        
        func insert(audio: AVAsset, at: CMTime) {
            try? audioTrack.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: audio.duration), of: audio.tracks(withMediaType: .audio)[0], at: CMTime.zero)
        }
        
        if !video.isEmpty {
            insert(video: video[0], at: CMTime.zero)
            
            for i in 1..<video.count {
                insert(video: video[i], at: video[i-1].duration)
            }
        }
        
        if !audio.isEmpty {
            insert(audio: audio[0], at: CMTime.zero)
            
            for i in 1..<audio.count {
                insert(audio: audio[i], at: audio[i-1].duration)
            }
        }
        
        return composition
    }
}
