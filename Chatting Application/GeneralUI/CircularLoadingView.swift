//
//  Loading View.swift
//  Custom Views
//
//  Created by Sagar Baloch on 04/08/2020.
//  Copyright © 2020 Sagar Baloch. All rights reserved.
//

import Foundation
import UIKit



// This is an Loading View
//You can show it by using showLoading() method.
//Hide it by using hideLoading() method.

class CircularLoadingView: UIView {
    
    static var loadingView: CircularLoadingView?
    let rotatingCirclesView = RotatingCirclesView()
    
    static func showLoading(controllerView: UIView? = nil){
        
        //  return
        print("SHOWING LOADING")
        
        //loadingView?.removeFromSuperview()
        
        guard let mainView:UIView = UIApplication.shared.keyWindow ?? controllerView else {return}
        loadingView = CircularLoadingView()
        guard let loadingView = loadingView else{ return }
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(loadingView)
        loadingView.leftAnchor.constraint(equalTo: mainView.leftAnchor).isActive = true
        loadingView.rightAnchor.constraint(equalTo: mainView.rightAnchor).isActive = true
        loadingView.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
        loadingView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        
    }
    
    fileprivate lazy var background:UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.alpha = 0.8
        return v
    }()
    
    fileprivate func setupViews(){
        addSubview(background)
        background.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        background.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        background.topAnchor.constraint(equalTo: topAnchor).isActive = true
        background.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        addSubview(rotatingCirclesView)
        rotatingCirclesView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        rotatingCirclesView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        rotatingCirclesView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        rotatingCirclesView.widthAnchor.constraint(equalToConstant: 200).isActive = true
    }
    
    static func hideLoading(){
        loadingView?.removeFromSuperview()
        
        loadingView = CircularLoadingView()
        print("HIDING LOADING")
        
        
        
    }
    
    //When you're inflating with code
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        rotatingCirclesView.animate(rotatingCirclesView.circle1, counter: 1)
        rotatingCirclesView.animate(rotatingCirclesView.circle2, counter: 3)
    }
    
    //When you're inflating with storyboard/xib
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
}

class RotatingCirclesView: UIView {
    
    let circle1 = UIView(frame: CGRect(x: 20, y: 20, width: 60, height: 60))
    let circle2 = UIView(frame: CGRect(x: 120, y: 20, width: 60, height: 60))
    let position : [CGRect] = [CGRect(x: 30, y: 20, width: 60, height: 60),CGRect(x: 60, y: 15, width: 70, height: 70),CGRect(x: 110, y: 20, width: 60, height: 60),CGRect(x: 60, y: 25, width: 50, height: 50)]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func configure(){
        translatesAutoresizingMaskIntoConstraints = false
        circle1.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        circle1.alpha = 0.8
        circle1.layer.cornerRadius = circle1.frame.width/2
        circle1.layer.zPosition = 2
        
        circle2.backgroundColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
        circle2.alpha = 0.8
        circle2.layer.cornerRadius = circle2.frame.width/2
        circle2.layer.zPosition = 1
        
        addSubview(circle1)
        addSubview(circle2)
    }
    
    func animate(_ circle: UIView, counter: Int){
        var counter = counter
        
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveLinear, animations: { [weak self] in
            if self?.position.count == 0{return}
            circle.frame = (self?.position[counter])!
            circle.layer.cornerRadius = circle.frame.width/2
            
            switch counter{
            case 1:
                if circle == self?.circle1{ self?.circle1.layer.zPosition = 2}
            case 3:
                if circle == self?.circle1{ self?.circle1.layer.zPosition = 0}
            default:
                break;
            //  print()
            
            }
        }) { [weak self] (completed) in
            
            guard let self = self else{return}
            //if counter == 0{return}
            
            switch counter{
            case 0...2:
                counter += 1
            case 3:
                counter = 0
            default:
                break;
            //  print()
            }
            self.animate(circle, counter: counter)
        }
        
    }
}
