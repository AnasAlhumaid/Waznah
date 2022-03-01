//
//  Extentions.swift
//  Waznah
//
//  Created by Anas Hamad on 26/07/1443 AH.
//

import Foundation

extension String{
    
    var localized: String {
          return NSLocalizedString(self, comment: "")
      }
    
}

/*
 let currentLanguage = Locale.current.languageCode
 
 let alert = UIAlertController(title: "Warning".localized, message: "The application will be restarted".localized, preferredStyle: .actionSheet)
 alert.addAction(UIAlertAction(title: "Restart".localized, style: .default) { restart in
     let newLanguage = currentLanguage == "en" ? "ar" : "en"
     UserDefaults.standard.setValue([newLanguage], forKey: "AppleLanguages")
     exit(0)
 })
 alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
 present(alert, animated: true)
 */
