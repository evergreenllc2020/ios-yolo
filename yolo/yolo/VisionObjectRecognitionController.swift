//
//  VisionObjectRecognitionController.swift
//  yolo
//
//  Created by Evergreen Technologies on 6/18/20.
//  Copyright © 2020 Evergreen Technologies. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import Vision

class VisionObjectRecognitionController : ViewController
{
    private var detectionOverlay: CALayer! = nil
    
    private var requests = [VNRequest]()
    
    
    
    override func setupAVCapture()
    {
        super.setupAVCapture()
        setupLayers()
        updateGeometry()
        
        setupVision()
        
        startCaptureSession()
        
    }
    
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)  else { return}
        let exifOrientation = exifOrientationFromDeviceOrientation()
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        
        do
        {
            try imageRequestHandler.perform(self.requests)
            print("invoking model", Date())
        }
        catch{
            print(error)
        }
        
        
        
    }
    
    
    @discardableResult
    func setupVision() -> NSError? {
        let error : NSError! = nil
        
        do
        {
            let visionModel = try VNCoreMLModel(for: YOLOv3().model)
            let objectRecognition = VNCoreMLRequest(model: visionModel) { (request, error) in
                
                DispatchQueue.main.async
                {
                    if let results = request.results {
                        self.drawVisionRequestResults(results)
                    }
                    
                        
                }
                
                
            }
            self.requests = [objectRecognition]
            
        }
        catch{
            print("Model inference gone wrong . \(error)")
        }
        
        
        
        
        
        return error
        
        
        
    }
    
    
    func drawVisionRequestResults(_ results:[Any])
    {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil
        for observation in results where observation is VNRecognizedObjectObservation
        {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {continue}
            let topLabelObservation = objectObservation.labels[0]
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            
            let shapeLayer = self.createRoundRectLayerWithBounds(objectBounds)
            
            let textLayer = self.createTextSubLayerInBounds(objectBounds, identifier: topLabelObservation.identifier, confidence: topLabelObservation.confidence)
            
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
            
            
            
        }
        self.updateGeometry()
        CATransaction.commit()
        
    }
    
    func createTextSubLayerInBounds(_ bounds:CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer
    {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: String(format:"\(identifier)\nConfidence: %.2f", confidence))
        let largeFont = UIFont(name: "Helvetica", size: 24.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range:NSRange(location:0, length:identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x:0, y:0, width: bounds.size.width-10, height: bounds.size.height-10)
        textLayer.position = CGPoint(x:bounds.midX, y: bounds.midX)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        
        let rAngle : CGFloat = .pi / 2.0
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: rAngle).scaledBy(x: 1.0, y: -1.0))
        return textLayer
        
    }
    
    func createRoundRectLayerWithBounds(_ bounds: CGRect) -> CALayer
    {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        return shapeLayer
        
    }
    
    
    
    
    func setupLayers()
    {
        detectionOverlay = CALayer()
        detectionOverlay.name = "DetectionOverLay"
        detectionOverlay.bounds = CGRect(x:0.0, y:0.0, width:bufferSize.width, height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
        
        
    }
    
    func updateGeometry()
    {
        let bounds = rootLayer.bounds
        var scale : CGFloat
        
        let xScale: CGFloat = bounds.size.width/bufferSize.width
        let yScale: CGFloat = bounds.size.height/bufferSize.height
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        
        let rAngle : CGFloat = .pi / 2.0
        
        //rotate the layer and scale it
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: rAngle).scaledBy(x: scale, y: -scale))
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        
        CATransaction.commit()
        
        
        
        
    }
    
    
    
    
    
    
    
    
    
}
