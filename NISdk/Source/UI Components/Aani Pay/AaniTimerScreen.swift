//
//  AaniTimerScreen.swift
//  NISdk
//
//  Created by Gautam Chibde on 06/08/24.
//

import SwiftUI

struct AaniTimerScreen: View {
    let amountFormatted: String
    let timeString: String
    
    var body: some View {
        VStack(alignment: .center, content: {
            
            CurrencySymbol.swiftUIText(String.localizedStringWithFormat("aani_paying_amount".localized, amountFormatted),
                                       fontSize: UIFont.preferredFont(forTextStyle: .title1).pointSize).font(.title)
                .multilineTextAlignment(.center)
                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            
            Text("aani_tap_notification".localized).font(.caption)
                .multilineTextAlignment(.center)
                .padding(.vertical)
            
            Text(timeString).font(.largeTitle)
                .multilineTextAlignment(.center)
            Text("aani_note_do_not_close".localized).font(.footnote)
                .multilineTextAlignment(.center)
                .padding(.vertical)
                .foregroundColor(.gray)
        }).padding()
    }
}

#Preview {
    AaniTimerScreen(amountFormatted: "3000 AED", timeString: "03:12")
}
