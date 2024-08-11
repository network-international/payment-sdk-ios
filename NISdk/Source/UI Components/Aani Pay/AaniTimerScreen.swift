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
            
            Text("Paying \(amountFormatted)").font(.title)
                .multilineTextAlignment(.center)
                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            
            Text("Click the notification received on yor app to complete the payment").font(.caption)
                .multilineTextAlignment(.center)
                .padding(.vertical)
            
            Text(timeString).font(.largeTitle)
                .multilineTextAlignment(.center)
            Text("NOTE: Please do not close the app while the timer is running").font(.footnote)
                .multilineTextAlignment(.center)
                .padding(.vertical)
                .foregroundColor(.gray)
        }).padding()
    }
}

#Preview {
    AaniTimerScreen(amountFormatted: "3000 AED", timeString: "03:12")
}
