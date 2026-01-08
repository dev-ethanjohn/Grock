//
//  UserDefaults+Onboarding.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/28/25.
//

import Foundation

extension UserDefaults {
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let userName = "userName"
        static let hasPromptedForNameAfterOnboarding = "hasPromptedForNameAfterOnboarding"
        static let hasPromptedForNameAfterVaultCelebration = "hasPromptedForNameAfterVaultCelebration"
    }

    var hasCompletedOnboarding: Bool {
        get { bool(forKey: Keys.hasCompletedOnboarding) }
        set { set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }
    
    var userName: String? {
        get { string(forKey: Keys.userName) }
        set { set(newValue, forKey: Keys.userName) }
    }
    
    var hasEnteredName: Bool {
        guard let name = userName else { return false }
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasPromptedForNameAfterOnboarding: Bool {
        get { bool(forKey: Keys.hasPromptedForNameAfterOnboarding) }
        set { set(newValue, forKey: Keys.hasPromptedForNameAfterOnboarding) }
    }
    
    var hasPromptedForNameAfterVaultCelebration: Bool {
        get { bool(forKey: Keys.hasPromptedForNameAfterVaultCelebration) }
        set { set(newValue, forKey: Keys.hasPromptedForNameAfterVaultCelebration) }
    }
}
