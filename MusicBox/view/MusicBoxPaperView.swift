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
    let leftMargin: CGFloat = 120
    let topMargin: CGFloat = 80
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
    var title: String = "Toccata & Fugue In D Minor - II. Fugue - BWV 538"
    var originalArtist: String = "J. S. Bach"
    var paperMaker: String = "Paper Man"
    var paperMadeBy: String = "The paper was made by"
    var fontPalatio: UIFont!
    var fontAlpha: CGFloat = 0.8
    var whenDrawAThickLineEveryBars = 4
    var whenToggleBackgroundColorEveryBars = 8
    
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
        
        fontPalatio = UIFont(name: "Palatio", size: 30) ?? UIFont()
        
        self.setNeedsDisplay()
    }
    
    func setTexts(title: String?, originalArtist: String?, paperMaker: String?) {
        if let title = title,
           let originalArtist = originalArtist,
           let paperMaker = paperMaker {
            self.title = title
            self.originalArtist = originalArtist
            self.paperMaker = paperMaker
        }
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
            context.setFillColor(CGColor(gray: 0.894, alpha: fontAlpha))
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
                ? context.setFillColor(CGColor(gray: 0.894, alpha: fontAlpha))
                : context.setFillColor(CGColor(gray: 1, alpha: fontAlpha))
            
            context.fill(
                CGRect(
                    x: CGFloat(imBeatCount) * cst.cellWidth + boxOutline.minX + cst.cellWidth * CGFloat(index - 1),
                    y: boxOutline.minY,
                    width: cst.cellWidth,
                    height: boxOutline.height
                )
            )
            
            if index % whenToggleBackgroundColorEveryBars == 0 {
                toggleTableBackgroundColor = !toggleTableBackgroundColor
            }
            
        }
        
        let cst = PaperConstant.shared

        // 모든 가로 수치는 절대값 사용
        context.setStrokeColor(CGColor(gray: 0, alpha: fontAlpha))
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
        let blackFontUIColor = UIColor.black
        
        var noteNameAttrs = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue", size: 13.4)!, NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.foregroundColor: blackFontUIColor]
        
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
        context.setStrokeColor(CGColor(gray: 0.95, alpha: fontAlpha))
        
        if imBeatCount > 0 {
            for index in 1...imBeatCount {
                let targetX = cst.leftMargin + (index.cgFloat * cst.cellWidth)
                context.move(to: CGPoint(x: targetX, y: cst.topMargin))
                if index < imBeatCount {
                    context.setLineWidth(1)
                    context.setStrokeColor(CGColor(gray: 0.4, alpha: fontAlpha))
                } else {
                    context.setLineWidth(2)
                    context.setStrokeColor(CGColor(gray: 0, alpha: fontAlpha))
                }
                context.addLine(to: CGPoint(x: targetX, y: cst.topMargin + boxOutline.height))
                context.strokePath()
            }
        }
        
        noteNameAttrs[NSAttributedString.Key.foregroundColor] = UIColor(cgColor: CGColor(gray: 0.1, alpha: 0.5))
        for index in 1...innerColNum {
            let targetX = cst.leftMargin + (index.cgFloat * cst.cellWidth) + (imBeatCount.cgFloat * cst.cellWidth)
            context.move(to: CGPoint(x: targetX, y: cst.topMargin))
            if index % whenDrawAThickLineEveryBars == 0 {
                context.setLineWidth(2)
                context.setStrokeColor(CGColor(gray: 0, alpha: fontAlpha))
            } else {
                context.setLineWidth(1)
                context.setStrokeColor(CGColor(gray: 0.1, alpha: fontAlpha))
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
        
        // 제목 - 아티스트
        let titleParagaphStyle = NSMutableParagraphStyle()
        titleParagaphStyle.alignment = .left
        let titleFontSize: CGFloat = 39
        let titleAttrs = [NSAttributedString.Key.font: UIFont(name: "Palatino", size: titleFontSize)!, NSAttributedString.Key.paragraphStyle: titleParagaphStyle, NSAttributedString.Key.foregroundColor: blackFontUIColor]
        
        let titleSize = (title as NSString).size(withAttributes: titleAttrs)
        let titleX: CGFloat = boxOutline.minX
        let titleY: CGFloat = 30
        let titleRect = CGRect(x: titleX, y: titleY, width: titleSize.width, height: titleSize.height)
        title.draw(with: titleRect, options: .usesLineFragmentOrigin, attributes: titleAttrs, context: nil)
        
        let artistFontSize: CGFloat = 27
        let artistAttrs = [NSAttributedString.Key.font: UIFont(name: "Palatino", size: artistFontSize)!, NSAttributedString.Key.paragraphStyle: titleParagaphStyle, NSAttributedString.Key.foregroundColor: blackFontUIColor]
        
        let artistSize = (originalArtist as NSString).size(withAttributes: artistAttrs)
        let artistX: CGFloat = titleRect.maxX + 30
        let artistY: CGFloat = 40.2
        let artistRect = CGRect(x: artistX, y: artistY, width: artistSize.width, height: artistSize.height)
        originalArtist.draw(with: artistRect, options: .usesLineFragmentOrigin, attributes: artistAttrs, context: nil)
        
        // 꼬릿말
        let footerFontSize: CGFloat = 25
        let footerAttrs = [NSAttributedString.Key.font: UIFont(name: "Palatino", size: footerFontSize)!, NSAttributedString.Key.paragraphStyle: titleParagaphStyle, NSAttributedString.Key.foregroundColor: blackFontUIColor]
        
        let footerText: NSString = "\(paperMadeBy) \(paperMaker) - http://musicbox.con" as NSString
        let footerSize = footerText.size(withAttributes: footerAttrs)
        let footerRect = CGRect(x: boxOutline.minX, y: boxOutline.maxY + 20, width: footerSize.width, height: footerSize.height)
        footerText.draw(with: footerRect, options: .usesLineFragmentOrigin, attributes: footerAttrs, context: nil)

        // 점 더하기
        if let backgroundPatternImage = UIImage(named: "Melamine-wood-2") {
            UIColor(patternImage: backgroundPatternImage).set()
        } else {
            UIColor.black.set()
        }
        for coord in data {
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
