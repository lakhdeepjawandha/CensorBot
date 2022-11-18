//
//  ViewController.swift
//  SpeechRecognizer
//
//  Created by Lakhdeep Jawandha on 17/11/22.
//

import UIKit
import Speech
import AVFoundation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        speachRecognizer()
    }

    func speachRecognizer() {
        let videoUrl = Bundle.main.url(forResource: "video", withExtension: "MOV")

        textUsingSimpleUrl(audioURL: videoUrl!) { [weak self] timeRanges in
            guard let timeRanges = timeRanges else { return }
            
            DispatchQueue.main.async {
                let asset =  self?.makeComposition(url: videoUrl!, muteRanges: timeRanges)
                self?.setupAVplayer(asset: asset!)
            }

        }
    }

    
    func setupAVplayer(asset: AVAsset) {
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        let layer = AVPlayerLayer(player: player)
        layer.backgroundColor = UIColor.orange.cgColor
        layer.frame = self.view.bounds
        self.view.layer.addSublayer(layer)
        player.seek(to: .zero)
        player.play()
        player.volume = 1
    }
    
    
    func textUsingBuffers(audioURL: URL) {
        
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        let request = SFSpeechAudioBufferRecognitionRequest()
        
        // ------ 1
        /*
        let allBuffers = getAllAudioBuffers(url: audioURL)
//        print("allBuffers are :\(allBuffers)")
        print("allBuffers count are :\(allBuffers?.count)")
        allBuffers?.forEach({ buffer in
            request.appendAudioSampleBuffer(buffer)
        })
        */
        
        // ------ 2
        guard let file = try? AVAudioFile(forReading: audioURL) else { return }

        let audioBuffer = AVAudioPCMBuffer.init(pcmFormat: file.processingFormat,
                  frameCapacity: AVAudioFrameCount(file.length))
        request.append(audioBuffer!)


//        var task: SFSpeechRecognitionTask?
        request.shouldReportPartialResults = true

        if (recognizer?.isAvailable)! {
            
            recognizer?.recognitionTask(with: request) { result, error in
                
//                print("speakingRate segments", result?.bestTranscription.speakingRate)
//                print("time stamp segments", result?.bestTranscription.segments.count)
//                print("time stamp", result?.bestTranscription.segments.last?.timestamp)
                guard error == nil else { print("Error: \(error!)"); return }
                guard let result = result else { print("No result!"); return }
//                print(result.bestTranscription.formattedString)
                print(result.transcriptions.last?.formattedString)
                
                
                if result.isFinal {
                    print("Final:",result.bestTranscription.formattedString)
                }
            }
        } else {
            print("Device doesn't support speech recognition")
        }
        
        
    }
    
    
    func textUsingSimpleUrl(audioURL: URL, completion: @escaping ([CMTimeRange]?) -> Void) {
        
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        
//        let request = SFSpeechURLRecognitionRequest

//        let trans = SFTranscription()
        request.shouldReportPartialResults = false
        
        var muteTimeRange = [CMTimeRange]()
        
        if (recognizer?.isAvailable)! {

            recognizer?.recognitionTask(with: request) { result, error in
                
                guard error == nil else { print("Error: \(error!)"); return }
                guard let result = result else { print("No result!"); return }
                print("bestTranscription :",result.bestTranscription)
                print("--------")
                if result.isFinal {

                    result.bestTranscription.segments.forEach { segment in
                        print("segment substring:",segment.substring)
                        print("segment substring Range:",segment.substringRange)
                        print("segment time Stemp:",segment.timestamp)
                        print("segment duration:",segment.duration)
                        if segment.substring.lowercased() == "how" {
                            muteTimeRange.append(CMTimeRange(start: CMTime(seconds: segment.timestamp), duration: CMTime(seconds: segment.duration)))
                        }
                    }
                    completion(muteTimeRange)
                }
            }
        } else {
            print("Device doesn't support speech recognition")
        }
       
    }

    func makeComposition(url:URL, muteRanges: [CMTimeRange]) -> AVAsset {
        
        let asset = AVAsset(url: url)
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return asset
        }
        
        guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
            return asset
        }
        
        let mainComposition = AVMutableComposition()

        // Init video & audio composition track
        let videoCompositionTrack = mainComposition.addMutableTrack(
                withMediaType: AVMediaType.video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        
        var audioCompositionTrack = mainComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                preferredTrackID: Int32(kCMPersistentTrackID_Invalid))

        try? videoCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
        try? audioCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioTrack, at: .zero)
        
        
        let audioAsset = AVAsset(url: Bundle.main.url(forResource: "mute", withExtension: "m4r")!)
        guard let audioTrack = audioAsset.tracks(withMediaType: .audio).first else {
            return asset
        }

        muteRanges.forEach { range in
            audioCompositionTrack?.removeTimeRange(range)
            try? audioCompositionTrack?.insertTimeRange(CMTimeRange(start: CMTime(seconds: 0.1), duration: range.duration), of: audioTrack, at: range.start)
        }
        
        return mainComposition
    }
    
    
    func testing() {
        
//        SFSpeechRecognitionMetadata
//
//        SFTranscription
//
//        SFTranscriptionSegment
//        SFSpeechRecognitionRequest
//        AVSpeechUtterance
        
    }
    
    
    func getAllAudioBuffers(url: URL) -> [CMSampleBuffer]? {
        
        let asset = AVAsset(url: url)
        
        var reader: AVAssetReader? = nil
        do {
            reader = try AVAssetReader(asset: asset)
        } catch {
            return nil
        }
        
        guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
            return nil
        }
        
        var audioReadSettings: [AnyHashable : Any] = [:]
        audioReadSettings[AVFormatIDKey] = NSNumber(value: Int32(kAudioFormatLinearPCM))
        
        let readerOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: audioReadSettings as? [String : Any])
        reader!.add(readerOutput)
        reader!.startReading()
        
        var sample = readerOutput.copyNextSampleBuffer()
        var samples: [CMSampleBuffer] = []

        while sample != nil {
            sample = readerOutput.copyNextSampleBuffer()
            if sample == nil {
                continue
            }
            samples.append(sample!)
        }
        
        return samples
    }
    
}

extension ViewController: SFSpeechRecognizerDelegate, SFSpeechRecognitionTaskDelegate {
    
    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
        
    }

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        
    }

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        
    }

    func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
        
    }

    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        
    }

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        
    }

}

extension CMTime {
    init(seconds: Double) {
        self.init(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    }
}
