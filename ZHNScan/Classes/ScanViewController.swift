//
//  ScanViewController.swift
//  Runner
//
//  Created by 张海南 on 2019/4/3.
//  Copyright © 2019年 The Chromium Authors. All rights reserved.
//

import UIKit
import AVFoundation

private let scanAnimationDuration = 3.0//扫描时长
private let needSound = true //扫描结束是否需要播放声音
private let scanWidth : CGFloat = 300 //扫描框宽度
private let scanHeight : CGFloat = 300 //扫描框高度
private let isRecoScanSize = true //是否仅识别框内
private let scanBoxImagePath = "scanBox" //扫描框图片
private let scanLineImagePath = "QRCode_ScanLine" //扫描线图片
private let soundFilePath = "noticeMusic.caf" //声音文件
private let kThemeWhiteColor             =        #colorLiteral(red: 0.9960784314, green: 1, blue: 1, alpha: 1)
private let kThemeBlueColor              =        #colorLiteral(red: 0.2941176471, green: 0.5333333333, blue: 0.8078431373, alpha: 1)
// 屏幕宽度
private let kScreenH = UIScreen.main.bounds.height
// 屏幕高度
private let kScreenW = UIScreen.main.bounds.width

public class ScanVC: UIViewController {
    
    private var scanPane: UIImageView!///扫描框
    private var flashBtn = OMSButton() // 扫码区域上方闪光灯提示
    private var topTitle = UILabel() // 扫码区域上方提示文字
    private var scanPreviewLayer : AVCaptureVideoPreviewLayer! //预览图层
    private var output : AVCaptureMetadataOutput!
    private var input: AVCaptureDeviceInput!
    private var device: AVCaptureDevice!
    var scanSession: AVCaptureSession?
    typealias ClosureStringToVoid = (String) -> ()
    var scanClosure: ClosureStringToVoid?
    
    lazy var scanLine : UIImageView = {
        let scanLine = UIImageView()
        scanLine.frame = CGRect(x: 0, y: 0, width: scanWidth, height: 3)
        scanLine.image = UIImage(named: scanLineImagePath)
        return scanLine
        
    }()
    
    override public func viewDidLoad(){
        super.viewDidLoad()
        //初始化界面
        self.initView()
        //初始化ScanSession
        setupScanSession()
    }
    
    override public func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        startScan()
    }
    
    //初始化界面
    private func initView()  {
        scanPane = UIImageView()
        scanPane.frame = CGRect(x: 300, y: 100, width: scanWidth, height: scanWidth)
        scanPane.image = UIImage(named: scanBoxImagePath)
        scanPane.isUserInteractionEnabled = true
        self.view.addSubview(scanPane)
        
        scanPane.center = view.center
        //增加约束
        //addConstraint()
        scanPane.addSubview(scanLine)
        
        flashBtn.setTitleColor(kThemeWhiteColor, for: .normal)
        flashBtn.setTitleColor(kThemeBlueColor, for: .selected)
        flashBtn.setTitle("轻触点亮", for: .normal)
        flashBtn.setTitle("轻触熄灭", for: .selected)
        flashBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        flashBtn.setImage(UIImage(named: "icon_scan_illumination_normal"), for: .normal)
        flashBtn.setImage(UIImage(named: "icon_scan_illumination"), for: .selected)
        flashBtn.isSelected = false
        flashBtn.imagePosition = .top
        flashBtn.contentHorizontalAlignment = .center
        flashBtn.space = 0
        flashBtn.imageSize = CGSize(width: 16, height: 30)
        flashBtn.frame = CGRect(x: 0, y: scanPane.bottom - 70, width: 60, height: 60)
        flashBtn.centerX = view.centerX
        flashBtn.addTarget(self, action: #selector(flashBtnAction), for: .touchUpInside)
        view.addSubview(flashBtn)
        
        topTitle.text = "将二维码放入框内，即可自动扫描"
        topTitle.textAlignment = .center
        topTitle.font = UIFont.CustomSuitFont(14)
        topTitle.textColor = UIColor(red: 255.0/255, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        topTitle.frame = CGRect(x: 0, y: scanPane.bottom + 15, width: kScreenW, height: 20)
        view.addSubview(topTitle)
    }
    
    @objc private func flashBtnAction(button: UIButton) {
        button.isSelected = !button.isSelected
        changeTorch()
    }
    
    open func isGetFlash() -> Bool {
        guard let _ = self.device else {
            print("模拟器状态")
            return false
        }
        if (device.hasFlash && device.hasTorch) {
            return true
        }
        return false
    }
    
    /// 闪光灯打开或关闭
    private func changeTorch() {
        if isGetFlash() {
            do {
                try input.device.lockForConfiguration()
                
                var torch = false
                
                if input.device.torchMode == AVCaptureDevice.TorchMode.on {
                    torch = false
                } else if input.device.torchMode == AVCaptureDevice.TorchMode.off {
                    torch = true
                }
                
                input.device.torchMode = torch ? AVCaptureDevice.TorchMode.on : AVCaptureDevice.TorchMode.off
                
                input.device.unlockForConfiguration()
            } catch let error as NSError {
                print("device.lockForConfiguration(): \(error)")
                
            }
        }
    }
    
    //扫描完成回调
    private func qrCodeCallBack(_ codeString: String?) {
        guard let closure = scanClosure else { return }
        closure(codeString ?? "")
        //        self.confirm(title: "扫描结果", message: codeString, controller: self,handler: { (_) in
        //            //继续扫描
        //            self.startScan()
        //        })
    }
    
    private func addConstraint() {
        scanPane.translatesAutoresizingMaskIntoConstraints = false
        //创建约束
        let widthConstraint = NSLayoutConstraint(item: scanPane, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: scanWidth)
        let heightConstraint = NSLayoutConstraint(item: scanPane, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: scanHeight)
        let centerX = NSLayoutConstraint(item: scanPane, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0)
        let centerY = NSLayoutConstraint(item: scanPane, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0)
        //添加多个约束
        view.addConstraints([widthConstraint,heightConstraint,centerX,centerY])
    }
    
    //初始化scanSession
    private func setupScanSession(){
        
        do{
            //设置捕捉设备
            guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
                print("模拟器")
                return
            }
            //let device = AVCaptureDevice.default(for: AVMediaType.video)
            self.device = device
            //设置设备输入输出
            let input = try AVCaptureDeviceInput(device: device)
            self.input = input
            let output = AVCaptureMetadataOutput()
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            self.output = output
            
            //设置会话
            let  scanSession = AVCaptureSession()
            scanSession.canSetSessionPreset(.high)
            
            if scanSession.canAddInput(input){
                scanSession.addInput(input)
            }
            
            if scanSession.canAddOutput(output){
                scanSession.addOutput(output)
            }
            
            //设置扫描类型(二维码和条形码)
            output.metadataObjectTypes = [
                .qr,
                .code39,
                .code128,
                .code39Mod43,
                .ean13,
                .ean8,
                .code93
            ]
            //预览图层
            let scanPreviewLayer = AVCaptureVideoPreviewLayer(session:scanSession)
            scanPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            scanPreviewLayer.frame = view.layer.bounds
            self.scanPreviewLayer = scanPreviewLayer
            
            setLayerOrientationByDeviceOritation()
            
            //保存会话
            self.scanSession = scanSession
            
        }catch{
            //摄像头不可用
            self.confirm(title: "温馨提示", message: "摄像头不可用", controller: self)
            return
        }
        
    }
    
    private func setLayerOrientationByDeviceOritation() {
        if(scanPreviewLayer == nil){
            return
        }
        scanPreviewLayer.frame = view.layer.bounds
        view.layer.insertSublayer(scanPreviewLayer, at: 0)
        let screenOrientation = UIDevice.current.orientation
        if(screenOrientation == .portrait){
            scanPreviewLayer.connection?.videoOrientation = .portrait
        }else if(screenOrientation == .landscapeLeft){
            scanPreviewLayer.connection?.videoOrientation = .landscapeRight
        }else if(screenOrientation == .landscapeRight){
            scanPreviewLayer.connection?.videoOrientation = .landscapeLeft
        }else if(screenOrientation == .portraitUpsideDown){
            scanPreviewLayer.connection?.videoOrientation = .portraitUpsideDown
        }else{
            scanPreviewLayer.connection?.videoOrientation = .landscapeRight
        }
        
        //设置扫描区域
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureInputPortFormatDescriptionDidChange, object: nil, queue: nil, using: { (noti) in
            if(isRecoScanSize){
                self.output.rectOfInterest = self.scanPreviewLayer.metadataOutputRectConverted(fromLayerRect: self.scanPane.frame)
            }else{
                self.output.rectOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
            }
        })
    }
    
    //设备旋转后重新布局
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setLayerOrientationByDeviceOritation()
    }
    
    //开始扫描
    fileprivate func startScan(){
        scanLine.layer.add(scanAnimation(), forKey: "scan")
        guard let scanSession = scanSession else { return }
        if !scanSession.isRunning
        {
            scanSession.startRunning()
        }
    }
    
    //扫描动画
    private func scanAnimation() -> CABasicAnimation{
        
        let startPoint = CGPoint(x: scanLine .center.x  , y: 1)
        let endPoint = CGPoint(x: scanLine.center.x, y: scanHeight - 2)
        
        let translation = CABasicAnimation(keyPath: "position")
        translation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        translation.fromValue = NSValue(cgPoint: startPoint)
        translation.toValue = NSValue(cgPoint: endPoint)
        translation.duration = scanAnimationDuration
        translation.repeatCount = MAXFLOAT
        translation.autoreverses = true
        
        return translation
    }
    
    //MARK: -
    //MARK: Dealloc
    deinit{
        ///移除通知
        NotificationCenter.default.removeObserver(self)
    }
    
}

//MARK: -
//MARK: AVCaptureMetadataOutputObjects Delegate
extension ScanVC : AVCaptureMetadataOutputObjectsDelegate {
    
    //捕捉扫描结果
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        //停止扫描
        self.scanLine.layer.removeAllAnimations()
        self.scanSession!.stopRunning()
        
        //播放声音
        if(needSound){
            self.playAlertSound()
        }
        
        //扫描完成
        if metadataObjects.count > 0 {
            if let resultObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject{
                
                guard let result = resultObj.stringValue else {
                    print("错误呀")
                    return
                }
                
                let isURL = RegexUtil.isValid(link: result)
                
                if isURL {
                    // 1.创建过滤器 -- 苹果没有将这个字符定义为常量
                    let filter: CIFilter = CIFilter(name: "CIQRCodeGenerator")!
                    // 2.过滤器恢复默认设置
                    filter.setDefaults()
                    // 3.给过滤器添加数据(正则表达式/帐号和密码) -- 通过KVC设置过滤器,只能设置NSData类型
                    let data = result.data(using: .utf8)
                    filter.setValue(data, forKeyPath: "inputMessage")
                    // 4.获取输出的二维码
                    let outputImage = filter.outputImage
                    // 5.显示二维码
                    if let op = outputImage {
                        let image = UIImage(ciImage: op)
                        print(image)
                    }
                    
                } else {
                    self.qrCodeCallBack(result)
                }
                
            }
        }
    }
    
    //弹出确认框
    func confirm(title:String?,message:String?,controller:UIViewController,handler: ( (UIAlertAction) -> Swift.Void)? = nil){
        
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let entureAction = UIAlertAction(title: "确定", style: .destructive, handler: handler)
        alertVC.addAction(entureAction)
        controller.present(alertVC, animated: true, completion: nil)
        
    }
    
    //播放声音
    func playAlertSound(){
        guard let soundPath = Bundle.main.path(forResource: soundFilePath, ofType: nil)  else { return }
        guard let soundUrl = NSURL(string: soundPath) else { return }
        var soundID:SystemSoundID = 0
        AudioServicesCreateSystemSoundID(soundUrl, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
}


private extension UIFont {
    
    class func CustomSuitFont(_ size: CGFloat) -> UIFont{
        return UIFont.systemFont(ofSize: UIScreen.chooseWidthByScreenWidth(size - 1, width375: size, width414: size + 1))
    }
}

private extension UIScreen {
    
    class func chooseWidthByScreenWidth(_ width320: CGFloat, width375: CGFloat, width414: CGFloat) -> CGFloat {
        
        switch kScreenW {
        case 320:
            return width320
        case 350:
            return width375
        case 414:
            return width414
        default:
            if kScreenW == 0 {
                return 0
            } else {
                return width320 * kScreenW / 320
            }
        }
    }
    
    class func chooseWidthByScreenHeight(_ height480: CGFloat, height568: CGFloat, height667: CGFloat, height736: CGFloat) -> CGFloat{
        
        switch kScreenH {
        case 480:
            return height480
        case 568:
            return height568
        case 667:
            return height667
        case 736:
            return height736
        default:
            if kScreenH == 0 {
                return 0
            } else {
                return 480 * kScreenH / 480
            }
        }
        
    }
    
}

private struct RegexHelper {
    
    let regex: NSRegularExpression
    
    init(_ pattern: String) throws {
        try regex = NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }
    
    func match(_ input: String) -> Bool {
        let matches = regex.matches(in: input, options: [], range: NSMakeRange(0, input.utf16.count))
        return matches.count > 0
    }
    
}

private class RegexUtil {
    
    /// url正则
    private class func getUrlLinkPattern() -> String {
        return "((http[s]{0,1}|ftp|HTTP[S]|FTP|HTTP)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(((http[s]{0,1}|ftp)://|)((?:(?:25[0-5]|2[0-4]\\d|((1\\d{2})|([1-9]?\\d)))\\.){3}(?:25[0-5]|2[0-4]\\d|((1\\d{2})|([1-9]?\\d))))(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)"
    }
    
    class func isValid(link: String) -> Bool {
        let matcher = try! RegexHelper(getUrlLinkPattern())
        return matcher.match(link)
    }
}
