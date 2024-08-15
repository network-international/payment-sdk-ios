//
//  AaniPayView.swift
//  NISdk
//
//  Created by Gautam Chibde on 02/08/24.
//

import SwiftUI

struct AaniPayView: View {
    @ObservedObject var viewModel: AaniViewModel
    
    var body: some View {
        let direction: LayoutDirection = if (Locale.characterDirection(forLanguage: NISdk.sharedInstance.sdkLanguage) == .rightToLeft) {
            .rightToLeft
        } else {
            .leftToRight
        }
        switch viewModel.viewType {
        case .inputSelection:
            AaniInputScreen { type, text in
                viewModel.onSubmit(idType: type, inputText: text)
            }.environment(\.layoutDirection, direction)
        case .timer:
            AaniTimerScreen(amountFormatted: viewModel.getAmountFormatted(), timeString: viewModel.timeString)
                .environment(\.layoutDirection, direction)
        }
    }
}
