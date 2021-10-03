//
//  MusicBoxPaper.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/11.
//

import UIKit

struct PaperConstant {
    static let shared = PaperConstant()
    
    // 상수
    let leftMargin: CGFloat = 80
    let topMargin: CGFloat = 120
//    let leftMargin: CGFloat = 20
//    let topMargin: CGFloat = 57
    
    let cellWidth: CGFloat = 58
    let cellHeight: CGFloat = 22
//    let cellWidth: CGFloat = 20
//    let cellHeight: CGFloat = 35
    
    let circleRadius: CGFloat = 10
    
    let defaultColNum: Int = 80
    let viewWidthPerCol: CGFloat = 62.5
}

class MusicBoxPaperView: UIView {
    
    // flag
    var isFirstRun: Bool = true
    
    var util: MusicBoxUtil!
    var rowNum: Int = 0
    var colNum: Int = 0

    var test: String!
    
    var imBeatCount: Int = 0
    
    // draw 주요 정보 저장
    var boxOutline: CGRect!

    var data: [PaperCoord] = [] {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    let cst = PaperConstant.shared
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configure(rowNum: Int, colNum: Int, util: MusicBoxUtil) {
        
        self.rowNum = rowNum
        self.colNum = colNum
        
        let boxWidth = cst.cellWidth * (colNum + imBeatCount).cgFloat
        let boxHeight = cst.cellHeight * (rowNum - 1).cgFloat
        self.boxOutline = CGRect(x: cst.leftMargin, y: cst.topMargin, width: boxWidth, height: boxHeight)

        self.util = util
        
        self.setNeedsDisplay()
    }
    
    func reloadPaper() {
        self.configure(rowNum: self.rowNum, colNum: self.colNum, util: util)
        self.setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // 배경색 채우기
        // 못갖춘마디

        if imBeatCount > 0 {
            context.setFillColor(CGColor(gray: 0.894, alpha: 1))
            for index in 1...imBeatCount {
                context.fill(
                    CGRect(
                        x: boxOutline.minX + cst.cellWidth * CGFloat(index - 1),
                        y: boxOutline.minY,
                        width: cst.cellWidth,
                        height: boxOutline.height
                    )
                )
            }
        }
        
        var toggleTableBackgroundColor: Bool = false
        
        for index in 1...colNum {
            toggleTableBackgroundColor
                ? context.setFillColor(CGColor(gray: 0.894, alpha: 1))
                : context.setFillColor(CGColor(gray: 1, alpha: 1))
            
            context.fill(
                CGRect(
                    x: CGFloat(imBeatCount) * cst.cellWidth + boxOutline.minX + cst.cellWidth * CGFloat(index - 1),
                    y: boxOutline.minY,
                    width: cst.cellWidth,
                    height: boxOutline.height
                )
            )
            
            if index % 8 == 0 {
                toggleTableBackgroundColor = !toggleTableBackgroundColor
            }
            
        }
        
        let cst = PaperConstant.shared

        // 모든 가로 수치는 절대값 사용
        UIColor.black.set()
        context.addRect(boxOutline)
        context.strokePath()

        // 가로줄 그리기
        let innerRowNum = rowNum - 1
        for index in 1...innerRowNum {
            let targetY = cst.topMargin + (index.cgFloat * cst.cellHeight)
            context.move(to: CGPoint(x: cst.leftMargin, y: targetY))
            context.addLine(to: CGPoint(x: cst.leftMargin + boxOutline.width, y: targetY))
            context.strokePath()
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        var noteNameAttrs = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue", size: 13.4)!, NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.foregroundColor: UIColor.black]
        
        // 노트 이름 윗 마진 (공통)
        let noteTextTopMargin: CGFloat = cst.topMargin - 8.4
        
        // (맨처음) 왼쪽에 노트 이름 적기
        for (index, note) in util.noteRange.enumerated() {
            let targetX = boxOutline.minX - 28
            let noteRect = CGRect(x: targetX, y: noteTextTopMargin + cst.cellHeight * index.cgFloat, width: 0, height: 0)

            let noteTextValue = note.textValueSharp
            noteTextValue.draw(with: noteRect, options: .usesLineFragmentOrigin, attributes: noteNameAttrs, context: nil)
        }
        
        // 세로줄 그리기
        let innerColNum = colNum - 1
        context.setStrokeColor(CGColor(gray: 0.95, alpha: 1))
        
        if imBeatCount > 0 {
            for index in 1...imBeatCount {
                let targetX = cst.leftMargin + (index.cgFloat * cst.cellWidth)
                context.move(to: CGPoint(x: targetX, y: cst.topMargin))
                if index < imBeatCount {
                    context.setLineWidth(1)
                    context.setStrokeColor(CGColor(gray: 0.4, alpha: 1))
                } else {
                    context.setLineWidth(2)
                    context.setStrokeColor(CGColor(gray: 0, alpha: 1))
                }
                context.addLine(to: CGPoint(x: targetX, y: cst.topMargin + boxOutline.height))
                context.strokePath()
            }
        }
        
        noteNameAttrs[NSAttributedString.Key.foregroundColor] = UIColor(cgColor: CGColor(gray: 0.1, alpha: 0.5))
        for index in 1...innerColNum {
            let targetX = cst.leftMargin + (index.cgFloat * cst.cellWidth) + (imBeatCount.cgFloat * cst.cellWidth)
            context.move(to: CGPoint(x: targetX, y: cst.topMargin))
            if index % 4 == 0 {
                context.setLineWidth(2)
                context.setStrokeColor(CGColor(gray: 0, alpha: 1))
            } else {
                context.setLineWidth(1)
                context.setStrokeColor(CGColor(gray: 0.1, alpha: 1))
            }
            context.addLine(to: CGPoint(x: targetX, y: cst.topMargin + boxOutline.height))
            context.strokePath()
            
            if index % 16 == 0 {
                // (중간) 왼쪽에 노트 이름 적기
                for (index, note) in util.noteRange.enumerated() {
                    
                    let noteRect = CGRect(x: targetX, y: noteTextTopMargin + cst.cellHeight * index.cgFloat, width: 0, height: 0)

                    let noteTextValue = note.textValueSharp
                    noteTextValue.draw(with: noteRect, options: .usesLineFragmentOrigin, attributes: noteNameAttrs, context: nil)
                }

            }
        }

        // 점 더하기
        for coord in data {
            UIColor.red.set()
//            let arcCenter = CGPoint(x: coord.snappedPoint.x + cst.leftMargin, y: coord.snappedPoint.y + cst.topMargin)
            let arcX = cst.leftMargin + coord.gridX! * cst.cellWidth
            let arcY = cst.topMargin + coord.gridY!.cgFloat * cst.cellHeight
            let arcCenter = CGPoint(x: arcX, y: arcY)
            let circle = UIBezierPath(arcCenter: arcCenter, radius: cst.circleRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
            
            context.addPath(circle.cgPath)

        }
        context.fillPath()

        isFirstRun = false
        
    }
}
