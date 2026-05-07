//
//  RadioButtonView.swift
//  NISdk
//
//  Created on 06/02/26.
//  Copyright © 2026 Network International. All rights reserved.
//

import UIKit

class RadioButtonView: UIView {

    var isOn: Bool = false {
        didSet { setNeedsDisplay() }
    }

    private let outerSize: CGFloat = PgSize.radioOuter
    private let innerSize: CGFloat = PgSize.radioInner

    private let selectedColor = PgColors.accentPrimary
    private let unselectedBorderColor = PgColors.borderInput

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: outerSize),
            heightAnchor.constraint(equalToConstant: outerSize)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let outerRect = CGRect(x: (rect.width - outerSize) / 2,
                               y: (rect.height - outerSize) / 2,
                               width: outerSize, height: outerSize)

        let borderColor = isOn ? selectedColor : unselectedBorderColor
        ctx.setStrokeColor(borderColor.cgColor)
        ctx.setLineWidth(1.13)
        ctx.strokeEllipse(in: outerRect.insetBy(dx: 0.565, dy: 0.565))

        if isOn {
            ctx.setFillColor(selectedColor.cgColor)
            let innerRect = CGRect(
                x: outerRect.midX - innerSize / 2,
                y: outerRect.midY - innerSize / 2,
                width: innerSize, height: innerSize)
            ctx.fillEllipse(in: innerRect)
        }
    }
}
