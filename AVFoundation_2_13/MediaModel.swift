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
    
    func export(asset: (AVAsset, AVVideoComposition?), completion: @escaping (Bool) -> Void) {
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError()
        }
        
        let videoName = UUID().uuidString
        let exportURL = documentsDirectory.appendingPathComponent("\(videoName).mov")
        
        guard let export = AVAssetExportSession(asset: asset.0, presetName: AVAssetExportPresetMediumQuality) else {
            fatalError()
        }
        
        export.videoComposition = asset.1
        export.outputFileType = .mov
        export.outputURL = exportURL
        
        export.exportAsynchronously {
            DispatchQueue.main.async {
                switch export.status {
                case .completed:
                    print("Succsess")
                    break
                default:
                    print("Something went wrong during export.")
                    print(export.error ?? "unknown error")
                    break
                }
            }
        }
    }
    
    func compose(withAnimation: Bool) -> (AVAsset, AVVideoComposition?) {
        let composition = AVMutableComposition()
        var videoComposition: AVMutableVideoComposition? = nil
        var animationDuration = CMTime(seconds: 0, preferredTimescale: 600)
        var audioDuration: CMTime? = nil
        videoTracks = []
        
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
        
        func insert(audio: AVAsset, at moment: CMTime, duration: CMTime) {
            try? audioTrack.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: duration), of: audio.tracks(withMediaType: .audio)[0], at: moment)
        }
        
        if withAnimation {
            animationDuration = CMTime(seconds: 2.0, preferredTimescale: 600)
        }
        
        if !video.isEmpty {
            videoTracks.append(insert(video: video[0], at: CMTime.zero))
            audioDuration = video[0].duration
            
            for i in 1..<video.count {
                if withAnimation {
                    videoTracks.append(insert(video: video[i], at: video[i-1].duration - animationDuration))
                } else {
                    videoTracks.append(insert(video: video[i], at: video[i-1].duration))
                }
                audioDuration = audioDuration! + video[i].duration - animationDuration
            }
        }
        
        if !audio.isEmpty {
            if let audioDuration = audioDuration {
                let audioPart = CMTime(seconds: audioDuration.seconds / Double(audio.count), preferredTimescale: 600)
                insert(audio: audio[0], at: CMTime.zero, duration: audioPart)
                
                for i in 1..<audio.count {
                    insert(audio: audio[i], at: CMTime(seconds: audioPart.seconds * Double(i), preferredTimescale: 600), duration: audioPart)
                }
            } else {
                audioDuration = audio[0].duration
                insert(audio: audio[0], at: CMTime.zero, duration: audioDuration!)
                
                for i in 1..<audio.count {
                    insert(audio: audio[i], at: audio[i-1].duration, duration: audio[i].duration)
                }
            }
        }
        
        if !videoTracks.isEmpty {
            videoComposition = AVMutableVideoComposition(propertiesOf: composition)
        }
        
        if withAnimation && video.count == 3 {
            let videoCompositionInstruction1 = addSmoothTransition(video1: 0, video2: 1, animationDuration: animationDuration)
            let videoCompositionInstruction2 = addScaledAppearance(videoNumber: 2, at: video[0].duration + video[1].duration, animationDuration: animationDuration)
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
