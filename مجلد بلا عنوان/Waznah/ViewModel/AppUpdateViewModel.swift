//
//  AppUpdateViewModel.swift
//  Waznah
//

import Foundation
import UIKit

@MainActor
final class AppUpdateViewModel: ObservableObject {
    enum Phase: Equatable {
        case checking
        case ready
    }
    
    @Published var phase: Phase = .checking
    @Published var updateKind: AppUpdateKind = .none
    
    private let manager = AppUpdateManager.shared
    
    var currentVersion: String {
        manager.currentAppVersion
    }
    
    func checkForUpdate() async {
        phase = .checking
        updateKind = await manager.checkForUpdate()
        phase = .ready
    }
    
    func openAppStore(urlString: String) {
        guard let url = URL(string: urlString),
              !urlString.isEmpty,
              UIApplication.shared.canOpenURL(url) else {
            return
        }
        
        UIApplication.shared.open(url)
    }
}
