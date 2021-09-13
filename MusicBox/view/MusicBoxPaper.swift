//
//  MusicBoxPaper.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/11.
//

import UIKit

class MusicBoxPaper: UIView {
    
    // 상수
    let leftMargin: CGFloat = 20
    let topMargin: CGFloat = 20
    
    let cellWidth: CGFloat = 58
    let cellHeight: CGFloat = 22
    
    let rowNum = 29
    let colNum = 80
    
    let circleRadius: CGFloat = 15
    
    // 변수
    var circles: [CGPoint] = [] {
        didSet {
            print("didSet")
            self.setNeedsDisplay()
        }
    }
    
    private func gridToCGPoint(x: Int, y: Int) -> CGPoint {
        let pointX = leftMargin + x.cgFloat * cellWidth
        let pointY = topMargin + (y - 1).cgFloat * cellHeight
        return CGPoint(x: pointX, y: pointY)
    }
    
    // 점 찍기
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // 모든 가로 수치는 절대값 사용
        UIColor.black.set()
        let boxWidth = cellWidth * colNum.cgFloat
        let boxHeight = cellHeight * rowNum.cgFloat
        let outline = CGRect(x: leftMargin, y: topMargin, width: boxWidth, height: boxHeight)
        context.addRect(outline)
        context.strokePath()
        
        // 가로줄 그리기
        let innerRowNum = rowNum - 1
        for index in 1...innerRowNum {
            let targetY = topMargin + (index.cgFloat * cellHeight)
            context.move(to: CGPoint(x: topMargin, y: targetY))
            context.addLine(to: CGPoint(x: leftMargin + boxWidth, y: targetY))
            context.strokePath()
        }
        
        // 세로줄 그리기
        let innerColNum = colNum - 1
        for index in 1...innerColNum {
            let targetX = leftMargin + (index.cgFloat * cellWidth)
            context.move(to: CGPoint(x: targetX, y: leftMargin))
            context.addLine(to: CGPoint(x: targetX, y: leftMargin + boxHeight))
            context.strokePath()
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let noteNameAttrs = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue", size: 14)!, NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.foregroundColor: UIColor.black]
        
        for index in 1...29 {
            "\(index)".draw(with: CGRect(x: 0, y: 12 + Int(cellHeight) * (index - 1), width: 0, height: 0), options: .usesLineFragmentOrigin, attributes: noteNameAttrs, context: nil)
        }
        
        // 예제: (3, 5) (5, 20)에 점 찍기
        let point1 = gridToCGPoint(x: 3, y: 5)
        let point2 = gridToCGPoint(x: 5, y: 20)
        
        let circle1 = UIBezierPath(arcCenter: point1, radius: 15, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        let circle2 = UIBezierPath(arcCenter: point2, radius: 15, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        context.addPath(circle1.cgPath)
        context.fillPath()
        context.addPath(circle2.cgPath)
        context.fillPath()
        
        // 점 더하기
        for coord in circles {
            UIColor.red.set()
            let circle = UIBezierPath(arcCenter: coord, radius: circleRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
            context.addPath(circle.cgPath)
        }
        context.fillPath()
        
    }
}
