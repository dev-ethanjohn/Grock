import Foundation

extension UserDefaults {
    private enum CategoryKeys {
        static let visibleCategoryNames = "visibleCategoryNames"
    }
    
    var visibleCategoryNames: [String] {
        get {
            guard
                let data = data(forKey: CategoryKeys.visibleCategoryNames),
                let decoded = try? JSONDecoder().decode([String].self, from: data),
                !decoded.isEmpty
            else {
                return GroceryCategory.allCases.map(\.title)
            }
            
            return decoded
        }
        set {
            let normalized = newValue
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            guard let data = try? JSONEncoder().encode(normalized) else {
                removeObject(forKey: CategoryKeys.visibleCategoryNames)
                return
            }
            
            set(data, forKey: CategoryKeys.visibleCategoryNames)
        }
    }
}

