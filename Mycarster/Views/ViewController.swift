
import UIKit
import AVFoundation
import DynamsoftBarcodeReader
import Alamofire

class ViewController: UIViewController, UIAlertViewDelegate {
    
    
    private var m_isFlashOn = false
    var cameraPreview: UIView = UIView()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var dbrManager: DbrManager = DbrManager()
    var userName:String = ""
    var password:String = ""
    
    
    @IBOutlet var rectLayerImage: UIImageView!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var detectDescLabel: UILabel!
    
    
    
    @IBAction func onFlashButtonClick(_ sender: Any) {
        m_isFlashOn = m_isFlashOn == true ? false : true
        turnFlash(on: m_isFlashOn)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        //register notification for UIApplicationDidBecomeActiveNotification
        NotificationCenter.default.addObserver(self, selector: #selector(self.didBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        //init DbrManager with Dynamsoft Barcode Reader mobile license
        dbrManager = DbrManager(license: "6440D80E694BD7534AFA04BE1A5A3A9A")
        dbrManager.setRecognitionCallback(self, callback: #selector(self.onReadImageBufferComplete))
        dbrManager.beginVideoSession()
        configInterface()
    }
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func didBecomeActive(_ notification: Notification) {
        if dbrManager.isPauseFramesComing == false {
            self.dbrManager.isCurrentFrameDecodeFinished = true
            turnFlash(on: m_isFlashOn)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Show the navigation bar for current view controller
        self.navigationController?.isNavigationBarHidden = false
        self.navigationItem.setHidesBackButton(true, animated:true);
        self.dbrManager.isCurrentFrameDecodeFinished = true
        dbrManager.isPauseFramesComing = false
        turnFlash(on: m_isFlashOn)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func turnFlash(on: Bool) {
        // validate whether flashlight is available
        
        if NSClassFromString("AVCaptureDevice") != nil {
            let device: AVCaptureDevice? = AVCaptureDevice.default(for: .video)
            if device != nil && (device?.hasTorch)! && (device?.hasFlash)! {
                try? device?.lockForConfiguration()
                if on == true {
                    device?.torchMode = .on
                    device?.flashMode = .on
                    flashButton.setImage(UIImage(named: "flash_on"), for: .normal)
                    flashButton.setTitle(NSLocalizedString("flash-on", comment: "flash on string"), for: .normal)
                }
                else {
                    device?.torchMode = .off
                    device?.flashMode = .off
                    flashButton.setImage(UIImage(named: "flash_off"), for: .normal)
                    flashButton.setTitle(NSLocalizedString("flash-off", comment: "flash off string"), for: .normal)
                }
                device?.unlockForConfiguration()
            }
        }
    }
    
    @IBAction func testfunc(_ sender: Any) {
        var vinNumber:String = "15TFAZ5CN6JX054930aa"
        if vinNumber.count > 17 {
            vinNumber = vinNumber.subString(startIndex: 1, endIndex: 17)
        }
        searchResult(vinNumber: vinNumber)
    }
    
    
    @objc func onReadImageBufferComplete(_ readResult: ReadResult) {
        if readResult.barcodes == nil || dbrManager.isPauseFramesComing == true {
            dbrManager.isCurrentFrameDecodeFinished = true
            return
        }
        
        let barcode = readResult.barcodes[0] as? Barcode
        var vinNumber:String = (barcode?.displayValue)!
        
        
        //var vinNumber:String = "5TFAZ5CN6JX054930"
        if vinNumber.count > 17 {
            if vinNumber.subString(startIndex: 0, endIndex: 0) == "I" {
                vinNumber = vinNumber.subString(startIndex: 1, endIndex: 17)
            }else{
                vinNumber = vinNumber.subString(startIndex: 0, endIndex: 16)
            }
        }
        searchResult(vinNumber: vinNumber)
        
    }
    func searchResult(vinNumber:String) {
        let alert = UIAlertController(title: "Capture completed!", message: "\n VIN NUMBER : \(vinNumber) \n\n Please send this number to search details.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "SEARCH", style: UIAlertActionStyle.default, handler: {(_ action: UIAlertAction) -> Void in
            self.startActivityIndicator()
            
            let parameters = ["vin": vinNumber] as [String : Any]
            
            let url = "https://mycarster.com/webservices/vin-search.php"
            Alamofire.request(
                URL(string: url)!,
                method: .post,
                parameters: parameters)
                .validate()
                .responseJSON { (response) -> Void in
                    self.stopActivityIndicator()
                    guard response.result.isSuccess else {
                        self.showAlert(title: "Connection Failed!", message: "Couldn't connect to server. \n Check your network connection and try again.")
                        self.dbrManager.isCurrentFrameDecodeFinished = true
                        return
                    }
                    
                    guard let value = response.result.value as? [String: Any] else {
                        self.showAlert(title: "Unknown data.", message: "We couldn't find infomations for this VIN NUMBER: \(vinNumber) \n please try again capture.")
                        self.dbrManager.isCurrentFrameDecodeFinished = true
                        return
                    }
                    
                    
                    switch value["status"] as! String{
                    case "200":   //success
                        guard let data = value["search_data"] as? [String:String], let alerts = value["alerts"] as? [String:String]  else{
                            self.showAlert(title: "Unknown data.", message: "We couldn't find infomations for this VIN NUMBER: \(vinNumber) \n please try again capture.")
                            self.dbrManager.isCurrentFrameDecodeFinished = true
                            return
                        }
                        if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "searchResultViewController") as? searchResultViewController {
                            if let navigator = self.navigationController {
                                viewController.items = data
                                viewController.alerts = alerts
                                viewController.vinNumber = vinNumber
                                navigator.pushViewController(viewController, animated: true)
                            }
                        }
                        
                    default:
                        self.showAlert(title: "SEARCH ERROR.", message: "VIN NUMBER: \(vinNumber). \n \(value["error"] as! String) \n please try again capture.")
                        self.dbrManager.isCurrentFrameDecodeFinished = true
                        return
                    }
                    
            }
        }))
        alert.addAction(UIAlertAction(title: "RETRY", style: UIAlertActionStyle.default, handler: {(_ action: UIAlertAction) -> Void in
            print("retry tapped")
            self.dbrManager.isCurrentFrameDecodeFinished = true
        }))
        self.present(alert, animated: true, completion: nil)
    }

    func configInterface() {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        let w: CGFloat = UIScreen.main.bounds.size.width
        let h: CGFloat = UIScreen.main.bounds.size.height
        var mainScreenLandscapeBoundary: CGRect = CGRect.zero
        mainScreenLandscapeBoundary.size.width = min(w, h)
        mainScreenLandscapeBoundary.size.height = max(w, h)
        rectLayerImage.frame = mainScreenLandscapeBoundary
        rectLayerImage.contentMode = .topLeft
        createRectBorderAndAlignControls()
        //init vars and controls
        m_isFlashOn = false
        flashButton.layer.zPosition = 1
        detectDescLabel.layer.zPosition = 1
        flashButton.setTitle(NSLocalizedString("flash-off", comment: "flash off string"), for: .normal)
        //show vedio capture
        let captureSession: AVCaptureSession? = dbrManager.getVideoSession()
        if captureSession == nil {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        //print("\(previewLayer)")
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = mainScreenLandscapeBoundary
        cameraPreview = UIView()
        cameraPreview.layer.addSublayer(previewLayer!)
        view.insertSubview(cameraPreview, at: 0)
    }
    
    
    
    func createRectBorderAndAlignControls() {
        let width: CGFloat = rectLayerImage.bounds.size.width
        let height: CGFloat = rectLayerImage.bounds.size.height
        let widthMargin: CGFloat = width * 0.1
        let heightMargin: CGFloat = (height - width + 2 * widthMargin) / 2
        UIGraphicsBeginImageContext(rectLayerImage.bounds.size)
        let ctx: CGContext? = UIGraphicsGetCurrentContext()
        //1. draw gray rect
        UIColor.black.setFill()
        ctx?.fill([CGRect(origin: .zero, size: CGSize(width: widthMargin, height: height) )])
        ctx?.fill([CGRect(origin: .zero, size: CGSize(width: width, height: heightMargin) )])
        ctx?.fill([CGRect(origin: CGPoint(x:width - widthMargin , y: 0 ) , size: CGSize(width: widthMargin, height: height) )])
        ctx?.fill([CGRect(origin: CGPoint(x:0 , y: height - heightMargin ), size: CGSize(width: width, height: heightMargin) )])
        
        
        //2. draw red line
        var points = [CGPoint](repeating: CGPoint.zero, count: 2)
        UIColor.red.setStroke()
        ctx?.setLineWidth(2.0)
        points[0] = CGPoint(x: widthMargin + 5, y: height / 2)
        points[1] = CGPoint(x: width - widthMargin - 5, y: height / 2)
        
        ctx?.strokeLineSegments(between: points)
        //3. draw white rect
        UIColor.white.setStroke()
        ctx?.setLineWidth(1.0)
        // draw left side
        points[0] = CGPoint(x: widthMargin, y: heightMargin)
        points[1] = CGPoint(x: widthMargin, y: height - heightMargin)
        ctx?.strokeLineSegments(between: points)
        // draw right side
        points[0] = CGPoint(x: width -  widthMargin, y: heightMargin)
        points[1] = CGPoint(x: width - widthMargin, y: height -  heightMargin)
        
        ctx?.strokeLineSegments(between: points)
        // draw top side
        points[0] = CGPoint(x: widthMargin, y: heightMargin)
        points[1] = CGPoint(x: width - widthMargin, y: heightMargin)
        ctx?.strokeLineSegments(between: points)
        // draw bottom side
        points[0] = CGPoint(x: widthMargin, y: height - heightMargin)
        points[1] = CGPoint(x: width - widthMargin, y: height -  heightMargin)
        ctx?.strokeLineSegments(between: points)
        
        //4. draw orange corners
        UIColor.orange.setStroke()
        ctx?.setLineWidth(2.0)
        
        // draw left up corner
        points[0] = CGPoint(x: widthMargin - 2, y: heightMargin - 2)
        points[1] = CGPoint(x: widthMargin + 18, y: heightMargin - 2)
        ctx?.strokeLineSegments(between: points)
        points[0] = CGPoint(x: widthMargin - 2, y: heightMargin - 2)
        points[1] = CGPoint(x: widthMargin - 2, y: heightMargin + 18)
        ctx?.strokeLineSegments(between: points)
        
        // draw left bottom corner
        points[0] = CGPoint(x: widthMargin - 2, y: height - heightMargin + 2)
        points[1] = CGPoint(x: widthMargin + 18, y: height - heightMargin + 2)
        ctx?.strokeLineSegments(between: points)
        
        points[0] = CGPoint(x: widthMargin - 2, y: height - heightMargin + 2)
        points[1] = CGPoint(x: widthMargin - 2, y: height - heightMargin - 18)
        ctx?.strokeLineSegments(between: points)
        
        
        // draw right up corner
        
        points[0] = CGPoint(x: width - widthMargin + 2, y: heightMargin - 2)
        points[1] = CGPoint(x: width - widthMargin - 18, y: heightMargin - 2)
        ctx?.strokeLineSegments(between: points)
        
        points[0] = CGPoint(x: width - widthMargin + 2, y: heightMargin - 2)
        points[1] = CGPoint(x: width - widthMargin + 2, y: heightMargin + 18)
        ctx?.strokeLineSegments(between: points)
        
        
        // draw right bottom corner
        points[0] = CGPoint(x: width - widthMargin + 2, y: height - heightMargin + 2)
        points[1] = CGPoint(x: width - widthMargin - 18, y: height - heightMargin + 2)
        ctx?.strokeLineSegments(between: points)
        
        
        points[0] = CGPoint(x: width - widthMargin + 2, y: height - heightMargin + 2)
        points[1] = CGPoint(x: width - widthMargin + 2, y: height - heightMargin - 18)
        ctx?.strokeLineSegments(between: points)
        
        
        //5. set image
        rectLayerImage.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        //6. align detectDescLabel horizontal center
        var tempFrame: CGRect = detectDescLabel.frame
        tempFrame.origin.x = (width - detectDescLabel.bounds.size.width) / 2
        tempFrame.origin.y = heightMargin * 0.6
        detectDescLabel.frame = tempFrame
        //7. align flashButton horizontal center
        tempFrame = flashButton.frame
        tempFrame.origin.x = (width - flashButton.bounds.size.width) / 2
        tempFrame.origin.y = (heightMargin + (width - widthMargin * 2) + height) * 0.5 - flashButton.bounds.size.height * 0.5
        flashButton.frame = tempFrame
        return
    }
    func showAlert(title:String, message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(_ action: UIAlertAction) -> Void in }))
        self.present(alert, animated: true, completion: nil)
    }
 
}

