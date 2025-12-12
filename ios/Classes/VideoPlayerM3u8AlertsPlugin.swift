import Flutter
import UIKit
import AVFoundation

public class VideoPlayerM3u8AlertsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "video_player_m3u8_alerts", binaryMessenger: registrar.messenger())
    let instance = VideoPlayerM3u8AlertsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "getSegmentDuration":
      guard let args = call.arguments as? [String: Any],
            let segmentUrl = args["segmentUrl"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "segmentUrl is required", details: nil))
        return
      }
      getSegmentDuration(segmentUrl: segmentUrl, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func getSegmentDuration(segmentUrl: String, result: @escaping FlutterResult) {
    // Remove query parameters from URL as they might interfere with AVFoundation
    var cleanUrlString = segmentUrl
    if let queryRange = segmentUrl.range(of: "?") {
      cleanUrlString = String(segmentUrl[..<queryRange.lowerBound])
    }
    
    guard let url = URL(string: cleanUrlString) else {
      result(FlutterError(code: "INVALID_URL", message: "Invalid segment URL: \(segmentUrl)", details: nil))
      return
    }
    
    // Note: AVFoundation on iOS has limitations with direct TS file access.
    // TS (Transport Stream) files are typically meant to be accessed through M3U8 playlists.
    // This may fail with "Cannot Open" errors for individual TS segments.
    let asset = AVURLAsset(url: url, options: [
      AVURLAssetPreferPreciseDurationAndTimingKey: true
    ])
    
    // Load duration asynchronously
    asset.loadValuesAsynchronously(forKeys: ["duration", "tracks"]) {
      var error: NSError?
      let durationStatus = asset.statusOfValue(forKey: "duration", error: &error)
      
      DispatchQueue.main.async {
        if durationStatus == .loaded {
          let duration = asset.duration
          let durationSeconds = CMTimeGetSeconds(duration)
          
          if durationSeconds.isFinite && durationSeconds > 0 {
            result(durationSeconds)
          } else {
            let errorMsg = "Invalid duration: \(durationSeconds) (isFinite: \(durationSeconds.isFinite))"
            result(FlutterError(code: "INVALID_DURATION", message: errorMsg, details: nil))
          }
        } else if durationStatus == .failed {
          // Provide detailed error information
          let errorDescription = error?.localizedDescription ?? "Unknown error"
          let errorCode = error?.code ?? -1
          let errorDomain = error?.domain ?? "Unknown"
          let detailedError = "\(errorDescription) (Code: \(errorCode), Domain: \(errorDomain))"
          result(FlutterError(code: "LOAD_FAILED", message: detailedError, details: nil))
        } else {
          result(FlutterError(code: "LOAD_CANCELLED", message: "Duration loading was cancelled (status: \(durationStatus.rawValue))", details: nil))
        }
      }
    }
  }
}
