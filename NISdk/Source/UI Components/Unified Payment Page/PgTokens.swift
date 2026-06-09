//
//  PgTokens.swift
//  NISdk
//
//  Design tokens — mirrors PgColors/Spacing/Radius/PgSize/PgType from Android payment page redesign.
//

import UIKit

enum PgColors {
    static let accentPrimary      = UIColor(hexString: "#0069B1")
    static let surfacePage        = UIColor.white
    static let surfaceRow         = UIColor(hexString: "#F5F9FC")
    static let textPrimary        = UIColor(hexString: "#070707")
    static let textSecondary      = UIColor(hexString: "#4A4A4A")
    static let textMuted          = UIColor(hexString: "#8F8F8F")
    static let textEligibility    = UIColor(hexString: "#EEAA16")
    static let borderRow          = UIColor(hexString: "#E6F0F7")
    static let borderSection      = UIColor(hexString: "#C2DBEC")
    static let borderInput        = UIColor(hexString: "#DADADA")
    static let borderInputFocused = UIColor(hexString: "#91BFDD")
    static let badgeDarkBg        = UIColor(hexString: "#2FBF71")
    static let badgeDarkText      = UIColor.white
    static let spinnerPrimary     = UIColor(hexString: "#EEAA16")
    static let spinnerTrack       = UIColor(hexString: "#FFD781")
    static let surfaceSliceDetail = UIColor(hexString: "#FFF8EA")
    static let dividerSlice       = UIColor(hexString: "#FFF2D8")
    static let textOnTabSelected  = UIColor.white
    static let borderTabUnselected = UIColor(hexString: "#C2DBEC")
}

enum PgSpacing {
    static let pageH: CGFloat          = 20
    static let sectionGap: CGFloat     = 24
    static let rowGap: CGFloat         = 12
    static let rowPaddingH: CGFloat    = 16
    static let rowPaddingV: CGFloat    = 12
    static let fieldsStackGap: CGFloat = 12
    static let headingToContent: CGFloat = 16
}

enum PgRadius {
    static let pill: CGFloat   = 20
    static let row: CGFloat    = 8
    static let input: CGFloat  = 8
    static let badge: CGFloat  = 16
    static let button: CGFloat = 8
}

enum PgSize {
    static let radioOuter: CGFloat           = 18
    static let radioInner: CGFloat           = 9
    static let tabHeight: CGFloat            = 36
    static let inputMinHeight: CGFloat       = 56
    static let buttonHeight: CGFloat         = 48
    static let brandLogoStripHeight: CGFloat = 36
    static let providerLogoHeight: CGFloat   = 24
    static let merchantLogoHeight: CGFloat   = 28
    static let merchantLogoMaxWidth: CGFloat = 120
}

enum PgType {
    static let headingSection     = UIFont.systemFont(ofSize: 16, weight: .medium)
    static let bodyRowTitle       = UIFont.systemFont(ofSize: 14, weight: .medium)
    static let bodyRowSubtitle    = UIFont.systemFont(ofSize: 12, weight: .regular)
    static let labelField         = UIFont.systemFont(ofSize: 14, weight: .medium)
    static let bodyInput          = UIFont.systemFont(ofSize: 16, weight: .regular)
    static let amountSummary      = UIFont.systemFont(ofSize: 18, weight: .medium)
    static let amountRow          = UIFont.systemFont(ofSize: 14, weight: .medium)
    static let captionSlicePeriod = UIFont.systemFont(ofSize: 12, weight: .regular)
    static let pillTabSelected    = UIFont.systemFont(ofSize: 12, weight: .bold)
    static let pillTabUnselected  = UIFont.systemFont(ofSize: 12, weight: .medium)
    static let buttonPrimary      = UIFont.systemFont(ofSize: 16, weight: .medium)
    static let captionDisclaimer  = UIFont.systemFont(ofSize: 13, weight: .regular)
}
