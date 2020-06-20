//
//  ViewController.swift
//  yolo
//
//  Created by Evergreen Technologies on 6/18/20.
//  Copyright © 2020 Evergreen Technologies. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate  {

    
    @IBOutlet weak var previewView: UIView!
    
    
    var bufferSize : CGSize = .zero
    var rootLayer : CALayer! = nil
    private let session = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label:"VideoDataOutout", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    private var previewLayer :AVCaptureVideoPreviewLayer! = nil
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupAVCapture()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
    
    
    func setupAVCapture()
    {
        var deviceInput : AVCaptureDeviceInput!
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position:.back).devices.first
        
        
        
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        }
        catch
        {
            print("could not create vido input. \(error.localizedDescription)")
        }
        
        session.beginConfiguration()
        session.sessionPreset = .vga640x480
        
        guard session.canAddInput(deviceInput) else {
            print("could not add input video device ")
            return
        }
        
        session.addInput(deviceInput)
        
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
            
        }
        else
        {
            print("could not connect to video output")
            session.commitConfiguration()
            return
        }
        
        let captureConnection = videoDataOutput.connection(with: .video)
        captureConnection?.isEnabled = true
        
        do
        {
            try videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice!.unlockForConfiguration()
            
        }
        catch{
            print(error)
        }
        
        session.commitConfiguration()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        rootLayer = previewView.layer
        previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer)
        
        
        
    }
    
    func startCaptureSession()
    {
        session.startRunning()
    }
    
    func tearDownCapture()
    {
        previewLayer.removeFromSuperlayer()
        previewLayer = nil
    }
    
    
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation
    {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation : CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown :
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft :
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight :
            exifOrientation = .down
        case UIDeviceOrientation.portrait :
            exifOrientation = .up
        default :
            exifOrientation = .up
            
            
        }
        return exifOrientation
        
    }
    
    


}

