//
//  OMSButton.swift
//  Runner
//
//  Created by 张海南 on 2019/4/3.
//  Copyright © 2019年 The Chromium Authors. All rights reserved.
//

import UIKit

enum OMSButtonImagePosition {
    case left
    case right
    case top
    case bottom
}

class OMSButton: UIButton {
    
    var space: CGFloat = 5 {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    var imagePosition: OMSButtonImagePosition = .left {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    var imageSize: CGSize = .zero {
        didSet {
            self.layoutIfNeeded()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override var isHighlighted: Bool {
        set{
            
        }
        get {
            return false
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.bounds.isEmpty { return }
        
        guard let imageView = imageView,
            let titleLabel = titleLabel
            else { return }
        
        resizeSubviews(titleLabel: titleLabel,imageView: imageView)
        
        switch imagePosition {
        case .left:
            layoutSubviewsForImagePositionLeft(titleLabel: titleLabel, imageView: imageView)
        case .right:
            layoutSubViewsForImagePositionRight(titleLabel: titleLabel, imageView: imageView)
        case .top:
            layoutSubViewsForImagePositionTop(titleLabel: titleLabel, imageView: imageView)
        case .bottom:
            layoutSubViewsForImagePositionBottom(titleLabel: titleLabel, imageView: imageView)
        }
    }
    
    private func resizeSubviews(titleLabel: UILabel,imageView: UIImageView) {
        
        imageView.frame.size = imageSize != .zero ? imageSize : imageView.image?.size ?? .zero
        titleLabel.sizeToFit()
        
        switch imagePosition {
        case .left,.right:
            if titleLabel.width > self.width - space - imageView.width {
                titleLabel.width = self.width
            }
        case .top,.bottom:
            if titleLabel.width > self.width {
                titleLabel.width = self.width
            }
        }
    }
    
    func layoutSubviewsForImagePositionLeft(titleLabel: UILabel,imageView: UIImageView) {
        
        switch self.contentHorizontalAlignment {
        case .right:
            titleLabel.left = self.width - titleLabel.width
            titleLabel.top = (self.height - titleLabel.height) * 0.5
            
            imageView.left = self.width - titleLabel.width - space - imageView.width
            imageView.top = (self.height - imageView.height) * 0.5;
        case .left:
            imageView.left = 0
            imageView.top = (self.height - imageView.height) * 0.5
            
            titleLabel.left = imageView.right + space
            titleLabel.top = (self.height - titleLabel.height) * 0.5
        case .center:
            imageView.left = self.width * 0.5 - (titleLabel.width + space + imageView.width) * 0.5
            imageView.top = (self.height - imageView.height) * 0.5
            
            titleLabel.left = space + imageView.right
            titleLabel.top = (self.height - titleLabel.height) * 0.5
        default: break
        }
    }
    
    func layoutSubViewsForImagePositionRight(titleLabel: UILabel,imageView: UIImageView) {
        
        switch self.contentHorizontalAlignment {
        case .right:
            imageView.left = self.width - imageView.width
            imageView.top = (self.height - imageView.height) * 0.5
            
            titleLabel.left = self.width - imageView.width - space - titleLabel.width
            titleLabel.top = (self.height - titleLabel.height) * 0.5
        case .left:
            titleLabel.left = 0
            titleLabel.top = (self.height - titleLabel.height) * 0.5
            
            imageView.left = space + titleLabel.width
            imageView.top = (self.height - imageView.height) * 0.5
        case .center:
            titleLabel.left = self.width * 0.5 - (titleLabel.width + space + imageView.width) * 0.5
            titleLabel.top = (self.height - titleLabel.height) * 0.5
            imageView.left = titleLabel.left + titleLabel.width + space
            imageView.top = (self.height - imageView.height) * 0.5
        default:break
        }
    }
    
    func layoutSubViewsForImagePositionTop(titleLabel: UILabel,imageView: UIImageView) {
        
        switch self.contentVerticalAlignment {
        case .top:
            imageView.centerX = self.width * 0.5
            imageView.top = 0
            
            titleLabel.top = imageView.bottom + space
            titleLabel.centerX = self.width * 0.5
        case .bottom:
            titleLabel.centerX = self.width * 0.5
            titleLabel.top = self.height - titleLabel.height
            
            imageView.left = space + titleLabel.width
            imageView.top = self.height - (imageView.height + titleLabel.height + space)
        case .center:
            titleLabel.centerX = self.width * 0.5
            titleLabel.top = imageView.bottom + space
            
            imageView.centerX = self.width * 0.5
            imageView.top = (self.height - imageView.height - titleLabel.height - space) * 0.5
        default:break
        }
    }
    
    func layoutSubViewsForImagePositionBottom(titleLabel: UILabel,imageView: UIImageView) {
        
        switch self.contentVerticalAlignment {
        case .top:
            imageView.centerX = self.width * 0.5
            imageView.top = titleLabel.bottom + space
            
            titleLabel.top = 0
            titleLabel.centerX = self.width * 0.5
        case .bottom:
            titleLabel.centerX = self.width * 0.5
            titleLabel.top = self.height - (titleLabel.height + imageView.height + space)
            
            imageView.centerX = self.width * 0.5
            imageView.top = self.height - imageView.height
        case .center:
            titleLabel.centerX = self.width * 0.5
            titleLabel.top = (self.height - imageView.height - titleLabel.height - space) * 0.5
            
            imageView.centerX = self.width * 0.5
            imageView.top = titleLabel.bottom + space
        default:break
        }
    }
}
