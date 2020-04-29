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
    var videoTracks: [AVMutableCompositionTrack] = []
    
    func addVideo(from url: URL) {
        video.append(AVAsset(url: url))
    }
    
    func addMusic(from url: URL) {
        audio.append(AVAsset(url: url))
    }
    
    func compose(withAnimation: Bool) -> (AVAsset, AVVideoComposition?) {
        let composition = AVMutableComposition()
        var videoComposition: AVMutableVideoComposition? = nil
        
//        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
//            fatalError()
//        }
        
        guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
            fatalError()
        }
        
        func insert(video: AVAsset, at moment: CMTime) -> AVMutableCompositionTrack {
            guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
                fatalError()
            }
            
            try? videoTrack.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video.duration), of: video.tracks(withMediaType: .video)[0], at: moment)
            
            return videoTrack
        }
        
        func insert(audio: AVAsset, at: CMTime) {
            try? audioTrack.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: audio.duration), of: audio.tracks(withMediaType: .audio)[0], at: CMTime.zero)
        }
        
        if !video.isEmpty {
            videoTracks.append(insert(video: video[0], at: CMTime.zero))
            
            for i in 1..<video.count {
                videoTracks.append(insert(video: video[i], at: video[i-1].duration - CMTime(seconds: 2.0, preferredTimescale: 600)))
            }
        }
        
        if !audio.isEmpty {
            insert(audio: audio[0], at: CMTime.zero)
            
            for i in 1..<audio.count {
                insert(audio: audio[i], at: audio[i-1].duration)
            }
        }
        
        // В общем, я устала, но тут какая-то дичь с записью в videoTrack. Получается, что у меня нет доступа к следующему видео, пока не закночу с первым.

        
        if withAnimation && video.count == 2 {
            let videoCompositionInstruction1 = addSmoothTransition(video1: video[0], video2: video[1], preferredTransgorm: videoTracks[0].preferredTransform)
//            let videoCompositionInstruction2 = addScaledAppearance(of: video[2], at: video[0].duration + video[1].duration - CMTime(seconds: 3.0, preferredTimescale: 600))
            videoComposition = AVMutableVideoComposition(propertiesOf: composition)
            videoComposition!.instructions = videoCompositionInstruction1
        }
        
        return (composition, videoComposition)
    }
    
    
    
    func addSmoothTransition(video1: AVAsset, video2: AVAsset, preferredTransgorm: CGAffineTransform) -> [AVMutableVideoCompositionInstruction] {
        let transitionDuration = CMTime(seconds: 2.0, preferredTimescale: 600)
        let transitionTimeRange = CMTimeRange(start: video1.duration - transitionDuration, duration: transitionDuration)
        var videoCompositionInstructions: [AVMutableVideoCompositionInstruction] = []
        
        let firstVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        firstVideoCompositionInstruction.timeRange = CMTimeRange(start: CMTime.zero, duration: video1.duration - transitionDuration)
        
        let firstVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTracks[0])
        firstVideoCompositionLayerInstruction.setTransform(preferredTransgorm, at: CMTime.zero)
        firstVideoCompositionInstruction.layerInstructions = [firstVideoCompositionLayerInstruction]
        
        let intermediateCompositionInstruction = AVMutableVideoCompositionInstruction()
        intermediateCompositionInstruction.timeRange = transitionTimeRange
        
        let layerSize1 = video1.tracks(withMediaType: .video)[0].naturalSize

        let layerInstruction1 = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTracks[0])
        layerInstruction1.setTransform(preferredTransgorm, at: CMTime.zero)
        
//        layerInstruction1.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 0.0, timeRange: transitionTimeRange)
        layerInstruction1.setCropRectangleRamp(fromStartCropRectangle: CGRect(origin: CGPoint(x: 0, y: 0), size: layerSize1), toEndCropRectangle: CGRect(origin: CGPoint(x: layerSize1.width, y: 0), size: layerSize1), timeRange: transitionTimeRange)
        
        let layerInstruction2 = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTracks[1])
//        layerInstruction2.setTransform(preferredTransgorm, at: video1.duration - transitionDuration)

        let layerSize2 = video2.tracks(withMediaType: .video)[0].naturalSize

        layerInstruction2.setCropRectangleRamp(fromStartCropRectangle: CGRect(x: 0, y: 0, width: 0, height: layerSize2.height), toEndCropRectangle: CGRect(origin: CGPoint(x: 0, y: 0), size: layerSize2), timeRange: transitionTimeRange)
//        layerInstruction2.setOpacityRamp(fromStartOpacity: 0.0, toEndOpacity: 1.0, timeRange: transitionTimeRange)
        
        intermediateCompositionInstruction.layerInstructions = [layerInstruction1, layerInstruction2]
        
        let secondVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        secondVideoCompositionInstruction.timeRange = CMTimeRange(start: video1.duration, duration: video2.duration)
        
        let secondVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTracks[1])
        secondVideoCompositionLayerInstruction.setTransform(preferredTransgorm, at: CMTime.zero)
        secondVideoCompositionInstruction.layerInstructions = [secondVideoCompositionLayerInstruction]
        
        videoCompositionInstructions = [firstVideoCompositionInstruction, intermediateCompositionInstruction, secondVideoCompositionInstruction]

        return videoCompositionInstructions
    }
    
    func addScaledAppearance(of video: AVAsset, at moment: CMTime) -> AVMutableVideoCompositionInstruction {
        let transitionDuration = CMTime(seconds: 3.0, preferredTimescale: 600)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: video.tracks[0])
        
        let layerSize = video.tracks(withMediaType: .video)[0].naturalSize.applying(video.preferredTransform)
        
        layerInstruction.setCropRectangleRamp(fromStartCropRectangle: CGRect(x: layerSize.width / 2, y: layerSize.height / 2, width: layerSize.width * 0.001, height: layerSize.height * 0.001), toEndCropRectangle: CGRect(x: 0, y: 0, width: layerSize.width, height: layerSize.height), timeRange: CMTimeRange(start: moment, duration: transitionDuration))
        
        let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
        videoCompositionInstruction.timeRange = CMTimeRange(start: moment, duration: moment + video.duration)
        
        videoCompositionInstruction.layerInstructions.append(layerInstruction)
        
        return videoCompositionInstruction
    }
}
