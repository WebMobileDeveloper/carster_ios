//
//  DbrManager.swift
//  DynamsoftBarcodeReaderDemo
//
//  Created on 1/15/18.
//  Copyright © 2018 dynamsoft. All rights reserved.
//

import AVFoundation
import CoreMedia
import UIKit
import DynamsoftBarcodeReader

class DbrManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    
    private var m_barcodeReader: BarcodeReader?
    private var m_recognitionCallback : Selector!
    private var m_recognitionReceiver: Any?
    var m_videoCaptureSession: AVCaptureSession = AVCaptureSession()
    

    var captureOutput = AVCaptureVideoDataOutput();
    
    var barcodeFormat: Int = 0
    var startRecognitionDate: Date?
    var isPauseFramesComing = false
    var isCurrentFrameDecodeFinished = false
    var cameraResolution = CGSize.zero
    
    
    init(license: String) {
        super.init()
        //m_videoCaptureSession = nil
        m_barcodeReader = BarcodeReader(license: license)
        isPauseFramesComing = false
        isCurrentFrameDecodeFinished = true
        barcodeFormat = Barcode.unknown()
        startRecognitionDate = nil
        m_recognitionReceiver = nil
        
    }
    convenience override init() {
        self.init(license: "")
    }
    
    func beginVideoSession() {
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInDualCamera, AVCaptureDevice.DeviceType.builtInTelephotoCamera,AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        for device in (deviceDiscoverySession.devices) {
            if(device.position == AVCaptureDevice.Position.back){
                do{
                    let inputDevice = try AVCaptureDeviceInput(device: device)
                    if(m_videoCaptureSession.canAddInput(inputDevice)){
                        m_videoCaptureSession.addInput(inputDevice);
                        if(m_videoCaptureSession.canAddOutput(captureOutput)){
                            captureOutput.alwaysDiscardsLateVideoFrames = true
                            var queue: DispatchQueue
                            queue = DispatchQueue(label: "dbrCameraQueue")
                            captureOutput.setSampleBufferDelegate(self, queue: queue)                            
                            
                            // Enable continuous autofocus and AutoFocusRangeRestriction
                            do {
                                try device.lockForConfiguration()
                                device.focusMode = .continuousAutoFocus
                                device.autoFocusRangeRestriction = .near
                                device.unlockForConfiguration()
                            } catch {
                                print("Fail to set autofocus: \(error)")
                            }
                   
                            captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
                            
                            m_videoCaptureSession.addOutput(captureOutput)
                            
                            if m_videoCaptureSession.canSetSessionPreset(.hd1920x1080) {
                                m_videoCaptureSession.sessionPreset = .hd1920x1080
                                cameraResolution.width = 1920
                                cameraResolution.height = 1080
                            }
                            else if m_videoCaptureSession.canSetSessionPreset(.hd1280x720) {
                                m_videoCaptureSession.sessionPreset = .hd1280x720
                                cameraResolution.width = 1280
                                cameraResolution.height = 720
                            }
                            else if m_videoCaptureSession.canSetSessionPreset(.vga640x480) {
                                m_videoCaptureSession.sessionPreset = .vga640x480
                                cameraResolution.width = 640
                                cameraResolution.height = 480
                            }
                            
                            m_videoCaptureSession.startRunning()
                        }
                    }
                }
                catch{
                    print("exception!");
                }
            }
        }
        
    }
    func getVideoSession() -> AVCaptureSession? {
        return m_videoCaptureSession
    }
    
    func setRecognitionCallback(_ sender: Any, callback: Selector) {
        m_recognitionReceiver = sender
        m_recognitionCallback = callback
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        autoreleasepool {
            if isPauseFramesComing == true || isCurrentFrameDecodeFinished == false {
                return
            }
            isCurrentFrameDecodeFinished = false
            
            
            let imageBuffer: CVImageBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
            
            let pixelFormat: OSType = CVPixelBufferGetPixelFormatType(imageBuffer!)
            if (!(pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange || pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange))
            {
                isCurrentFrameDecodeFinished = true;
                return;
            }
            CVPixelBufferLockBaseAddress(imageBuffer!, .readOnly)
            let numPlanes = Int(CVPixelBufferGetPlaneCount(imageBuffer!))
            let bufferSize = Int(CVPixelBufferGetDataSize(imageBuffer!))
            let imgWidth = Int(CVPixelBufferGetWidthOfPlane(imageBuffer!, 0))
            let imgHeight = Int(CVPixelBufferGetHeightOfPlane(imageBuffer!, 0))
            if numPlanes < 1 {
                isCurrentFrameDecodeFinished = true
                return
            }
            let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer!, 0)
            let bytesToCopy: size_t = CVPixelBufferGetHeightOfPlane(imageBuffer!, 0) * CVPixelBufferGetBytesPerRowOfPlane(imageBuffer!, 0)
            let imageData = malloc(bytesToCopy)
            let copyToAddress = imageData
            memcpy(copyToAddress, baseAddress, bytesToCopy)
            CVPixelBufferUnlockBaseAddress(imageBuffer!, .readOnly)
            let buffer = NSData(bytesNoCopy: imageData!, length: bufferSize, freeWhenDone: true)
            startRecognitionDate = Date()
            // read frame using Dynamsoft Barcode Reader in async manner
            m_barcodeReader?.readSingleAsync(buffer as Data!, width: Int32(imgWidth), height: Int32(imgHeight), barcodeFormat: barcodeFormat, sender: m_recognitionReceiver, onComplete: m_recognitionCallback)
        }
    }

    func getAvailableCamera() -> AVCaptureDevice? {
        let videoDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: .video, position: .back).devices
        var captureDevice: AVCaptureDevice? = nil
        for device: AVCaptureDevice in videoDevices {
            if device.position == .back {
                captureDevice = device
                break
            }
        }
        if captureDevice == nil {
            captureDevice = AVCaptureDevice.default(for: .video)
        }
        return captureDevice
    }
}


extension CVPixelBuffer {
    func copy() -> CVPixelBuffer {
        precondition(CFGetTypeID(self) == CVPixelBufferGetTypeID(), "copy() cannot be called on a non-CVPixelBuffer")
        
        var _copy : CVPixelBuffer?
        CVPixelBufferCreate(
            nil,
            CVPixelBufferGetWidth(self),
            CVPixelBufferGetHeight(self),
            CVPixelBufferGetPixelFormatType(self),
            CVBufferGetAttachments(self, .shouldPropagate) ,
            &_copy)
        
        guard let copy = _copy else { fatalError() }
        
        CVPixelBufferLockBaseAddress(self, .readOnly)
        CVPixelBufferLockBaseAddress(copy, CVPixelBufferLockFlags(rawValue: 0))
        
        for plane in 0..<CVPixelBufferGetPlaneCount(self) {
            let dest = CVPixelBufferGetBaseAddressOfPlane(copy, plane)
            let source = CVPixelBufferGetBaseAddressOfPlane(self, plane)
            let height = CVPixelBufferGetHeightOfPlane(self, plane)
            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(self, plane)
            
            memcpy(dest, source, height * bytesPerRow)
        }
        
        CVPixelBufferUnlockBaseAddress(copy, CVPixelBufferLockFlags(rawValue: 0))
        CVPixelBufferUnlockBaseAddress(self, .readOnly)
        
        return copy
    }
}
