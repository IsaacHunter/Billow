//
//  CanvasView.swift
//  Canvas
//
//  Created by Brian Advent on 01.12.17.
//  Copyright © 2017 Brian Advent. All rights reserved.
//

import UIKit

class CanvasView: UIView {

    // Properties for line drawing
    var lineColor:UIColor!
    var lineWidth:CGFloat!
    var path:UIBezierPath!
    var touchPoint:CGPoint!
    var startingPoint:CGPoint!
    var canDraw:Bool=false
    var history:[[CALayer]?]!
    var historyIndex:Int = 0
    
    override func layoutSubviews() {
        self.clipsToBounds = true // no lines should be visible outside of the view
        self.isMultipleTouchEnabled = false // we only process one touch at a time
        
        // standard settings for our line
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // get the touch position when user starts drawing
        let touch = touches.first
        startingPoint = touch?.location(in: self)
        NSLog("started")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // save the canvas when touch ended so that we can undo
        if (historyIndex == 10) {
            for i:Int in 0 ..< 9 {
                history[i] = history[i+1]
            }
            historyIndex = historyIndex - 1
        }
        history[historyIndex] = self.layer.sublayers
        historyIndex=historyIndex+1
        NSLog("ended")
    }
    
    func distance(from lhs: CGPoint, to rhs: CGPoint) -> CGFloat {
        let xDistance = lhs.x - rhs.x
        let yDistance = lhs.y - rhs.y
        return sqrt(xDistance * xDistance + yDistance * yDistance)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (canDraw) {
            // get the next touch point as the user draws
            let touch = touches.first
            touchPoint = touch?.location(in: self)
        
            // create path originating from the starting point to the next point the user reached
            path = UIBezierPath()
            path.move(to: startingPoint)
            path.addLine(to: touchPoint)
            
            let dist = distance(from: startingPoint, to: touchPoint);
        
            // setting the startingPoint to the previous touchpoint
            // this updates while the user draws
            startingPoint = touchPoint
        
            drawShapeLayer(withSpeed: dist) // draws the actual line shapes
        }
    }
    
    func drawShapeLayer(withSpeed speed: CGFloat) {
        
        let shapeLayer = CAShapeLayer()
        // the shape layer is used to draw along the already created path
        shapeLayer.path = path.cgPath
        
        // adjusting the shape to our wishes
        shapeLayer.strokeColor = lineColor.cgColor
        shapeLayer.lineWidth = min(lineWidth*(log(speed)*(-0.15) + 1.0), lineWidth); //increase the -0.15 to make the line smaller at faster speeds
        shapeLayer.lineCap = kCALineCapRound
        shapeLayer.fillColor = UIColor.clear.cgColor
        
        // adding the shapelayer to the vies layer and forcing a redraw
        self.layer.addSublayer(shapeLayer)
        self.setNeedsDisplay()
        
    }
    
    func clearCanvas() -> [CALayer]? {
        initHistory()
        let tempLayers = self.layer.sublayers
        
        if (path != nil) {
            path.removeAllPoints()
        }
        self.layer.sublayers = nil
        self.setNeedsDisplay()
        return tempLayers
    }
    
    func initHistory() {
        history = [[CALayer]?](repeating: nil, count: 10)
        historyIndex = 0
    }
    
    func undo() {
        if (historyIndex > 0) {
            if (path != nil) {
                path.removeAllPoints()
            }
            self.layer.sublayers = nil
            self.setNeedsDisplay()
            historyIndex=historyIndex-1
        }
        if (historyIndex > 0 && history[historyIndex-1] != nil) {
            for shape:CALayer in history[historyIndex-1]! {
                self.layer.addSublayer(shape)
            }
            history[historyIndex] = nil
        }
    }
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
