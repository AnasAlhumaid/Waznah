//
//  ContantView.swift
//  Waznah
//
//  Created by Anas Hamad on 10/4/22.
//

import SwiftUI

struct ContantView: View {
    
    private var isDaytime: Bool {
          let calendar = Calendar.current
          let currentTime = getCurrentTime()
          let startOfDay = calendar.startOfDay(for: currentTime)
          let sixAM = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: startOfDay)!
          let sixPM = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: startOfDay)!
          return currentTime >= sixAM && currentTime < sixPM
      }
    var body: some View {
        Home()
            .preferredColorScheme(isDaytime ? .light : .dark)
        
    }
}

struct ContantView_Previews: PreviewProvider {
    static var previews: some View {
        ContantView()
    }
}
