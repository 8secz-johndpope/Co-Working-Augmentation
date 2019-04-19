//
//  ViewController.swift
//  Co-Working Augmentation
//
//  Created by Sarah Mautsch on 20.03.19.
//  Copyright © 2019 Sarah Mautsch. All rights reserved.
//

import UIKit
import GradientView
import SceneKit
import ARKit
import FirebaseDatabase
import SwiftySound

var ref: DatabaseReference?

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, UITextViewDelegate {
    
    var sceneView: ARSCNView!
    
    var faceNode: SCNNode = SCNNode()
    
    let contentContainer = AAView()
    
    var focussed : Bool = false
    
    let headerContainer = AAView()
    
    let focusViewContainer = UIView()
    let focusView = AAView()
    let focusLabel = AALabel()
    let focusIcon = UIImageView()
    let onfocusIcon = UIImageView()
    
    let demoViewContainer = AAView()
    let focusIndicatorEyeCon = UIImageView()
    let focusIndicatorFocusIcon = UIImageView()
    let focusIndicator = AAView()
    let blendGradient = GradientView()
    
    var isObserving : Bool = false


    var eyeLNode: SCNNode = {
        let geometry = SCNCone(topRadius: 0.005, bottomRadius: 0, height: 0.2)
        geometry.radialSegmentCount = 3
        geometry.firstMaterial?.diffuse.contents = UIColor.blue
        let node = SCNNode()
        node.geometry = geometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1
        let parentNode = SCNNode()
        parentNode.addChildNode(node)
        return parentNode
    }()
    
    var eyeRNode: SCNNode = {
        let geometry = SCNCone(topRadius: 0.005, bottomRadius: 0, height: 0.2)
        geometry.radialSegmentCount = 3
        geometry.firstMaterial?.diffuse.contents = UIColor.blue
        let node = SCNNode()
        node.geometry = geometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1
        let parentNode = SCNNode()
        parentNode.addChildNode(node)
        return parentNode
    }()
    
    var lookAtTargetEyeLNode: SCNNode = SCNNode()
    var lookAtTargetEyeRNode: SCNNode = SCNNode()
    
    // actual physical size of iPhoneX screen
    let phoneScreenSize = CGSize(width: 0.0623908297, height: 0.135096943231532)
    
    // actual point size of iPhoneX screen
    let phoneScreenPointSize = CGSize(width: 375, height: 812)
    
    var virtualPhoneNode: SCNNode = SCNNode()
    
    var virtualScreenNode: SCNNode = {
        
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.isDoubleSided = true
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.green
        
        return SCNNode(geometry: screenGeometry)
    }()
    
    var eyeLookAtPositionXs: [CGFloat] = []
    
    var eyeLookAtPositionYs: [CGFloat] = []

    var focusShape = AAView()
    
    
    let switchScrollView = UIScrollView()
    
    let secondaryView = SecondaryView()
    
    let interruptionContainer = AAView()

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        secondaryView.startAnimation()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.3) {
            if scrollView.contentOffset.y <= 0 {

            } else if scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height) {
                self.blendGradient.alpha = 0
            } else {
                self.blendGradient.alpha = 1
                
            }
        }
    }
    
    var observationTimer : Timer?


    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.appropriateBlue
        
        switchScrollView.isPagingEnabled = true
        switchScrollView.showsHorizontalScrollIndicator = false
        switchScrollView.showsVerticalScrollIndicator = false
        self.view.addSubview(switchScrollView)
        switchScrollView.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
        }
        
        let switchStack = UIStackView()
        switchStack.axis = .horizontal
        switchStack.distribution = .fill
        
        switchScrollView.addSubview(switchStack)
        switchStack.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        let mainView = AAView()
        switchStack.addArrangedSubview(mainView)
        
        mainView.snp.makeConstraints { make in
            make.size.equalTo(self.view)
        }
        
        switchStack.addArrangedSubview(secondaryView)
        
        secondaryView.snp.makeConstraints { make in
            make.size.equalTo(self.view)
        }

        ref = Database.database().reference()
        
        
        ref?.child("focussed").observe(.value, with: { (snapshot) in
            if let value = snapshot.value as? Bool {
                DispatchQueue.main.async {
                    if self.switchScrollView.currentPage == 2 {
                        self.secondaryView.setStatus(toFocussed: value)
                    }
                    
                    if self.isObserving {
                        if value == false {
                            
                            if self.observationTimer == nil {
                                self.observationTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { _ in
                                    self.invokeNotification()
                                })
                            }
                            
                        } else {
                            self.observationTimer?.invalidate()
                            self.observationTimer = nil
                        }
                    }
                }
            }
        })
        
        ref?.child("isObserving").setValue(false)
        
        ref?.child("isObserving").observe(.value, with: { (snapshot) in
            if let value = snapshot.value as? Bool {
                self.isObserving = value
                
                if self.isObserving == false {
                    self.secondaryView.showNotification(show: false)
                }
            }
        })

        
        mainView.addSubview(focusViewContainer)
        
        focusViewContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(144)
            make.width.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
        }
        
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
        
        
        focusViewContainer.addSubview(button)
        button.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        focusView.cornerRadius = 10
        focusView.contentView.backgroundColor = .white
        button.addSubview(focusView)
        
        focusView.isUserInteractionEnabled = false
        focusView.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
        }

        
        let focusStack = UIStackView()
        focusStack.axis = .horizontal
        focusStack.alignment = .center
        focusStack.spacing = 10
        
        focusView.contentView.addSubview(focusStack)
        
        focusStack.snp.makeConstraints { make in
            let insets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            make.pinAllEdges(withInsets: insets, respectingSafeAreaLayoutGuidesOfView: nil)
        }
        
        focusLabel.text = "Distracted"
        focusLabel.textColor = UIColor.appropriateBlue
        focusLabel.font = UIFont.ceraFont(ofSize: 16, Weight: .medium)
        focusLabel.letterSpacing = 0.4
        
        let focusIconView = UIView()
        
        focusIcon.image = UIImage(named: "focus-icon")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        focusIcon.tintColor = UIColor.appropriateBlue
        focusIcon.alpha = 0.25
        focusIconView.addSubview(focusIcon)
        focusIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        onfocusIcon.image = UIImage(named: "onfocus-icon")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        onfocusIcon.tintColor = UIColor.appropriateBlue
        onfocusIcon.alpha = 0.25
        focusIconView.addSubview(onfocusIcon)
        onfocusIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        
        focusStack.addArrangedSubview(focusIconView)
        focusStack.addArrangedSubview(focusLabel)
        
        focusIconView.snp.makeConstraints { make in
            make.width.equalTo(24)
            make.height.equalTo(24)
        }
        
        contentContainer.cornerRadius = 24
        contentContainer.contentView.backgroundColor = .white
        mainView.addSubview(contentContainer)
        contentContainer.snp.makeConstraints { make in
            let insets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            make.top.equalTo(focusViewContainer.snp.bottom)
            make.left.equalToSuperview().inset(insets)
            make.right.equalToSuperview().inset(insets)
            make.bottom.equalToSuperview()
        }
        
        headerContainer.backgroundMaterial = UIBlurEffect(style: .light)
        
        let textContainer = AAView()
        textContainer.clipsToBounds = false
        textContainer.layer.masksToBounds = false
        textContainer.backgroundColor = .clear
        
        contentContainer.contentView.addSubview(textContainer)
        
        contentContainer.contentView.addSubview(focusShape)
        focusShape.alpha = 0
        focusShape.isUserInteractionEnabled = false
        focusShape.contentView.backgroundColor = UIColor.appropriateBlue.withAlphaComponent(0.06)
        focusShape.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(120)
            make.centerX.equalToSuperview()
            make.centerY.equalTo(0)
        }
        
        focusIndicator.alpha = 0
        self.focusIndicator.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
        focusIndicator.cornerRadius = 12
        focusIndicator.configureShadow(withColor: .black, radius: 24, andOpacity: 0.12)
        focusIndicator.contentView.backgroundColor = .white
        contentContainer.addSubview(focusIndicator)
        focusIndicator.snp.makeConstraints { make in
            make.width.equalTo(36)
            make.height.equalTo(36)
            make.trailing.equalToSuperview().offset(6)
            make.top.greaterThanOrEqualTo(contentContainer.snp.top).offset(-6).priority(.high)
            make.bottom.lessThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.bottom).priority(.high)
            make.centerY.equalTo(focusShape.snp.centerY).priority(.low)
        }
        
        focusIndicatorFocusIcon.tintColor = UIColor.appropriateBlue
        focusIndicatorFocusIcon.alpha = 0.25
        focusIndicatorFocusIcon.image = UIImage(named: "focus-icon")
        focusIndicator.addSubview(focusIndicatorFocusIcon)
        focusIndicatorFocusIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        focusIndicatorEyeCon.tintColor = UIColor.appropriateBlue
        focusIndicatorEyeCon.alpha = 0.25
        focusIndicatorEyeCon.image = UIImage(named: "onfocus-icon")
        focusIndicator.addSubview(focusIndicatorEyeCon)
        focusIndicatorEyeCon.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        contentContainer.contentView.addSubview(headerContainer)
        
        headerContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        headerContainer.configureShadow(withColor: .black, radius: 24, andOpacity: 0.12)

        
        let titleStackView = UIStackView()
        titleStackView.axis = .vertical
        titleStackView.spacing = 8
        titleStackView.distribution = .fill
        titleStackView.alignment = .leading
        
        headerContainer.contentView.addSubview(titleStackView)
        titleStackView.snp.makeConstraints { make in
            let insets = UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
            make.pinAllEdges(withInsets: insets, respectingSafeAreaLayoutGuidesOfView: nil)
        }
        
        let titleLabel = AALabel()
        titleLabel.text = "Augmenting Human Intellect"
        titleLabel.font = UIFont.ceraFont(ofSize: 16, Weight: .bold)
        titleLabel.textColor = UIColor.appropriateBlue
        
        titleStackView.addArrangedSubview(titleLabel)
        
        let subtitleLabel = AALabel()
        subtitleLabel.text = "by Douglas C. Engelbart"
        subtitleLabel.font = UIFont.ceraFont(ofSize: 16, Weight: .regular)
        subtitleLabel.alpha = 0.5
        subtitleLabel.textColor = UIColor.appropriateBlue
        
        titleStackView.addArrangedSubview(subtitleLabel)
        
        textContainer.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        let textView = UITextView()
        textView.layer.masksToBounds = false
        textView.clipsToBounds = false
        textView.isEditable = false
        textView.delegate = self
        textView.isSelectable = false
        textContainer.contentView.addSubview(textView)
        
        textView.textContainerInset.left = 12
        textView.textContainerInset.right = 12
            
        textView.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
        }
        
        let attributedString = NSMutableAttributedString(string: "By 'augmenting human intellect' we mean increasing the capability of a man to approach a complex problem situation, to gain comprehension to suit his particular needs, and to derive solutions to problems. Increased capability in this respect is taken to mean a mixture of the following: more-rapid comprehension, better comprehension, the possibility of gaining a useful degree of comprehension in a situation that previously was too complex, speedier solutions, better solutions, and the possibility of finding solutions to problems that before seemed insoluble. And by 'complex situations' we include the professional problems of diplomats, executives, social scientists, life scientists, physical scientists, attorneys, designers—whether the problem situation exists for twenty minutes or twenty years. We do not speak of isolated clever tricks that help in particular situations. We refer to a way of life in an integrated domain where hunches, cut-and-try, intangibles, and the human 'feel for a situation' usefully co-exist with powerful concepts, streamlined terminology and notation, sophisticated methods, and high-powered electronic aids. Man's population and gross product are increasing at a considerable rate, but the complexity of his problems grows still faster, and the urgency with which solutions must be found becomes steadily greater in response to the increased rate of activity and the increasingly global nature of that activity. Augmenting man's intellect, in the sense defined above, would warrant full pursuit by an enlightened society if there could be shown a reasonable approach and some plausible benefits. This report covers the first phase of a program aimed at developing means to augment the human intellect. These 'means' can include many things—all of which appear to be but extensions of means developed and used in the past to help man apply his native sensory, mental, and motor capabilities—and we consider the whole system of a human and his augmentation means as a proper field of search for practical possibilities. It is a very important system to our society, and like most systems its performance can best be improved by considering the whole as a set of interacting components rather than by considering the components in isolation. This kind of system approach to human intellectual effectiveness does not find a ready-made conceptual framework such as exists for established disciplines. Before a research program can be designed to pursue such an approach intelligently, so that practical benefits might be derived within a reasonable time while also producing results of longrange significance, a conceptual framework must be searched out—a framework that provides orientation as to the important factors of the system, the relationships among these factors, the types of change among the system factors that offer likely improvements in performance, and the sort of research goals and methodology that seem promising. In the first (search) phase of our program we have developed a conceptual framework that seems satisfactory for the current needs of designing a research phase. Section II contains the essence of this framework as derived from several different ways of looking at the system made up of a human and his intellect-augmentation means. The process of developing this conceptual framework brought out a number of significant realizations: that the intellectual effectiveness exercised today by a given human has little likelihood of being intelligence limited—that there are dozens of disciplines in engineering, mathematics, and the social, life, and physical sciences that can contribute improvements to the system of intellect-augmentation means; that any one such improvement can be expected to trigger a chain of coordinating improvements; that until every one of these disciplines comes to a standstill and we have exhausted all the improvement possibilities we could glean from it, we can expect to continue to develop improvements in this human-intellect system; that there is no particular reason not to expect gains in personal intellectual effectiveness from a concerted system-oriented approach that compare to those made in personal geographic mobility since horseback and sailboat days. The picture of how one can view the possibilities for a systematic approach to increasing human intellectual effectiveness, as put forth in Section II in the sober and general terms of an initial basic analysis, does not seem to convey all of the richness and promise that was stimulated by the development of that picture. Consequently, Section III is intended to present some definite images that illustrate meaningful possibilities deriveable from the conceptual framework presented in Section II—and in a rather marked deviation from ordinary technical writing, a good portion of Section III presents these images in a fiction-dialogue style as a mechanism for transmitting a feeling for the richness and promise of the possibilities in one region of the 'improvement space' that is roughly mapped in Section II. The style of Section III seems to make for easier reading. If Section II begins to seem unrewardingly difficult, the reader may find it helpful to skip from Section II-B directly to Section III. If it serves its purpose well enough, Section III will provide a context within which the reader can go back and finish Section II with less effort. In Section IV (Research Recommendations) we present a general strategy for pursuing research toward increasing human intellectual effectiveness. This strategy evolved directly from the concepts presented in Sections II and III; one of its important precepts is to pursue the quickest gains first, and use the increased intellectual effectiveness thus derived to help pursue successive gains. We see the quickest gains emerging from (1) giving the human the minute-by-minute services of a digital computer equipped with computer-driven cathode-ray-tube display, and (2) developing the new methods of thinking and working that allow the human to capitalize upon the computer's help. By this same strategy, we recommend that an initial research effort develop a prototype system of this sort aimed at increasing human effectiveness in the task of computer programming. To give the reader an initial orientation about what sort of thing this computer-aided working system might be, we include below a short description of a possible system of this sort. This illustrative example is not to be considered a description of the actual system that will emerge from the program. It is given only to show the general direction of the work, and is clothed in fiction only to make it easier to visualize. Let us consider an augmented architect at work. He sits at a working station that has a visual display screen some three feet on a side; this is his working surface, and is controlled by a computer (his 'clerk') with which he can communicate by means of a small keyboard and various other devices. He is designing a building. He has already dreamed up several basic layouts and structural forms, and is trying them out on the screen. The surveying data for the layout he is working on now have already been entered, and he has just coaxed the clerk to show him a perspective view of the steep hillside building site with the roadway above, symbolic representations of the various trees that are to remain on the lot, and the service tie points for the different utilities. The view occupies the left two-thirds of the screen. With a 'pointer,' he indicates two points of interest, moves his left hand rapidly over the keyboard, and the distance and elevation between the points indicated appear on the right-hand third of the screen. Now he enters a reference line with his pointer, and the keyboard. Gradually the screen begins to show the work he is doing—a neat excavation appears in the hillside) revises itself slightly, and revises itself again. After a moment, the architect changes the scene on the screen to an overhead plan view of the site, still showing the excavation. A few minutes of study, and he enters on the keyboard a list of items, checking each one as it appears on the screen, to be studied later. Ignoring the representation on the display, the architect next begins to enter a series of specifications and data—a six-inch slab floor, twelve-inch concrete walls eight feet high within the excavation, and so on. When he has finished, the revised scene appears on the screen. A structure is taking shape. He examines it, adjusts it, pauses long enough to ask for handbook or catalog information from the clerk at various points, and readjusts accordingly. He often recalls from the 'clerk' his working lists of specifications and considerations to refer to them, modify them, or add to them. These lists grow into an evermore-detailed, interlinked structure, which represents the maturing thought behind the actual design. Prescribing different planes here and there, curved surfaces occasionally, and moving the whole structure about five feet, he finally has the rough external form of the building balanced nicely with the setting and he is assured that this form is basically compatible with the materials to be used as well as with the function of the building. Now he begins to enter detailed information about the interior. Here the capability of the clerk to show him any view he wants to examine (a slice of the interior, or how the structure would look from the roadway above) is important. He enters particular fixture designs, and examines them in a particular room. He checks to make sure that sun glare from the windows will not blind a driver on the roadway, and the 'clerk' computes the information that one window will reflect strongly onto the roadway between 6 and 6:30 on midsummer mornings. Next he begins a functional analysis. He has a list of the people who will occupy this building, and the daily sequences of their activities. The 'clerk' allows him to follow each in turn, examining how doors swing, where special lighting might be needed. Finally he has the 'clerk' combine all of these sequences of activity to indicate spots where traffic is heavy in the building, or where congestion might occur, and to determine what the severest drain on the utilities is likely to be. All of this information (the building design and its associated 'thought structure') can be stored on a tape to represent the design manual for the building. Loading this tape into his own clerk, another architect, a builder, or the client can maneuver within this design manual to pursue whatever details or insights are of interest to him—and can append special notes that are integrated into the design manual for his own or someone else's later benefit. In such a future working relationship between human problem-solver and computer 'clerk,' the capability of the computer for executing mathematical processes would be used whenever it was needed. However, the computer has many other capabilities for manipulating and displaying information that can be of significant benefit to the human in nonmathematical processes of planning, organizing, studying, etc. Every person who does his thinking with symbolized concepts (whether in the form of the English language, pictographs, formal logic, or mathematics) should be able to benefit significantly.")
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = CGFloat(1.75)

        attributedString.addAttributes([NSAttributedString.Key.paragraphStyle : paragraphStyle], range: NSMakeRange(0, attributedString.length))

        textView.attributedText = attributedString
        
        textView.font = UIFont.ceraFont(ofSize: 16, Weight: .regular)
        textView.textColor = UIColor.appropriateBlue
        
        blendGradient.isUserInteractionEnabled = false
        contentContainer.contentView.addSubview(blendGradient)
        blendGradient.colors = [UIColor.white.withAlphaComponent(0), UIColor.white.withAlphaComponent(1)]
        blendGradient.direction = .vertical
        blendGradient.backgroundColor = .clear
        blendGradient.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(120)
        }
        
        self.interruptionContainer.alpha = 0
        self.interruptionContainer.backgroundMaterial = nil

        textContainer.contentView.addSubview(interruptionContainer)
        interruptionContainer.snp.makeConstraints { make in
            make.pinAllEdgesToSuperView()
        }
        
        let interruptionNotificationContainer = AAView()
        interruptionContainer.addSubview(interruptionNotificationContainer)
        interruptionNotificationContainer.snp.makeConstraints { make in
            let insets = UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18)
            make.pinAllEdges(withInsets: insets, respectingSafeAreaLayoutGuidesOfView: interruptionContainer)
        }
        
        let interruptionStackView = UIStackView()
        interruptionStackView.axis = .vertical
        interruptionStackView.alignment = .center
        interruptionStackView.spacing = 12
        
        interruptionNotificationContainer.contentView.addSubview(interruptionStackView)
        interruptionStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        let heading = AALabel()
        heading.font = UIFont.ceraFont(ofSize: 18, Weight: .bold)
        heading.lineHeightMultiple = 1.4
        heading.textAlignment = .center
        heading.letterSpacing = 0.5
        heading.numberOfLines = 0
        heading.textColor = UIColor.appropriateBlue
        heading.text = "Time for a little break?"
        interruptionStackView.addArrangedSubview(heading)
        
        let interruptionSubtitle = AALabel()
        interruptionSubtitle.font = UIFont.ceraFont(ofSize: 16, Weight: .regular)
        interruptionSubtitle.lineHeightMultiple = 1.5
        interruptionSubtitle.textAlignment = .center
        interruptionSubtitle.letterSpacing = 0.4
        interruptionSubtitle.numberOfLines = 0
        interruptionSubtitle.textColor = UIColor.appropriateBlue
        interruptionSubtitle.alpha = 0.75
        interruptionSubtitle.text = "Your colleague want’s to chat  with you and you seem not to focus anyways at the moment."
        interruptionStackView.addArrangedSubview(interruptionSubtitle)
        
        interruptionStackView.insertVerticalSpacerView(ofHeight: 6)
        
        let interruptionDismiss = AAButton()
        interruptionDismiss.isUserInteractionEnabled = true
        interruptionDismiss.addTarget(self, action: #selector(self.interruptionDismiss(sender:)), for: .touchUpInside)
        interruptionDismiss.label.text = "Continue reading"
        interruptionDismiss.label.font = UIFont.ceraFont(ofSize: 16, Weight: .bold)
        interruptionDismiss.contentView.cornerRadius = Float.infinity
        interruptionDismiss.contentView.tintColor = UIColor.appropriateBlue
        interruptionDismiss.contentView.contentView.tintColor = UIColor.appropriateBlue
        interruptionDismiss.iconView.tintColor = UIColor.appropriateBlue
        interruptionDismiss.contentView.contentView.backgroundColor = .clear
        interruptionDismiss.contentView.backgroundMaterial = nil
        interruptionDismiss.contentView.contentView.layer.borderColor = UIColor.appropriateBlue.cgColor
        interruptionDismiss.contentView.contentView.layer.borderWidth = 0.5
        interruptionDismiss.label.uppercased = true
        interruptionDismiss.label.letterSpacing = 0.5
        interruptionDismiss.label.textColor = UIColor.appropriateBlue
        interruptionStackView.addArrangedSubview(interruptionDismiss)
        
        interruptionDismiss.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        
        mainView.addSubview(demoViewContainer)
        demoViewContainer.configureShadow(withColor: .black, radius: 24, andOpacity: 0.24)
        demoViewContainer.cornerRadius = 12
        demoViewContainer.snp.makeConstraints { make in
            make.leading.equalTo(self.view.snp.trailing).offset(24)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            make.width.equalTo(120)
            make.height.equalTo(180)
        }
        
        // Set the view's delegate
        sceneView = ARSCNView(frame: UIScreen.main.bounds)
        demoViewContainer.contentView.addSubview(sceneView)
        sceneView.snp.makeConstraints { make in
            make.everythingEqualToSuperView()
        }
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        // Setup Scenegraph
        sceneView.scene.rootNode.addChildNode(faceNode)
        sceneView.scene.rootNode.addChildNode(virtualPhoneNode)
        virtualPhoneNode.addChildNode(virtualScreenNode)
        faceNode.addChildNode(eyeLNode)
        faceNode.addChildNode(eyeRNode)
        eyeLNode.addChildNode(lookAtTargetEyeLNode)
        eyeRNode.addChildNode(lookAtTargetEyeRNode)
        
        // Set LookAtTargetEye at 2 meters away from the center of eyeballs to create segment vector
        lookAtTargetEyeLNode.position.z = 2
        lookAtTargetEyeRNode.position.z = 2
        
        self.view.layoutIfNeeded()
        switchScrollView.contentSize = switchStack.frame.size
    }
    
    @objc func interruptionDismiss (sender : AAButton) {
        print("dismiss")
        self.showInterruption(interrupt: false)
        ref?.child("isObserving").setValue(false)
    }
    
    var isInterrupting : Bool = false
    
    func showInterruption (interrupt : Bool) {
        
        if isInterrupting != interrupt {
            
            isInterrupting = interrupt
            
            UIView.animate(withDuration: 0.3, animations: {
                if self.isInterrupting {
                    self.interruptionContainer.alpha = 1
                    self.interruptionContainer.backgroundMaterial = UIBlurEffect(style: .light)
                } else {
                    self.interruptionContainer.alpha = 0
                    self.interruptionContainer.backgroundMaterial = nil
                }
            }, completion: nil)
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    @objc func activate (sender : UIButton) {
        UIView.animate(withDuration: 0.1, delay: 0, options: [UIView.AnimationOptions.curveEaseOut], animations: {
            self.focusView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }, completion: nil)
        
    }
    
    func startDebugging (debug : Bool) {
        UIView.animate(withDuration: 0.3) {
            if debug {
                self.demoViewContainer.snp.remakeConstraints { make in
                    make.trailing.equalToSuperview().inset(24)
                    make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
                    make.width.equalTo(120)
                    make.height.equalTo(180)
                }
                self.focusIndicator.alpha = 1
                self.focusShape.alpha = 1
                self.demoViewContainer.alpha = 1
                self.focusIndicator.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.view.layoutIfNeeded()
                
            } else {
                self.demoViewContainer.snp.remakeConstraints { make in
                    make.leading.equalTo(self.view.snp.trailing).offset(24)
                    make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
                    make.width.equalTo(120)
                    make.height.equalTo(180)
                }
                self.focusIndicator.alpha = 0
                self.focusIndicator.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                self.focusShape.alpha = 0
                self.demoViewContainer.alpha = 0
                self.view.layoutIfNeeded()
                
            }

        }
    }
    
    @objc func deactivate (sender : UIButton) {
        UIView.animate(withDuration: 0.1, delay: 0, options: [UIView.AnimationOptions.curveEaseOut], animations: {
            self.focusView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }, completion: nil)
    }
    
    var debugging = false
    
    
    @objc func invoke (sender : UIButton) {
        self.deactivate(sender: sender)
        
        debugging = !debugging
        self.startDebugging(debug: debugging)
        
    }
    
    func invokeNotification () {
        
        Sound.play(file: "waitingfor.mp3")
        
        if switchScrollView.currentPage == 1 {
            self.showInterruption(interrupt: true)
        } else {
            secondaryView.showNotification(show: true)
        }
        
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        faceNode.transform = node.transform
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        update(withFaceAnchor: faceAnchor)
    }
    
    func update(withFaceAnchor anchor: ARFaceAnchor) {
        
        eyeRNode.simdTransform = anchor.rightEyeTransform
        eyeLNode.simdTransform = anchor.leftEyeTransform
        
        var eyeLLookAt = CGPoint()
        var eyeRLookAt = CGPoint()
        
        let heightCompensation: CGFloat = 312
        
        DispatchQueue.main.async {
            
            // Perform Hit test using the ray segments that are drawn by the center of the eyeballs to somewhere two meters away at direction of where users look at to the virtual plane that place at the same orientation of the phone screen
            
            let phoneScreenEyeRHitTestResults = self.virtualPhoneNode.hitTestWithSegment(from: self.lookAtTargetEyeRNode.worldPosition, to: self.eyeRNode.worldPosition, options: nil)
            
            let phoneScreenEyeLHitTestResults = self.virtualPhoneNode.hitTestWithSegment(from: self.lookAtTargetEyeLNode.worldPosition, to: self.eyeLNode.worldPosition, options: nil)
            
            for result in phoneScreenEyeRHitTestResults {
                
                eyeRLookAt.x = CGFloat(result.localCoordinates.x) / (self.phoneScreenSize.width / 2) * self.phoneScreenPointSize.width
                
                eyeRLookAt.y = CGFloat(result.localCoordinates.y) / (self.phoneScreenSize.height / 2) * self.phoneScreenPointSize.height + heightCompensation
            }
            
            for result in phoneScreenEyeLHitTestResults {
                
                eyeLLookAt.x = CGFloat(result.localCoordinates.x) / (self.phoneScreenSize.width / 2) * self.phoneScreenPointSize.width
                
                eyeLLookAt.y = CGFloat(result.localCoordinates.y) / (self.phoneScreenSize.height / 2) * self.phoneScreenPointSize.height + heightCompensation
            }
            
            // Add the latest position and keep up to 8 recent position to smooth with.
            let smoothThresholdNumber: Int = 10
            self.eyeLookAtPositionXs.append((eyeRLookAt.x + eyeLLookAt.x) / 2)
            self.eyeLookAtPositionYs.append(-(eyeRLookAt.y + eyeLLookAt.y) / 2)
            self.eyeLookAtPositionXs = Array(self.eyeLookAtPositionXs.suffix(smoothThresholdNumber))
            self.eyeLookAtPositionYs = Array(self.eyeLookAtPositionYs.suffix(smoothThresholdNumber))
            
            let smoothEyeLookAtPositionX = self.eyeLookAtPositionXs.average!
            let smoothEyeLookAtPositionY = self.eyeLookAtPositionYs.average!
            
            self.updateFocus(point: CGPoint(x: smoothEyeLookAtPositionX, y: smoothEyeLookAtPositionY))
            
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let face = anchor as? ARFaceAnchor {
                
                if !face.isTracked {
                    UIView.animate(withDuration: 0.3) {
                        self.focusIcon.alpha = 0.25
                        self.focusIndicatorFocusIcon.alpha = 0.25
                    }
                    self.setFocusState(toFocussed: false)
                } else {
                    UIView.animate(withDuration: 0.3) {
                        self.focusIcon.alpha = 1
                        self.focusIndicatorFocusIcon.alpha = 1
                    }
                }
            }
        }
    }
    
    var focusTimer : Timer?
    
    func setFocusState (toFocussed focussed : Bool) {
        
        if switchScrollView.currentPage == 1 {
            if self.focussed != focussed {
                if focussed {
                    focusTimer?.invalidate()
                    focusTimer = nil
                    self.focussed = true
                    self.focusLabel.text = "Focussed"
                    ref?.child("focussed").setValue(true)
                    
                    UIView.animate(withDuration: 0.3) {
                        self.focusViewContainer.layoutIfNeeded()
                        self.onfocusIcon.alpha = 1
                        self.focusIndicatorEyeCon.alpha = 1
                    }
                    
                } else {
                    if focusTimer == nil {
                        focusTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { _ in
                            DispatchQueue.main.async {
                                self.focussed = false
                                self.focusLabel.text = "Distracted"
                                ref?.child("focussed").setValue(false)
                                
                                UIView.animate(withDuration: 0.3) {
                                    self.focusViewContainer.layoutIfNeeded()
                                    self.onfocusIcon.alpha = 0.25
                                    self.focusIndicatorEyeCon.alpha = 0.25
                                }
                            }
                        })
                        
                    }
                }
            }
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        virtualPhoneNode.transform = (sceneView.pointOfView?.transform)!
    }

    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        faceNode.transform = node.transform
        guard let faceAnchor = anchor as? ARFaceAnchor else {
            return
        }
        update(withFaceAnchor: faceAnchor)
    }
    
    func updateFocus (point : CGPoint) {
        
        let focusFrame = CGRect(origin: CGPoint(x: -2000, y: -2000), size: CGSize(width: 4000+UIScreen.main.bounds.width, height: 4000+UIScreen.main.bounds.height))
        
        if focusFrame.contains(point) {
            self.setFocusState(toFocussed: true)
        } else {
            self.setFocusState(toFocussed: false)
        }
        
        let normalizedPoint = self.view.convert(point, to: contentContainer)
        if debugging {
            focusShape.snp.updateConstraints { make in
                make.width.equalToSuperview()
                make.height.equalTo(120)
                make.centerX.equalToSuperview()
                make.centerY.equalTo(normalizedPoint.y)
            }
        }
    }
    
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }


}

extension UIScrollView {
    var currentPage:Int{
        return Int((self.contentOffset.x+(0.5*self.frame.size.width))/self.frame.width)+1
    }
}
