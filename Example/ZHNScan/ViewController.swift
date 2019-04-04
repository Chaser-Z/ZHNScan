//
//  ViewController.swift
//  ZHNScan
//
//  Created by Chaser-Z on 04/03/2019.
//  Copyright (c) 2019 Chaser-Z. All rights reserved.
//

import UIKit
import ZHNScan
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let vc = ScanVC()
        self.view.addSubview(vc.view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

