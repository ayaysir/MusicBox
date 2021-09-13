//
//  MusicBoxPaper.swift
//  MusicBox
//
//  Created by yoonbumtae on 2021/09/11.
//

import UIKit

class MusicBoxPaperView: UIView {
    
    // flag
    var isFirstRun: Bool = true
    
    // 상수
    let leftMargin: CGFloat = 30
    let topMargin: CGFloat = 20
    
    let cellWidth: CGFloat = 58
    let cellHeight: CGFloat = 22
    
    let circleRadius: CGFloat = 10
    
    // 변수
    var util: MusicBoxUtil!
    var noteRange: [Note]!
    var noteRangeWithHeight: [NoteWithHeight] = []
    
    var rowNum = 29
    var colNum = 80
    
    // draw 주요 정보 저장
    var boxOutline: CGRect!

    var data: [CGPoint] = [] {
        didSet {
            self.setNeedsDisplay()
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        let boxWidth = cellWidth * colNum.cgFloat
        let boxHeight = cellHeight * (rowNum - 1).cgFloat
        self.boxOutline = CGRect(x: leftMargin, y: topMargin, width: boxWidth, height: boxHeight)
        print("init from coder")
        
        util = MusicBoxUtil(highestNote: Note(note: .E, octave: 6), cellWidth: cellWidth, cellHeight: cellHeight)
        noteRange = util.getNoteRange()
        rowNum = noteRange.count
        
        let tolerance = cellHeight - topMargin
        for (index, note) in noteRange.enumerated() {
            let noteHeight = NoteWithHeight(height: tolerance + boxOutline.minY + cellHeight * index.cgFloat, note: note)
            noteRangeWithHeight.append(noteHeight)
        }
    }
    
    func addPaperCoordByCGPoint() {
        
    }
    
    private func gridToCGPoint(x: Int, y: Int) -> CGPoint {
        let pointX = leftMargin + x.cgFloat * cellWidth
        let pointY = topMargin + (y - 1).cgFloat * cellHeight - (cellHeight - topMargin)
        return CGPoint(x: pointX, y: pointY)
    }
    

    
    func setValues() {
        
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        setValues()

        // 모든 가로 수치는 절대값 사용
        UIColor.black.set()
        context.addRect(boxOutline)
        context.strokePath()
        
        // 가로줄 그리기
        let innerRowNum = rowNum - 1
        for index in 1...innerRowNum {
            let targetY = topMargin + (index.cgFloat * cellHeight)
            context.move(to: CGPoint(x: leftMargin, y: targetY))
            context.addLine(to: CGPoint(x: leftMargin + boxOutline.width, y: targetY))
            context.strokePath()
        }
        
        // 세로줄 그리기
        let innerColNum = colNum - 1
        for index in 1...innerColNum {
            let targetX = leftMargin + (index.cgFloat * cellWidth)
            context.move(to: CGPoint(x: targetX, y: topMargin))
            context.addLine(to: CGPoint(x: targetX, y: topMargin + boxOutline.height))
            context.strokePath()
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let noteNameAttrs = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue", size: 13.4)!, NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.foregroundColor: UIColor.black]
        
        // 왼쪽에 노트 이름 적기
        for (index, note) in noteRange.enumerated() {
            let noteTextTopMargin: CGFloat = topMargin * 0.5
            let noteRect = CGRect(x: 0, y: noteTextTopMargin + cellHeight * index.cgFloat, width: 0, height: 0)
            
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
            let snapCoord = CGPoint(x: util.snapToGridX(originalX: coord.x), y: util.snapToGridY(originalY: coord.y))
            let circle = UIBezierPath(arcCenter: snapCoord, radius: circleRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
            context.addPath(circle.cgPath)
            
            _ = util.getNoteFromCGPointY(range: noteRangeWithHeight, coord: coord)
        }
        context.fillPath()
        
        isFirstRun = false
        
    }
}
