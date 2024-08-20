import Foundation

func determineDeviceLanguage() -> String {
    let supportedLanguages = ["it", "fr", "es", "de"]
    var deviceLanguage = "en"
    if let deviceLanguageIdentifier = Locale.current.language.languageCode?.identifier,
       supportedLanguages.contains(deviceLanguageIdentifier) {
        deviceLanguage = deviceLanguageIdentifier
    }
    return deviceLanguage
}

func setCurrentDate() {
    let today = Date()
    UserDefaults.standard.set(today, forKey: "currentDate")
}
