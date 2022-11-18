//
//  Exporter.swift
//  SpeechRecognizer
//
//  Created by Lakhdeep Jawandha on 17/11/22.
//

import AVFoundation
import Photos

class Exporter {
    static let shared = Exporter()
    var exporter: AVAssetExportSession? = nil

    // MARK: GET Unique Output File Url
    private func getUniqueUrl(videoName: String) -> URL {
        let timeStr = NSDate().timeIntervalSince1970
        let filename = videoName + "\(timeStr).mov"
        let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(filename)
        return filePath
    }

    func exportingVideo(asset: AVAsset,
                        videoName: String,
                        progress: @escaping (Int) -> Void,
                        completionBlock: @escaping (AVAssetExportSession?) -> Void) {

        let exportURL = getUniqueUrl(videoName: videoName)
        exporter = AVAssetExportSession.init(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = exportURL
        exporter?.shouldOptimizeForNetworkUse = true
        exporter?.outputFileType = AVFileType.mov

        var progressTimer: Timer?
        DispatchQueue.main.async {
            progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                let percentage: Int = Int(self.exporter!.progress * Float(100.0))
                progress(percentage)
            }
        }
        exporter?.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                progressTimer?.invalidate()
                progressTimer = nil
                completionBlock(self.exporter)
            }
        })
    }
}
