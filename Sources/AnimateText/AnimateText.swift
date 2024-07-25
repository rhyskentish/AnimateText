//
//  AnimateText.swift
//  AnimateText
//
//  Created by jasu on 2022/02/05.
//  Copyright (c) 2022 jasu All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is furnished
//  to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
//  PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
//  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import SwiftUI

/// A view that animates binding text. Passing the effect type as a generic.
public struct AnimateText<E: ATTextAnimateEffect>: View {

    @Binding private var texts: [String]
    @Binding private var currentIndex: Int

    var type: ATUnitType = .letters
    var userInfo: Any? = nil

    @State private var height: CGFloat = 0
    @State private var elements: Array<String> = []
    @State private var value: Double = 0
    @State private var toggle: Bool = false
    @State private var isChanged: Bool = false
    @State private var size: CGSize = .zero
    @State private var isAnimationComplete: Bool = false

    public init(_ texts: Binding<[String]>, currentIndex: Binding<Int>, type: ATUnitType = .letters, userInfo: Any? = nil) {
        _texts = texts
        _currentIndex = currentIndex
        self.type = type
        self.userInfo = userInfo
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            if !isChanged {
                Text(texts[currentIndex])
                    .takeSize($size)
                    .multilineTextAlignment(.center)
            } else {
                GeometryReader { geometry in
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(splitElements(containerWidth: geometry.size.width), id: \.self) { lineElements in
                            HStack {
                                Spacer()
                                HStack(spacing: 0) {
                                    ForEach(Array(lineElements.enumerated()), id: \.offset) { index, element in
                                        let data = ATElementData(element: element,
                                                                 type: self.type,
                                                                 index: index,
                                                                 count: elements.count,
                                                                 value: value,
                                                                 size: size)
                                        if toggle {
                                            Text(element).modifier(E(data, userInfo))
                                        } else {
                                            Text(element).modifier(E(data, userInfo))
                                        }
                                    }
                                }
                                .fixedSize(horizontal: true, vertical: false)
                                Spacer()
                            }
                        }
                    }
                    .onAppear {
                        height = CGFloat(splitElements(containerWidth: geometry.size.width).count) * 20
                    }
                    .onChange(of: geometry.size.width) { newValue in
                        height = CGFloat(splitElements(containerWidth: geometry.size.width).count) * 20
                    }
                }
                .frame(height: height)
            }
        }
        .onChange(of: currentIndex) { _ in
            animateCurrentText()
        }
        .onAppear {
            animateCurrentText()
        }
    }

    private func animateCurrentText() {
        withAnimation {
            value = 0
            getText(texts[currentIndex])
            toggle.toggle()
        }
        self.isChanged = true
        isAnimationComplete = false

        let animationDuration = Double(texts[currentIndex].count) * 0.05 + 0.5 // Add a small buffer

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: animationDuration)) {
                value = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            isAnimationComplete = true
        }
    }

    private func getText(_ text: String) {
        switch type {
        case .letters:
            self.elements = text.map { String($0) }
        case .words:
            var elements = [String]()
            text.components(separatedBy: " ").forEach{
                elements.append($0)
                elements.append(" ")
            }
            elements.removeLast()
            self.elements = elements
        }
    }

    func splitElements(containerWidth: CGFloat) -> [[String]] {
        var lines: [[String]] = [[]]
        var currentLineIndex = 0
        var remainingWidth: CGFloat = containerWidth
        var currentWord: String = ""
        var words: [String] = []
        
        // build words
        for (index, element) in elements.enumerated() {
            if element == " " {
                currentWord.append(element)
                words.append(currentWord)
                currentWord = ""
            } else {
                // Add the element to the current word
                currentWord.append(element)
                
                // Check if this is the last element
                if index == elements.count - 1 {
                    words.append(currentWord)
                }
            }
        }
        
        // build sentences, split words into elements
        for (index, word) in words.enumerated() {
            var letters: [String] = []
            for char in word {
                letters.append(String(char))
            }
            
            let wordWidth = word.width(withConstrainedHeight: 1000, font: .systemFont(ofSize: 40)) // change the size if you change a font on your contentView
            
            if index == 0 {
                lines[currentLineIndex].append(contentsOf: letters)
                remainingWidth -= wordWidth
            } else {
                if wordWidth > remainingWidth {
                    currentLineIndex += 1
                    lines.append(letters)
                    remainingWidth = containerWidth - wordWidth
                } else {
                    lines[currentLineIndex].append(contentsOf: letters)
                    remainingWidth -= wordWidth
                }
            }
        }
        return lines
    }
}

struct AnimateText_Previews: PreviewProvider {
    static var previews: some View {
        ATAnimateTextPreview<ATRandomTypoEffect>()
    }
}

extension String {
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.width)
    }
}
