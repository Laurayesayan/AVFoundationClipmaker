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
    private var video: [AVAsset] = []
    private var audio: [AVAsset] = []
    private var videoTracks: [AVMutableCompositionTrack] = []
    
    func addVideo(from url: URL) {
        video.append(AVAsset(url: url))
    }
    
    func addMusic(from url: URL) {
        audio.append(AVAsset(url: url))
    }
    
    func compose(withAnimation: Bool) -> (AVAsset, AVVideoComposition?) {
        let composition = AVMutableComposition()
        var videoComposition: AVMutableVideoComposition? = nil
        var animationDuration = CMTime()
        
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
        
        if withAnimation {
            animationDuration = CMTime(seconds: 2.0, preferredTimescale: 600)
        }
       
        if !video.isEmpty {
            videoTracks.append(insert(video: video[0], at: CMTime.zero))
        
            for i in 1..<video.count {
                videoTracks.append(insert(video: video[i], at: video[i-1].duration - animationDuration))
            }
        }
        
        if !audio.isEmpty {
            insert(audio: audio[0], at: CMTime.zero)
            
            for i in 1..<audio.count {
                insert(audio: audio[i], at: audio[i-1].duration)
            }
        }
        
        if withAnimation && video.count == 3 {
            let videoCompositionInstruction1 = addSmoothTransition(video1: 0, video2: 1, animationDuration: animationDuration)
            let videoCompositionInstruction2 = addScaledAppearance(videoNumber: 2, at: video[0].duration + video[1].duration, animationDuration: animationDuration)
            videoComposition = AVMutableVideoComposition(propertiesOf: composition)
            videoComposition!.instructions = videoCompositionInstruction1
            videoComposition?.instructions.append(videoCompositionInstruction2)
        }
        
        return (composition, videoComposition)
    }
    
    private func addSmoothTransition(video1: Int, video2: Int, animationDuration: CMTime) -> [AVMutableVideoCompositionInstruction] {
        let transitionTimeRange = CMTimeRange(start: video[video1].duration - animationDuration, duration: animationDuration)
        var videoCompositionInstructions: [AVMutableVideoCompositionInstruction] = []
        
        let firstVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        firstVideoCompositionInstruction.timeRange = CMTimeRange(start: CMTime.zero, duration: video[video1].duration - animationDuration)
        
        let firstVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTracks[video1])
        firstVideoCompositionLayerInstruction.setTransform(videoTracks[video1].preferredTransform, at: CMTime.zero)
        firstVideoCompositionInstruction.layerInstructions = [firstVideoCompositionLayerInstruction]
        
        let intermediateCompositionInstruction = AVMutableVideoCompositionInstruction()
        intermediateCompositionInstruction.timeRange = transitionTimeRange
        
        let layerSize1 = video[video1].tracks(withMediaType: .video)[0].naturalSize
        
        let layerInstruction1 = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTracks[video1])
        layerInstruction1.setTransform(videoTracks[video1].preferredTransform, at: CMTime.zero)
        
        layerInstruction1.setCropRectangleRamp(fromStartCropRectangle: CGRect(origin: CGPoint(x: 0, y: 0), size: layerSize1), toEndCropRectangle: CGRect(origin: CGPoint(x: layerSize1.width, y: 0), size: layerSize1), timeRange: transitionTimeRange)
        
        let layerInstruction2 = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTracks[video2])
        layerInstruction2.setTransform(videoTracks[video1].preferredTransform, at: video[video1].duration - animationDuration)
        
        let layerSize2 = video[video2].tracks(withMediaType: .video)[0].naturalSize
        
        layerInstruction2.setCropRectangleRamp(fromStartCropRectangle: CGRect(x: 0, y: 0, width: 0, height: layerSize2.height), toEndCropRectangle: CGRect(origin: CGPoint(x: 0, y: 0), size: layerSize2), timeRange: transitionTimeRange)
        
        intermediateCompositionInstruction.layerInstructions = [layerInstruction1, layerInstruction2]
        
        let secondVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        secondVideoCompositionInstruction.timeRange = CMTimeRange(start: video[video1].duration, duration: video[video2].duration - animationDuration)
        
        let secondVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTracks[video2])
        secondVideoCompositionLayerInstruction.setTransform(videoTracks[video1].preferredTransform, at: CMTime.zero)
        secondVideoCompositionInstruction.layerInstructions = [secondVideoCompositionLayerInstruction]
        
        videoCompositionInstructions = [firstVideoCompositionInstruction, intermediateCompositionInstruction, secondVideoCompositionInstruction]
        
        return videoCompositionInstructions
    }
    
    private func addScaledAppearance(videoNumber: Int, at moment: CMTime, animationDuration: CMTime) -> AVMutableVideoCompositionInstruction {
        let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
        videoCompositionInstruction.timeRange = CMTimeRange(start: moment - animationDuration, duration: video[videoNumber].duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTracks[videoNumber])
        let layerSize = video[videoNumber].tracks(withMediaType: .video)[0].naturalSize
        
        layerInstruction.setCropRectangleRamp(fromStartCropRectangle: CGRect(x: layerSize.width / 2, y: layerSize.height / 2, width: layerSize.width * 0.001, height: layerSize.height * 0.001), toEndCropRectangle: CGRect(x: 0, y: 0, width: layerSize.width, height: layerSize.height), timeRange: CMTimeRange(start: moment - animationDuration, duration: animationDuration))
        
        videoCompositionInstruction.layerInstructions.append(layerInstruction)
        
        return videoCompositionInstruction
    }
}
