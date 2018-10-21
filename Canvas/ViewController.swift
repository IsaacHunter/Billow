//
//  ViewController.swift
//  Canvas
//
//  Created by Brian Advent on 01.12.17.
//  Copyright © 2017 Brian Advent. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class ViewController: UIViewController {

    @IBOutlet weak var canvasView: CanvasView!
    @IBOutlet var spinner: UIActivityIndicatorView!
    @IBOutlet var bgView: UIImageView!
    @IBOutlet var triangleConstraint: NSLayoutConstraint!
    @IBOutlet var sliderConstraint: NSLayoutConstraint!
    @IBAction func sliderDown(_ sender: Any) {
        triangleConstraint.constant = 15
        sliderConstraint.constant = -120
    }
    
    @IBAction func sliderUp(_ sender: UISlider) {
        triangleConstraint.constant = -15
        sliderConstraint.constant = -150
        canvasView.lineWidth = CGFloat(sender.value)
    }
    
    @IBOutlet var progress: UIProgressView!
    @IBOutlet var whiteBtn: UIButton!
    @IBOutlet var blackBtn: UIButton!
    @IBOutlet var pinkBtn: UIButton!
    @IBOutlet var blueBtn: UIButton!
    @IBOutlet var eraseBtn: UIButton!
    let pink:UIColor = UIColor(red: 0.9922, green: 0.9297, blue: 0.9375, alpha: 1)
    let blue:UIColor = UIColor(red: 0.8828, green: 0.9609, blue: 0.9570, alpha: 1)
    
    @IBAction func pressColor(_ sender: UIButton) {
        switch canvasView.lineColor {
        case UIColor.white:
            whiteBtn.frame = CGRect(x: whiteBtn.frame.origin.x + 5, y:  whiteBtn.frame.origin.y + 5, width: 30, height: 30)
            break
        case UIColor.black:
            blackBtn.frame = CGRect(x: blackBtn.frame.origin.x + 5, y:  blackBtn.frame.origin.y + 5, width: 30, height: 30)
            break
        case pink:
            pinkBtn.frame = CGRect(x: pinkBtn.frame.origin.x + 5, y:  pinkBtn.frame.origin.y + 5, width: 30, height: 30)
            break
        default:
            blueBtn.frame = CGRect(x: blueBtn.frame.origin.x + 5, y:  blueBtn.frame.origin.y + 5, width: 30, height: 30)
            break
        }
        
        switch sender {
        case whiteBtn:
            canvasView.lineColor = UIColor.white
            whiteBtn.frame = CGRect(x: whiteBtn.frame.origin.x - 5, y:  whiteBtn.frame.origin.y - 5, width: 40, height: 40)
            break
        case blackBtn:
            canvasView.lineColor = UIColor.black
            blackBtn.frame = CGRect(x: blackBtn.frame.origin.x - 5, y:  blackBtn.frame.origin.y - 5, width: 40, height: 40)
            break
        case pinkBtn:
            canvasView.lineColor = pink
            pinkBtn.frame = CGRect(x: pinkBtn.frame.origin.x - 5, y:  pinkBtn.frame.origin.y - 5, width: 40, height: 40)
            break
        default:
            canvasView.lineColor = blue
            blueBtn.frame = CGRect(x: blueBtn.frame.origin.x - 5, y:  blueBtn.frame.origin.y - 5, width: 40, height: 40)
            break
        }
    }
    
    var videoUrl:URL! // use your own url
    var frames:[UIImage?]!
    var sketches:[[CALayer]?]!
    private var generator:AVAssetImageGenerator!
    var currentFrame:Int!
    var imagePicker = UIImagePickerController()
    
    func getFrames(aroundIndex: Int) {
        let asset:AVAsset = AVAsset(url:self.videoUrl) // these should be sitting locally
        let duration:Float64 = CMTimeGetSeconds(asset.duration) // should be sitting locally
        var times:[CMTime] = []
        let maxIndex:Int = Int(duration*10)
        for i:Int in max(0,aroundIndex-10) ..< min(maxIndex,aroundIndex+10) {
            if (frames[i] == nil) {
                let fromTime = ((3.0*Float64(i))+1)/30.0
                let time:CMTime = CMTimeMakeWithSeconds(fromTime, 600)
                times.append(time)
            }
        }
        if (times.count > 0) {
            self.generator = AVAssetImageGenerator(asset:asset) // possibly be sitting locally and just be refreshed when importing new footage
            self.generator.appliesPreferredTrackTransform = true
            self.generator.requestedTimeToleranceBefore = kCMTimeZero
            self.generator.requestedTimeToleranceAfter = kCMTimeZero
            self.generator.generateCGImagesAsynchronously(forTimes: times as [NSValue]) { (requestedTime, image, actualTime, result, error) in
                let h:Int = Int(round(Double(requestedTime.value)*30.0/Double(requestedTime.timescale)))
                let i:Int = Int((h-1)/3)
                self.frames[i] = UIImage(cgImage: image!)
                // reload in case waiting for frame
                if (self.currentFrame == i) {
                    DispatchQueue.main.async {
                        self.showFrame(self.currentFrame)
                    }
                }
            }
        }
    }
    
    func getAllFrames(export: Bool) {
        let asset:AVAsset = AVAsset(url:self.videoUrl)
        let duration:Float64 = CMTimeGetSeconds(asset.duration)
        self.generator = AVAssetImageGenerator(asset:asset)
        self.generator.appliesPreferredTrackTransform = true
        self.generator.requestedTimeToleranceBefore = kCMTimeZero
        self.generator.requestedTimeToleranceAfter = kCMTimeZero
        self.frames = []
        if (export) {
            for index:Int in 0 ..< Int(duration*30) {
                self.getFrame(fromTime:(Float64(index)/30.0))
            }
        } else {
            for index:Int in 0 ..< Int(duration*10) {
                self.getFrame(fromTime:((3.0*Float64(index))+1)/30.0)
            }
        }
        self.generator = nil
    }
    
    private func getFrame(fromTime:Float64) {
        let time:CMTime = CMTimeMakeWithSeconds(fromTime, 600)
        let image:CGImage
        do {
            var actualTime:CMTime = CMTimeMake(0, 0)
            try image = self.generator.copyCGImage(at:time, actualTime:&actualTime)
            print(actualTime)
        } catch {
            return
        }
        self.frames.append(UIImage(cgImage:image))
    }
    
    override func viewDidLoad() {
        spinner.startAnimating()
        canvasView.lineColor = UIColor.white
        canvasView.lineWidth = 10
        self.pressColor(whiteBtn)
        
//        self.videoUrl = Bundle.main.url(forResource: "IMG_0171", withExtension: "MOV")
        
//        let asset:AVAsset = AVAsset(url:self.videoUrl) // these should be sitting locally
//        let duration:Float64 = CMTimeGetSeconds(asset.duration) // should be sitting locally
//        let maxIndex:Int = Int(duration*10)
        
//        self.frames = [UIImage?](repeating: nil, count: maxIndex)
//        self.sketches = [[CALayer]?](repeating: nil, count: maxIndex)
//        getFrames(aroundIndex: 0)
//        showFrame(0)
        imagePicker.delegate = self
    }

    @IBAction func clearCanvas(_ sender: Any) {
        if ((self.sketches) != nil) {
            self.sketches[currentFrame] = canvasView.clearCanvas()
        }
    }
    
    @IBAction func nextFrame(_ sender: Any) {
        if (frames != nil && currentFrame < frames.count - 1) {
            clearCanvas(self)
            getFrames(aroundIndex: currentFrame + 1)
            showFrame(currentFrame + 1)
        }
    }
    
    @IBAction func prevFrame(_ sender: Any) {
        if (frames != nil && currentFrame > 0) {
            clearCanvas(self)
            getFrames(aroundIndex: currentFrame - 1)
            showFrame(currentFrame - 1)
        }
    }
    
    func showFrame(_ i:Int) {
        bgView.image = frames[i]
        if (sketches[i] != nil) {
            for sketch in sketches[i]! {
                canvasView.layer.addSublayer(sketch)
            }
        }
        currentFrame = i
    }
    
    @IBAction func export(_ sender: Any) {
        progress.progress = 0;
        progress.isHidden = false;
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputUrl = URL(fileURLWithPath: documentsPath.appendingPathComponent("videoFile")).appendingPathExtension("mov")
        do {
            if FileManager.default.fileExists(atPath: videoOutputUrl.path) {
                try FileManager.default.removeItem(at: videoOutputUrl)
                print("file removed")
            }
        } catch {
            print(error)
        }
        self.writeImagesAsMovie(videoPath: videoOutputUrl, videoSize: self.canvasView.frame.size, videoFPS: 30)
    }
    
    func writeImagesAsMovie(videoPath: URL, videoSize: CGSize, videoFPS: Int32) {
        let asset:AVAsset = AVAsset(url:self.videoUrl)
        let duration:Float64 = CMTimeGetSeconds(asset.duration)
        self.generator = AVAssetImageGenerator(asset:asset)
        self.generator.appliesPreferredTrackTransform = true
        self.generator.requestedTimeToleranceBefore = kCMTimeZero
        self.generator.requestedTimeToleranceAfter = kCMTimeZero
        let numImages:Int = Int(duration*30)
        var image:CGImage? = nil
        
        // Create AVAssetWriter to write video
        guard let assetWriter = createAssetWriter(path: videoPath, size: videoSize) else {
            print("Error converting images to video: AVAssetWriter not created")
            return
        }
        
        // If here, AVAssetWriter exists so create AVAssetWriterInputPixelBufferAdaptor
        let writerInput = assetWriter.inputs.filter { $0.mediaType == AVMediaType.video }.first!
        let sourceBufferAttributes: [String: AnyObject] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB) as AnyObject,
            kCVPixelBufferWidthKey as String: videoSize.width as AnyObject,
            kCVPixelBufferHeightKey as String: videoSize.height as AnyObject
        ]
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourceBufferAttributes)
        
        // Start writing session
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: kCMTimeZero)
        if pixelBufferAdaptor.pixelBufferPool == nil {
            print("Error converting images to video: pixelBufferPool nil after starting session")
            return
        }
        
        // -- Create queue for <requestMediaDataWhenReadyOnQueue>
        let mediaQueue = DispatchQueue.init(label: "mediaInputQueue")
        
        // -- Set video parameters
        let frameDuration = CMTimeMake(1, videoFPS)
        var frameCount = 0
        
        // -- Add images to video
//        let numImages = allImages.count
        writerInput.requestMediaDataWhenReady(on: mediaQueue, using: { () -> Void in
            // Append unadded images to video but only while input ready
            while writerInput.isReadyForMoreMediaData && frameCount < numImages {
                let fromTime = Float64(frameCount)/30.0
                let time:CMTime = CMTimeMakeWithSeconds(fromTime, 600)
                DispatchQueue.main.async {
                    self.progress.progress = Float(frameCount)/Float(numImages)
                }
                
                autoreleasepool {
                    do {
                        var actualTime:CMTime = CMTimeMake(0, 0)
                        try image = self.generator.copyCGImage(at:time, actualTime:&actualTime)
                        print(actualTime)
                        
                    } catch {
                        return
                    }
                    
                    UIGraphicsBeginImageContextWithOptions(videoSize, false, 0)
                    let areaSize = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
                    UIImage(cgImage: image!).draw(in: areaSize)
                    let j = Int(floor(Double(frameCount)/3.0)) // need to change if we're doing something other than 30 + 10
                    if (j < self.sketches.count && self.sketches[j] != nil) {
                        for sketch in self.sketches[j]! {
                            sketch.render(in: UIGraphicsGetCurrentContext()!)
                        }
                    }
                    let videoFrame:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                    
                    let lastFrameTime = CMTimeMake(Int64(frameCount), videoFPS)
                    let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                    
                    if !self.appendPixelBufferForImageAtURL(image: videoFrame, pixelBufferAdaptor: pixelBufferAdaptor, presentationTime: presentationTime) {
                        print("Error converting images to video: AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer")
                        return
                    }
                }
                
                UIGraphicsEndImageContext()
                
                frameCount += 1
            }
            
            // No more images to add? End video.
            if frameCount >= numImages {
                writerInput.markAsFinished()
                assetWriter.finishWriting {
                    if assetWriter.error != nil {
                        print("Error converting images to video: \(assetWriter.error?.localizedDescription ?? "")")
                    } else {
                        do {
                            let outputVideoFileURL = videoPath
                            let audioAsset = AVURLAsset(url: self.videoUrl)
                            let inputVideoAsset = AVURLAsset(url: outputVideoFileURL)
                            let composition = AVMutableComposition()
                            
                            let tracks = audioAsset.tracks(withMediaType: AVMediaType.audio)
                            
                            guard let videoAssetTrack = inputVideoAsset.tracks(withMediaType: AVMediaType.video).first else { return }
                            let compositionVideoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
                            try compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, inputVideoAsset.duration), of: videoAssetTrack, at: kCMTimeZero)
                            
                            let audioStartTime = kCMTimeZero
                            guard let audioAssetTrack = audioAsset.tracks(withMediaType: AVMediaType.audio).first else { return }
                            let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                            try compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, audioAsset.duration), of: audioAssetTrack, at: audioStartTime)
                            
                            guard let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else { return }
                            assetExport.outputFileType = AVFileType.mov
                            let finalVid = outputVideoFileURL.appendingPathExtension("tmp.mov")
                            do {
                                if FileManager.default.fileExists(atPath: finalVid.path) {
                                    try FileManager.default.removeItem(at: finalVid)
                                    print("file removed")
                                }
                            } catch {
                                print(error)
                            }
                            assetExport.outputURL = finalVid
                            
                            assetExport.exportAsynchronously {
                                self.saveVideoToLibrary(videoURL: finalVid)
                                print("Converted images to movie @ \(videoPath)")
                            }
                        } catch {
                            print("Error adding audio to video: \(assetWriter.error?.localizedDescription ?? "")")
                        }
                    }
                }
            }
        })
    }
    
    // MARK: - Create Asset Writer -
    
    func createAssetWriter(path: URL, size: CGSize) -> AVAssetWriter? {
        // Convert <path> to NSURL object
        let pathURL = path
        
        // Return new asset writer or nil
        do {
            // Create asset writer
            let newWriter = try AVAssetWriter(outputURL: pathURL, fileType: AVFileType.mov)
            
            // Define settings for video input
            let videoSettings: [String: AnyObject] = [
                AVVideoCodecKey: AVVideoCodecType.h264 as AnyObject,
                AVVideoWidthKey: size.width as AnyObject,
                AVVideoHeightKey: size.height as AnyObject
            ]
            
            // Add video input to writer
            let assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
            newWriter.add(assetWriterVideoInput)
            
            // Return writer
            print("Created asset writer for \(size.width)x\(size.height) video")
            return newWriter
        } catch {
            print("Error creating asset writer: \(error)")
            return nil
        }
    }
    
    // MARK: - Append Pixel Buffer -
    
    func appendPixelBufferForImageAtURL(image: UIImage, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor, presentationTime: CMTime) -> Bool {
        var appendSucceeded = false
        
            if  let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool {
                let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)
                let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
                    kCFAllocatorDefault,
                    pixelBufferPool,
                    pixelBufferPointer
                )
                
                if let pixelBuffer = pixelBufferPointer.pointee, status == 0 {
                    fillPixelBufferFromImage(image: image, pixelBuffer: pixelBuffer)
                    appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                    pixelBufferPointer.deinitialize()
                } else {
                    NSLog("Error: Failed to allocate pixel buffer from pool")
                }
                
                pixelBufferPointer.deallocate(capacity: 1)
            }
        
        return appendSucceeded
    }
    
    // MARK: - Fill Pixel Buffer -
    
    func fillPixelBufferFromImage(image: UIImage, pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Create CGBitmapContext
        let context = CGContext(
            data: pixelData,
            width: Int(image.size.width),
            height: Int(image.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )
        
        // Draw image into context"
        context?.draw(image.cgImage!, in: CGRect.init(x: 0, y: 0, width: image.size.width, height: image.size.height))
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    }
    
    // MARK: - Save Video -
    
    func saveVideoToLibrary(videoURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            // Return if unauthorized
            guard status == .authorized else {
                print("Error saving video: unauthorized access")
                return
            }
            
            // If here, save video to library
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }, completionHandler: { success, error in
                DispatchQueue.main.async {
                    self.progress.isHidden = true
                }
                if !success {
                    print("Error saving video: \(error?.localizedDescription ?? "")")
                }
            })
        }
    }
    
    @IBAction func `import`(_ sender: Any) {
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.mediaTypes = ["public.movie"]
        present(imagePicker, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let referenceURL = info[UIImagePickerControllerReferenceURL] as? NSURL {
            let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [referenceURL as URL], options: nil)
            if let phAsset = fetchResult.firstObject as? PHAsset {
                PHImageManager.default().requestAVAsset(forVideo: phAsset, options: PHVideoRequestOptions(), resultHandler: { (asset, audioMix, info) -> Void in
                    if let asset = asset as? AVURLAsset {
                        let videoData = NSData(contentsOf: asset.url)
                        
                        // optionally, write the video to the temp directory
                        let videoPath = NSTemporaryDirectory() + "tmpMovie.MOV"
                        let videoURL = NSURL(fileURLWithPath: videoPath)
                        let writeResult = videoData?.write(to: videoURL as URL, atomically: true)
                        
                        if let writeResult = writeResult, writeResult {
                            self.videoUrl = videoURL as URL
                            print("success")
                            DispatchQueue.main.async {
                                self.canvasView.lineColor = UIColor.white
                                self.canvasView.lineWidth = 10
                                self.canvasView.canDraw = true
                                self.pressColor(self.whiteBtn)
                                
                                let asset:AVAsset = AVAsset(url:self.videoUrl) // these should be sitting locally
                                let duration:Float64 = CMTimeGetSeconds(asset.duration) // should be sitting locally
                                let maxIndex:Int = Int(duration*10)
                                self.frames = [UIImage?](repeating: nil, count: maxIndex)
                                self.sketches = [[CALayer]?](repeating: nil, count: maxIndex)
                                self.getFrames(aroundIndex: 0)
                                self.showFrame(0)
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                        else {
                            print("failure")
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                })
            }
        }
    }
}
