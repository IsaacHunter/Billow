//
//  CanvasViewController.swift
//  Canvas
//
//  Created by Brian Advent on 01.12.17.
//  Copyright © 2017 Brian Advent. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CanvasViewController: UIViewController {

    @IBOutlet var siblingSketchView: UIImageView!
    @IBOutlet var launchView: UIView!
    @IBOutlet weak var canvasView: CanvasView!
    @IBOutlet var spinner: UIActivityIndicatorView!
    @IBOutlet var bgView: UIImageView!
    @IBOutlet var triangleConstraint: NSLayoutConstraint!
    @IBOutlet var sliderConstraint: NSLayoutConstraint!
    @IBOutlet var progress: UIProgressView!
    @IBOutlet var whiteBtn: UIButton!
    @IBOutlet var blackBtn: UIButton!
    @IBOutlet var redBtn: UIButton!
    @IBOutlet var greenBtn: UIButton!
    @IBOutlet var goldBtn: UIButton!
    @IBOutlet var eraseBtn: UIButton!
    @IBOutlet var colorBtn: UIButton!
    let red:UIColor = UIColor(red: 0.6588, green: 0.0667, blue: 0.0667, alpha: 1)
    let green:UIColor = UIColor(red: 0.0549, green: 0.4588, blue: 0.0549, alpha: 1)
    let gold:UIColor = UIColor(red: 0.9098, green: 0.7294, blue: 0.2117, alpha: 1)
    let eraser:UIColor = UIColor(red: 0.549019608, green: 0.211764706, blue: 0.909803922, alpha: 1)
    var savedColor:UIColor = UIColor.white
    var erase:Bool = false
    
    @IBOutlet var colorsViewConstraint: NSLayoutConstraint!
    @IBOutlet var colorBtnContraint: NSLayoutConstraint!
    @IBOutlet var timelineStack: UIView!
    @IBOutlet var timelineSliderConstraint: NSLayoutConstraint!
    
    private let filter = ChromaKeyFilter()
    
    @IBAction func sliderDown(_ sender: Any) {
        triangleConstraint.constant = 15
        sliderConstraint.constant = -120
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func sliderUp(_ sender: UISlider) {
        triangleConstraint.constant = -15
        sliderConstraint.constant = -150
        canvasView.lineWidth = CGFloat(sender.value)
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        if (!sliderMaxed && (sender.value == sender.maximumValue || sender.value == sender.minimumValue)) {
            sliderMaxed = true
            self.hapticAlert()
        } else if (sender.value != sender.maximumValue && sender.value != sender.minimumValue) {
            sliderMaxed = false
        }
    }
    
    @IBAction func pressColor(_ sender: UIButton) {
        
        self.hapticAlert()
        if (sender == eraseBtn) {
            canvasView.lineColor = eraser
            sender.setImage(UIImage(named:"erase-down"), for: .normal)
            colorBtn.setImage(UIImage(named:"icon-paint"), for: .normal)
            erase = true
            canvasView.erase = true
        } else {
            whiteBtn.setImage(UIImage(named:"color-white"), for: .normal)
            blackBtn.setImage(UIImage(named:"color-black"), for: .normal)
            redBtn.setImage(UIImage(named:"color-red"), for: .normal)
            greenBtn.setImage(UIImage(named:"color-green"), for: .normal)
            goldBtn.setImage(UIImage(named:"color-gold"), for: .normal)
            eraseBtn.setImage(UIImage(named:"erase"), for: .normal)
            
            switch sender {
            case whiteBtn:
                canvasView.lineColor = UIColor.white
                sender.setImage(UIImage(named:"color-white-selected"), for: .normal)
                savedColor = UIColor.white
                break
            case blackBtn:
                canvasView.lineColor = UIColor.black
                sender.setImage(UIImage(named:"color-black-selected"), for: .normal)
                savedColor = UIColor.black
                break
            case redBtn:
                canvasView.lineColor = red
                sender.setImage(UIImage(named:"color-red-selected"), for: .normal)
                savedColor = red
                break
            case greenBtn:
                canvasView.lineColor = green
                sender.setImage(UIImage(named:"color-green-selected"), for: .normal)
                savedColor = green
                break
            default:
                canvasView.lineColor = gold
                sender.setImage(UIImage(named:"color-gold-selected"), for: .normal)
                savedColor = gold
                break
            }
        }
    }
    
    @IBAction func pressColorBtn(_ sender: UIButton) {
        if (erase) {
            sender.setImage(UIImage(named:"color-menu"), for: .normal)
            eraseBtn.setImage(UIImage(named:"erase"), for: .normal)
            erase = false
            canvasView.erase = false
            canvasView.lineColor = savedColor
        } else {
            if (colorsViewConstraint.constant == 0) {
                colorsViewConstraint.constant = -230;
                colorBtnContraint.constant = 325;
            } else {
                colorsViewConstraint.constant = 0;
                colorBtnContraint.constant = 20;
            }
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    var videoUrl:URL!
    var asset:AVAsset! = nil
    var duration:Float64 = 0.0
    var frames:[UIImage?]!
    var sketches:[[CALayer]?]!
    private var generator:AVAssetImageGenerator!
    var currentFrame:Int!
    var lastFrame:Int!
    var imagePicker = UIImagePickerController()
    let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    var sliderMaxed:Bool = false
    var nextTimer: Timer?
    var prevTimer: Timer?
    
    func getTimelineThumbs() {
        var times:[CMTime] = []
        let track = asset.tracks(withMediaType: AVMediaType.video).first
        if (track != nil) {
            let size = track!.naturalSize.applying(track!.preferredTransform)
            
            let numThumbs = self.timelineStack.frame.width/(abs(size.width)*self.timelineStack.frame.height/abs(size.height));
            
            for i:Int in 0 ..< Int(ceil(numThumbs)) {
                let time:CMTime = CMTimeMakeWithSeconds(Float64(i)*duration/Float64(ceil(numThumbs)), 600);
                times.append(time)
            }
            
            self.generator = AVAssetImageGenerator(asset:asset) // possibly be sitting locally and just be refreshed when importing new footage
            self.generator.appliesPreferredTrackTransform = true
            self.generator.requestedTimeToleranceBefore = kCMTimeZero
            self.generator.requestedTimeToleranceAfter = kCMTimeZero
            
            self.generator.generateCGImagesAsynchronously(forTimes: times as [NSValue]) { (requestedTime, image, actualTime, result, error) in
                DispatchQueue.main.async {
                    let loc = times.firstIndex(of: requestedTime)
                    let image =  UIImage(cgImage: image!)
                    let imageView = UIImageView(image: image)
                    let width = Int(abs(size.width)*self.timelineStack.frame.height/abs(size.height))
                    let height = Int(self.timelineStack.frame.height)
                    imageView.frame = CGRect(x: loc!*width, y: 0, width: width, height: height)
                    self.timelineStack.addSubview(imageView)
                }
            }
        }
    }
    
    func getFrames(aroundIndex: Int) {
        var times:[CMTime] = []
        let maxIndex:Int = Int(duration*10)
        
        // loop through frames 10 before and 10 after index and any frames that are nil, add the time to populate async later
        for i:Int in max(0,aroundIndex-10) ..< min(maxIndex,aroundIndex+10) {
            if (frames[i] == nil) {
                let fromTime = ((3.0*Float64(i))+1)/30.0
                let time:CMTime = CMTimeMakeWithSeconds(fromTime, 600)
                times.append(time)
            }
        }
        
        // this is where we populate nil frames
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
        
        // now remove any frames that are not 20 before index or 20 after index so memory doesn't fill up
        for i:Int in 0 ..< max(0,aroundIndex-20) {
            frames[i] = nil
        }
        for i:Int in min(maxIndex,aroundIndex+20) ..< maxIndex {
            frames[i] = nil
        }
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
        lightImpactFeedbackGenerator.prepare()
        spinner.startAnimating()
        imagePicker.delegate = self
        self.videoUrl = UserDefaults.standard.url(forKey: "videoUrl")
        if (self.videoUrl != nil ) {
            self.asset = AVAsset(url:self.videoUrl)
            if (self.asset.tracks.count > 0) {
                DispatchQueue.main.async {
                    self.initVideo()
                    let decoded  = UserDefaults.standard.object(forKey: "sketches") as! Data?
                    if (decoded != nil) {
                        self.sketches = NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! [[CALayer]?]?
                        
                        UIGraphicsBeginImageContextWithOptions(self.canvasView.frame.size, false, 0)
                        if (self.sketches[1] != nil) {
                            for sketch in self.sketches[1]! {
                                sketch.render(in: UIGraphicsGetCurrentContext()!)
                            }
                        }
                        
                        let temp = UIGraphicsGetImageFromCurrentImageContext()
                        if ((temp) != nil) {
                            self.filter.inputImage = CIImage(image: temp!)!
                            self.siblingSketchView.image = UIImage(ciImage: self.filter.outputImage)
                        }
                        UIGraphicsEndImageContext();
                    }
                }
            } else {
                launchView.isHidden = false
            }
        } else {
            launchView.isHidden = false
        }
    }

    @IBAction func clearCanvas(_ sender: Any) {
        if ((self.sketches) != nil) {
            self.sketches[currentFrame] = canvasView.clearCanvas()
        }
    }
    
    @IBAction func nextDown(_ sender: Any) {
        nextFrame()
        nextTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(nextFrame), userInfo: nil, repeats: true)
    }
    
    @IBAction func nextUp(_ sender: Any) {
        nextTimer?.invalidate()
    }
    
    @objc func nextFrame() {
        if (frames != nil && currentFrame < frames.count - 1) {
            clearCanvas(self)
            
            UIGraphicsBeginImageContextWithOptions(self.canvasView.frame.size, false, 0)
            if (sketches[currentFrame] != nil) {
                for sketch in sketches[currentFrame]! {
                    sketch.render(in: UIGraphicsGetCurrentContext()!)
                }
            }
            let temp = UIGraphicsGetImageFromCurrentImageContext()
            if ((temp) != nil) {
                self.filter.inputImage = CIImage(image: temp!)!
                self.siblingSketchView.image = UIImage(ciImage: self.filter.outputImage)
            }
            UIGraphicsEndImageContext();
            
            lastFrame = currentFrame
            getFrames(aroundIndex: currentFrame + 1)
            showFrame(currentFrame + 1)
        } else {
            nextTimer?.invalidate()
        }
    }
    
    @IBAction func prevDown(_ sender: Any) {
        prevFrame()
        prevTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(prevFrame), userInfo: nil, repeats: true)
    }
    
    @IBAction func prevUp(_ sender: Any) {
        prevTimer?.invalidate()
    }
    
    @objc func prevFrame() {
        if (frames != nil && currentFrame > 0) {
            clearCanvas(self)

            UIGraphicsBeginImageContextWithOptions(self.canvasView.frame.size, false, 0)
            if (sketches[currentFrame] != nil) {
                for sketch in sketches[currentFrame]! {
                    sketch.render(in: UIGraphicsGetCurrentContext()!)
                }
            }
            let temp = UIGraphicsGetImageFromCurrentImageContext()
            if ((temp) != nil) {
                self.filter.inputImage = CIImage(image: temp!)!
                self.siblingSketchView.image = UIImage(ciImage: self.filter.outputImage)
            }
            UIGraphicsEndImageContext();

            lastFrame = currentFrame
            getFrames(aroundIndex: currentFrame - 1)
            showFrame(currentFrame - 1)
        } else {
            prevTimer?.invalidate()
        }
    }
    
    func showFrame(_ i:Int) {
        if (frames[i] != nil) {
            let size:CGSize = frames[i]!.size
            let orientation:UIImageOrientation = frames[i]!.imageOrientation
            
            switch UIDevice.current.orientation{
            case .landscapeLeft:
                if (size.height > size.width) {
                    switch orientation{
                    case UIImageOrientation.up, UIImageOrientation.down:
                        frames[i] = UIImage(cgImage: frames[i]!.cgImage!, scale: 1.0, orientation: UIImageOrientation.left)
                    default:
                        frames[i] = UIImage(cgImage: frames[i]!.cgImage!, scale: 1.0, orientation: UIImageOrientation.up)
                    }
                }
            case .landscapeRight:
                if (size.height > size.width) {
                    switch orientation{
                    case UIImageOrientation.up, UIImageOrientation.down:
                        frames[i] = UIImage(cgImage: frames[i]!.cgImage!, scale: 1.0, orientation: UIImageOrientation.right)
                    default:
                        frames[i] = UIImage(cgImage: frames[i]!.cgImage!, scale: 1.0, orientation: UIImageOrientation.up)
                    }
                }
            default:
                if (size.width > size.height) {
                    switch orientation{
                    case UIImageOrientation.up, UIImageOrientation.down:
                        frames[i] = UIImage(cgImage: frames[i]!.cgImage!, scale: 1.0, orientation: UIImageOrientation.right)
                    default:
                        frames[i] = UIImage(cgImage: frames[i]!.cgImage!, scale: 1.0, orientation: UIImageOrientation.up)
                    }
                }
            }
        }
        
        bgView.image = frames[i]
        if (sketches[i] != nil) {
            for sketch in sketches[i]! {
                canvasView.otherLayer.addSublayer(sketch)
            }
        }
        currentFrame = i
        DispatchQueue.main.async {
            var userDefaults = UserDefaults.standard
            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: self.sketches)
            userDefaults.set(encodedData, forKey: "sketches")
            userDefaults.synchronize()
        }
        let width = Int(self.timelineStack.frame.width)
        let newSliderConstant = currentFrame*(width-2)/frames.count+5
        self.timelineSliderConstraint.constant = CGFloat(newSliderConstant)
        canvasView.reloadView()
    }
    
    @IBAction func duplicateFrame(_ sender: UIButton) {
        if (lastFrame > -1 && sketches[lastFrame] != nil) {
            for sketch in sketches[lastFrame]! {
                canvasView.otherLayer.addSublayer(sketch)
                canvasView.reloadView()
            }
        }
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
        
//        var videoSize:CGSize = self.canvasView.frame.size
        let videoSize:CGSize = CGSize(width: 750, height: 1334)
        var orientation:UIImageOrientation = UIImageOrientation.up
        if (frames[currentFrame] != nil) {
            orientation = frames[currentFrame]!.imageOrientation
//            if (orientation == UIImageOrientation.left || orientation == UIImageOrientation.right) {
//                videoSize = CGSize(width: videoSize.height, height: videoSize.width)
//            }
        }
        self.writeImagesAsMovie(videoPath: videoOutputUrl, videoSize: videoSize, videoFPS: 30, orientation: orientation)
    }
    
    func writeImagesAsMovie(videoPath: URL, videoSize: CGSize, videoFPS: Int32, orientation: UIImageOrientation) {
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
                    
                    UIGraphicsBeginImageContextWithOptions(CGSize(width: 375, height: 667), false, 0)
//                    let areaSize = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
//                    UIImage(cgImage: image!, scale:1.0, orientation:orientation).draw(in: areaSize)
                    let j = Int(floor(Double(frameCount)/3.0)) // need to change if we're doing something other than 30 + 10
                    if (j < self.sketches.count && self.sketches[j] != nil) {
//                        let transformFloat = 2.87856071964018
                        for sketch in self.sketches[j]! {
                            sketch.render(in: UIGraphicsGetCurrentContext()!)
                        }
                    }
                    let temp = UIGraphicsGetImageFromCurrentImageContext()!
                    self.filter.inputImage = CIImage(image: temp)!
                    var videoFrame:UIImage = UIImage(ciImage: self.filter.outputImage)
                    
                    UIGraphicsEndImageContext()
                    
                    UIGraphicsBeginImageContextWithOptions(videoSize, false, 0)
                    let areaSize = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
                    UIImage(cgImage: image!, scale:1.0, orientation:orientation).draw(in: areaSize)
                    videoFrame.draw(in:areaSize)
                    
                    videoFrame = UIGraphicsGetImageFromCurrentImageContext()!
                    
                    let lastFrameTime = CMTimeMake(Int64(frameCount), videoFPS)
                    let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                    
                    if !self.appendPixelBufferForImageAtURL(image: videoFrame, pixelBufferAdaptor: pixelBufferAdaptor, presentationTime: presentationTime) {
                        print("Error converting images to video: AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer")
                        return
                    }
                    
                    UIGraphicsEndImageContext()
                }
                
                
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
                            
                            if (tracks.count > 0) {
                                let audioStartTime = kCMTimeZero
                                guard let audioAssetTrack = audioAsset.tracks(withMediaType: AVMediaType.audio).first else { return }
                                let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                                try compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, audioAsset.duration), of: audioAssetTrack, at: audioStartTime)
                            }
                            
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
            
            var videoSettings: [String: AnyObject] = [
                AVVideoWidthKey: size.width as AnyObject,
                AVVideoHeightKey: size.height as AnyObject
            ]
            // Define settings for video input
            if #available(iOS 11.0, *) {
                videoSettings = [
                    AVVideoCodecKey: AVVideoCodecType.h264 as AnyObject,
                    AVVideoWidthKey: size.width as AnyObject,
                    AVVideoHeightKey: size.height as AnyObject
                ]
            }
            
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
                
                pixelBufferPointer.deallocate()
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
    
    @IBAction func undo(_ sender: Any) {
        self.canvasView.undo()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initVideo() {
        clearCanvas(self)
        self.canvasView.initHistory()
        self.canvasView.lineColor = UIColor.white
        self.canvasView.lineWidth = 10
        self.canvasView.canDraw = true
        self.launchView.isHidden = true
        self.pressColor(self.whiteBtn)
        self.duration = CMTimeGetSeconds(self.asset.duration)
        let maxIndex:Int = Int(self.duration*10)
        self.frames = [UIImage?](repeating: nil, count: maxIndex)
        self.sketches = [[CALayer]?](repeating: nil, count: maxIndex)
        self.getTimelineThumbs()
        self.getFrames(aroundIndex: 0)
        lastFrame = -1;
        self.showFrame(0)
        self.siblingSketchView.image = nil
    }
    
    func hapticAlert() {
        // Play haptic signal
        if let feedbackSupportLevel = UIDevice.current.value(forKey: "_feedbackSupportLevel") as? Int {
            switch feedbackSupportLevel {
            case 2:
                // 2nd Generation Taptic Engine w/ Haptic Feedback (iPhone 7/7+)
                lightImpactFeedbackGenerator.impactOccurred()
            case 1:
                // 1st Generation Taptic Engine (iPhone 6S/6S+)
                let peek = SystemSoundID(1519)
                AudioServicesPlaySystemSound(peek)
            case 0:
                // No Taptic Engine
                break
            default: break
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil) { (_) in
            UIView.setAnimationsEnabled(true)
        }
        UIView.setAnimationsEnabled(false)
        super.viewWillTransition(to: size, with: coordinator)
        showFrame(currentFrame)
    }
}

extension CanvasViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let referenceURL = info[UIImagePickerControllerReferenceURL] as? NSURL {
            let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [referenceURL as URL], options: nil)
            if let phAsset = fetchResult.firstObject as? PHAsset {
                PHImageManager.default().requestAVAsset(forVideo: phAsset, options: PHVideoRequestOptions(), resultHandler: { (asset, audioMix, info) -> Void in
                    if let asset = asset as? AVURLAsset {
                        self.videoUrl = asset.url
                        UserDefaults.standard.set(self.videoUrl, forKey: "videoUrl")
//
//                        // optionally, write the video to the temp directory
//                        let videoPath = NSTemporaryDirectory() + "tmpMovie.MOV"
//                        let videoURL = NSURL(fileURLWithPath: videoPath)
//                        let writeResult = videoData?.write(to: videoURL as URL, atomically: true)
                        
//                        if let writeResult = writeResult, writeResult {
//                            self.videoUrl = videoURL as URL
                        
                        print("success")
                        DispatchQueue.main.async {
                            if (self.videoUrl != nil) {
                                self.asset = AVAsset(url:self.videoUrl)
                                if (self.asset.tracks.count > 0) {
                                    self.initVideo()
                                    self.dismiss(animated: true, completion: nil)
                                } else {
                                    self.launchView.isHidden = false
                                }
                            } else {
                                self.launchView.isHidden = false
                            }
                        }
                    }
                })
            }
        }
    }
}
