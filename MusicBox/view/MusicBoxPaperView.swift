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
    let leftMargin: CGFloat = 30
    let topMargin: CGFloat = 20
    
    let cellWidth: CGFloat = 58
    let cellHeight: CGFloat = 22
    
    let circleRadius: CGFloat = 10
}

class MusicBoxPaperView: UIView {
    
    // flag
    var isFirstRun: Bool = true
    
    var util: MusicBoxUtil!
    var rowNum: Int = 0
    var colNum: Int = 0

    var test: String!
    
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
        
        let boxWidth = cst.cellWidth * colNum.cgFloat
        let boxHeight = cst.cellHeight * (rowNum - 1).cgFloat
        self.boxOutline = CGRect(x: cst.leftMargin, y: cst.topMargin, width: boxWidth, height: boxHeight)

        self.util = util
        print("init1")
    }

    func addPaperCoordByCGPoint() {

    }

    private func gridToCGPoint(x: Int, y: Int) -> CGPoint {
        let cst = PaperConstant.shared
        let pointX = cst.leftMargin + x.cgFloat * cst.cellWidth
        let pointY = cst.topMargin + (y - 1).cgFloat * cst.cellHeight - (cst.cellHeight - cst.topMargin)
        return CGPoint(x: pointX, y: pointY)
    }



    func setValues() {

    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // 배경색 채우기
        var toggleTableBackgroundColor: Bool = false
        
        for index in 1...colNum {
            toggleTableBackgroundColor ? UIColor.lightGray.setFill() : UIColor.white.setFill()
            
            context.fill(CGRect(x: boxOutline.minX + cst.cellWidth * CGFloat(index - 1), y: boxOutline.minY, width: cst.cellWidth, height: boxOutline.height))
            
            if index % 8 == 0 {
                toggleTableBackgroundColor = !toggleTableBackgroundColor
            }
            
        }
        
        let cst = PaperConstant.shared

        setValues()

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

        // 세로줄 그리기
        let innerColNum = colNum - 1
        for index in 1...innerColNum {
            let targetX = cst.leftMargin + (index.cgFloat * cst.cellWidth)
            context.move(to: CGPoint(x: targetX, y: cst.topMargin))
            context.addLine(to: CGPoint(x: targetX, y: cst.topMargin + boxOutline.height))
            context.strokePath()
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let noteNameAttrs = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue", size: 13.4)!, NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.foregroundColor: UIColor.black]

        // 왼쪽에 노트 이름 적기
        for (index, note) in util.noteRange.enumerated() {
            let noteTextTopMargin: CGFloat = cst.topMargin * 0.5
            let noteRect = CGRect(x: 0, y: noteTextTopMargin + cst.cellHeight * index.cgFloat, width: 0, height: 0)

            let noteTextValue = note.textValueSharp
            noteTextValue.draw(with: noteRect, options: .usesLineFragmentOrigin, attributes: noteNameAttrs, context: nil)
        }

//        // 지우개 모드인 경우
//        if true {
//            data.map { coord in
//
//            }
//        }
//
        // 점 더하기
        for coord in data {
            UIColor.red.set()
            let circle = UIBezierPath(arcCenter: coord.snappedPoint, radius: cst.circleRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
            context.addPath(circle.cgPath)

        }
        context.fillPath()

        isFirstRun = false
        
    }
}
