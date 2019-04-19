//
//  SecondaryView.swift
//  Co-Working Augmentation
//
//  Created by Sarah Mautsch on 23.03.19.
//  Copyright © 2019 Sarah Mautsch. All rights reserved.
//

import UIKit

class SecondaryView: UIView {
    
    var faceView = AAView()
    var indicator = AAView()
    let blinkingView = AAView()
    let notificationButton = AAButton()
    let bubble = AAView()
    let notificationView = AAView()


    init() {
        super.init(frame: CGRect.zero)
        
        self.clipsToBounds = true
        
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = -12
        self.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().inset(24)
        }
        
        faceView.contentView.backgroundColor = .white
        faceView.cornerRadius = Float.infinity
        
        let button = UIButton()
        button.isUserInteractionEnabled = true
        button.addTarget(self, action: #selector(self.activate(sender:)), for: .touchDown)
        button.addTarget(self, action: #selector(self.invoke(sender:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(self.activate(sender:)), for: .touchDragInside)
        button.addTarget(self, action: #selector(self.activate(sender:)), for: .touchDragEnter)
        button.addTarget(self, action: #selector(self.deactivate(sender:)), for: .touchCancel)
        button.addTarget(self, action: #selector(self.deactivate(sender:)), for: .touchDragExit)
        button.addTarget(self, action: #selector(self.deactivate(sender:)), for: .touchUpOutside)
        button.addTarget(self, action: #selector(self.deactivate(sender:)), for: .touchCancel)


        contentStack.addArrangedSubview(button)
        button.snp.makeConstraints { make in
            make.height.equalTo(120)
            make.width.equalTo(120)
        }
        
        blinkingView.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        
        button.addSubview(blinkingView)
        blinkingView.isUserInteractionEnabled = false
        blinkingView.cornerRadius = Float.infinity
        blinkingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(120)
            make.width.equalTo(120)
        }

        
        
        button.addSubview(faceView)
        faceView.isUserInteractionEnabled = false
        faceView.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
        }
        
        let face = UIImageView()
        face.image = UIImage(named: "face")
        face.tintColor = UIColor.appropriateBlue
        faceView.addSubview(face)
        face.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        faceView.addSubview(indicator)
        indicator.isUserInteractionEnabled = false
        indicator.contentView.backgroundColor = UIColor.orange
        indicator.configureShadow(withColor: .black, radius: 12, andOpacity: 0.24)
        indicator.cornerRadius = Float.infinity
        indicator.contentView.layer.borderColor = UIColor.white.cgColor
        indicator.contentView.layer.borderWidth = 3
        indicator.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(32)
            make.height.equalTo(32)
        }
        
        bubble.contentView.backgroundColor = UIColor.white
        bubble.cornerRadius = 18
        bubble.isHidden = true
        bubble.alpha = 0
        contentStack.insertArrangedSubview(bubble, at: 0)
        bubble.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
        
        bubble.configureShadow(withColor: .black, radius: 24, andOpacity: 0.12)
        
        let pointer = UIImageView()
        pointer.image = UIImage(named: "pointer")
        pointer.tintColor = .white
        bubble.addSubview(pointer)
        pointer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(bubble.snp.bottom)
        }
        
        let bubbleStackView = UIStackView()
        bubbleStackView.axis = .vertical
        bubbleStackView.alignment = .center
        bubbleStackView.spacing = 12
        
        bubble.contentView.addSubview(bubbleStackView)
        bubbleStackView.snp.makeConstraints { make in
            let insets = UIEdgeInsets(top: 24, left: 24, bottom: 32, right: 24)
            make.pinAllEdges(withInsets: insets, respectingSafeAreaLayoutGuidesOfView: nil)
        }
        
        let heading = AALabel()
        heading.font = UIFont.ceraFont(ofSize: 18, Weight: .bold)
        heading.lineHeightMultiple = 1.4
        heading.textAlignment = .center
        heading.letterSpacing = 0.5
        heading.numberOfLines = 0
        heading.textColor = UIColor.appropriateBlue
        heading.text = "Want to know when your colleague is available to chat?"
        bubbleStackView.addArrangedSubview(heading)
        
        let subtitleLabel = AALabel()
        subtitleLabel.font = UIFont.ceraFont(ofSize: 16, Weight: .regular)
        subtitleLabel.lineHeightMultiple = 1.5
        subtitleLabel.textAlignment = .center
        subtitleLabel.letterSpacing = 0.4
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textColor = UIColor.appropriateBlue
        subtitleLabel.alpha = 0.75
        subtitleLabel.text = "Your colleague seems to be focussed reading at the moment."
        bubbleStackView.addArrangedSubview(subtitleLabel)
        
        bubbleStackView.insertVerticalSpacerView(ofHeight: 6)
        
        notificationButton.addTarget(self, action: #selector(self.notificationButtonTapped(sender:)), for: .touchUpInside)
        notificationButton.label.text = "Notify me when available"
        notificationButton.label.font = UIFont.ceraFont(ofSize: 16, Weight: .bold)
        notificationButton.contentView.cornerRadius = Float.infinity
        notificationButton.contentView.tintColor = UIColor.appropriateBlue
        notificationButton.contentView.contentView.tintColor = UIColor.appropriateBlue
        notificationButton.iconView.tintColor = UIColor.appropriateBlue
        notificationButton.contentView.contentView.backgroundColor = .clear
        notificationButton.contentView.backgroundMaterial = nil
        notificationButton.contentView.contentView.layer.borderColor = UIColor.appropriateBlue.cgColor
        notificationButton.contentView.contentView.layer.borderWidth = 0.5
        notificationButton.label.uppercased = true
        notificationButton.label.letterSpacing = 0.5
        notificationButton.label.textColor = UIColor.appropriateBlue
        bubbleStackView.addArrangedSubview(notificationButton)
        
        notificationButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        
        
        
        notificationView.isHidden = true
        notificationView.alpha = 0
        notificationView.contentView.backgroundColor = UIColor.white
        notificationView.cornerRadius = 18
        notificationView.configureShadow(withColor: .black, radius: 24, andOpacity: 0.12)
        
        let notificationStack = UIStackView()
        notificationStack.axis = .vertical
        notificationStack.alignment = .center
        notificationStack.spacing = 12
        
        contentStack.addArrangedSubview(notificationView)
        notificationView.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
        
        notificationView.addSubview(notificationStack)
        notificationStack.snp.makeConstraints { make in
            let insets = UIEdgeInsets(top: 24, left: 24, bottom: 32, right: 24)
            make.pinAllEdges(withInsets: insets, respectingSafeAreaLayoutGuidesOfView: nil)
        }
        
        let notificationHeading = AALabel()
        notificationHeading.font = UIFont.ceraFont(ofSize: 18, Weight: .bold)
        notificationHeading.lineHeightMultiple = 1.4
        notificationHeading.textAlignment = .center
        notificationHeading.letterSpacing = 0.5
        notificationHeading.numberOfLines = 0
        notificationHeading.textColor = UIColor.appropriateBlue
        notificationHeading.text = "Ready to chat!"
        notificationStack.addArrangedSubview(notificationHeading)
        
        let notificationSubtitle = AALabel()
        notificationSubtitle.font = UIFont.ceraFont(ofSize: 16, Weight: .regular)
        notificationSubtitle.lineHeightMultiple = 1.5
        notificationSubtitle.textAlignment = .center
        notificationSubtitle.letterSpacing = 0.4
        notificationSubtitle.numberOfLines = 0
        notificationSubtitle.textColor = UIColor.appropriateBlue
        notificationSubtitle.alpha = 0.75
        notificationSubtitle.text = "Your colleague seems to be ready to chat now!"
        notificationStack.addArrangedSubview(notificationSubtitle)

    }
    
    @objc func notificationButtonTapped (sender : AAButton) {
                
        self.notificationButton.label.text = "You will be notified"
        
        ref?.child("isObserving").setValue(true)
        
        sender.configureButton(forConfiguration: .success) {
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { _ in
                UIView.animate(withDuration: 0.3, animations: {
                    self.bubble.isHidden = true
                    self.bubble.alpha = 0
                }, completion: { _ in
                    self.notificationButton.label.text = "Notify me when available"
                    self.notificationButton.configureButton(forConfiguration: .normal, completion: nil)
                })
            })
        }
    }
    
    func showNotification (show : Bool) {
        if show {
            UIView.animate(withDuration: 0.3, animations: {
                self.notificationView.isHidden = false
                self.notificationView.alpha = 1
            }, completion: nil)

        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.notificationView.isHidden = true
                self.notificationView.alpha = 0
            }, completion: nil)

        }
    }
    
    func setStatus (toFocussed focus : Bool) {
        if focus {
            UIView.animate(withDuration: 0.12) {
                self.indicator.contentView.backgroundColor = UIColor.orange
            }
        } else {
            UIView.animate(withDuration: 0.12) {
                self.indicator.contentView.backgroundColor = UIColor.green
            }
        }
    }
    
    @objc func activate (sender : UIButton) {
        UIView.animate(withDuration: 0.1, delay: 0, options: [UIView.AnimationOptions.curveEaseOut], animations: {
            self.faceView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }, completion: nil)

    }
    
    @objc func deactivate (sender : UIButton) {
        UIView.animate(withDuration: 0.1, delay: 0, options: [UIView.AnimationOptions.curveEaseOut], animations: {
            self.faceView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }, completion: nil)
    }

    
    @objc func invoke (sender : UIButton) {
        self.deactivate(sender: sender)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.bubble.isHidden = false
            self.bubble.alpha = 1
        }, completion: nil)

    }
    
    func startAnimation () {
        UIView.animate(withDuration: 3, delay: 0, options: [UIView.AnimationOptions.repeat], animations: {
            
            self.blinkingView.alpha = 0
            
            self.blinkingView.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.height.equalTo(480)
                make.width.equalTo(480)
            }
            
            self.layoutIfNeeded()
            
        }, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
