//
//  GrockApp.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/28/25.
//

import SwiftUI
import SwiftData

@main
struct GrockApp: App {
    var body: some Scene {
        WindowGroup {
            if UserDefaults.standard.hasCompletedOnboarding {
                HomeView()
                    .environment(\.font, .custom("Lexend", size: 16))
            } else {
                OnboardingContainer()
                    .environment(\.font, .custom("Lexend", size: 16))
            }
        }
        .modelContainer(for: [
            Vault.self,
            Category.self,
            Item.self,
            PriceOption.self,
            PricePerUnit.self,
            Cart.self,
            CartItem.self,
            Store.self
        ])
    }
}
