import Foundation
import Combine

@MainActor
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String
    @Published var locale: Locale
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        let currentLocale = Locale.current
        self.locale = currentLocale
        self.currentLanguage = currentLocale.identifier.contains("zh-Hans") ? "zh-Hans" : "en"
        
        NotificationCenter.default.publisher(for: NSLocale.currentLocaleDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateLocale()
            }
            .store(in: &cancellables)
    }
    
    private func updateLocale() {
        locale = Locale.current
        currentLanguage = locale.identifier.contains("zh-Hans") ? "zh-Hans" : "en"
    }
    
    func localizedString(key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
    func localizedString(key: String, comment: String) -> String {
        return NSLocalizedString(key, comment: comment)
    }
    
    var searchPlaceholder: String {
        localizedString(key: "search.placeholder")
    }
    
    var settingsTitle: String {
        localizedString(key: "settings.title")
    }
    
    var noResults: String {
        localizedString(key: "search.noResults")
    }
    
    var generalTab: String {
        localizedString(key: "settings.tab.general")
    }
    
    var appearanceTab: String {
        localizedString(key: "settings.tab.appearance")
    }
    
    var shortcutTab: String {
        localizedString(key: "settings.tab.shortcut")
    }
}

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with comment: String) -> String {
        return NSLocalizedString(self, comment: comment)
    }
}
