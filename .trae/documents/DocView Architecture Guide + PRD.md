## What I Found (Current Codebase)
- **Stack:** SwiftUI + SwiftData + Observation (`@Observable`) with state-driven navigation.
- **Persistence/DI:** `ModelContainer` created in [GrockApp.swift](file:///Users/ethanjohnpaguntalan/Downloads/SUI/Grock/Grock/App/GrockApp.swift#L128-L191), and app-wide dependencies injected via `.environment(...)` (not singletons) in [ContentView](file:///Users/ethanjohnpaguntalan/Downloads/SUI/Grock/Grock/App/GrockApp.swift#L86-L126).
- **Domain Boundary:** `VaultService` is the central mutation/persistence API (single source of truth for data writes) [VaultService.swift](file:///Users/ethanjohnpaguntalan/Downloads/SUI/Grock/Grock/Service/VaultService.swift).
- **SwiftData Schema:** All entities and relationships live in [Vault.swift](file:///Users/ethanjohnpaguntalan/Downloads/SUI/Grock/Grock/Models/Vault.swift).
- **Feature Areas:** Home, Vault, Cart Detail, Onboarding, Menu, Insights placeholder (menu routes to [MenuView.swift](file:///Users/ethanjohnpaguntalan/Downloads/SUI/Grock/Grock/Core/Menu/MenuView.swift#L10-L189)).

## Docs To Generate
- **Technical Architecture Guide** (deep technical):
  - App entry + dependency injection
  - Data model graph + invariants (User/Vault/Cart/CartItem, etc.)
  - Service layer responsibilities (VaultService)
  - ViewModel/UI-state separation (HomeViewModel, CartViewModel, CartStateManager)
  - Navigation/data flows (Onboarding → Home → Vault → Cart Detail)
  - Backward compatibility strategy for SwiftData (optional fields, safe fallbacks)
  - Extension points for future Insights
- **PRD (Product Requirements Document):**
  - Problem statement, target users/personas
  - Goals/non-goals
  - Core user journeys (plan trip → shop → complete trip)
  - Functional requirements (vault, carts, budgets, shopping-only items)
  - Analytics/Insights roadmap + data requirements
  - Success metrics + constraints (iOS 17+, offline-first)

## Implementation Plan (DocView)
1. **Create an in-app `DocView` (SwiftUI)** that renders markdown using `AttributedString(markdown:)` and `Text`, with:
   - A segmented control or sidebar list to switch between **Architecture** and **PRD**.
   - Copyable text (`.textSelection(.enabled)`).
2. **Generate the two documents as markdown sources** in one of two ways (I’ll choose the most maintainable unless you prefer otherwise):
   - **Option A (Bundle resources):** add `TECHNICAL_ARCHITECTURE.md` + `PRD.md` and load them from `Bundle.main`.
   - **Option B (Embedded):** embed the markdown as `static let` strings inside `DocView` (no resource wiring).
3. **Add navigation entry in the Menu** by inserting a `NavigationLink` in [MenuView.swift](file:///Users/ethanjohnpaguntalan/Downloads/SUI/Grock/Grock/Core/Menu/MenuView.swift) (e.g., “Documentation”) that pushes `DocView`.
4. **Verify build** by running diagnostics and ensuring markdown renders on-device/simulator (no runtime crashes if resources aren’t found).

## Deliverables
- `DocView` accessible from the Menu.
- A complete **Technical Architecture Guide** and **PRD** visible inside the app.
- (If Option A) two markdown files added to the project and included as app resources.

If you confirm this plan, I’ll implement it end-to-end (DocView + docs + menu integration) and validate compilation.