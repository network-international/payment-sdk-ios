//
//  AaniTimerScreen.swift
//  NISdk
//
//  Created by Gautam Chibde on 06/08/24.
//

import SwiftUI

@available(iOS 13.0, *)
struct AaniTimerScreen: View {
    let amountFormatted: String
    let timeString: String
    
    var body: some View {
        VStack(alignment: .center, content: {
            
            Text(String.localizedStringWithFormat("aani_paying_amount".localized, amountFormatted)).font(.title)
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

@available(iOS 13.0, *)
#Preview {
    AaniTimerScreen(amountFormatted: "3000 AED", timeString: "03:12")
}
