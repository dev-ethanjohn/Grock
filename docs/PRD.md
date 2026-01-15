# Grock Product Requirements Document (PRD)

## 1. Product Overview

**Product Name:** Grock  
**Tagline:** Smart Grocery Shopping Companion  
**Platform:** iOS (SwiftUI)

Grock is a privacy-first, offline-capable grocery shopping app designed to help users manage their personal "Vault" of grocery items, plan trips with budget estimates, and track actual spending in real-time. Unlike generic to-do lists, Grock remembers prices per store, allowing for accurate budget forecasting.

---

## 2. Core Value Proposition

1.  **Price Intelligence:** Remembers the last price paid for an item at specific stores.
2.  **Budget Control:** Compare "Planned" vs. "Actual" spending during a trip.
3.  **Store-Specific Organization:** Items can have different prices and units depending on where they are bought.
4.  **Offline First:** All data lives locally on the device using SwiftData.

---

## 3. User Journeys

### Journey A: The Planner

> "I want to create a list for my weekly run to Trader Joe's and know how much it will cost."

1.  User opens Grock and creates a new Cart named "Weekly TJ's".
2.  User sets a Budget (e.g., $150).
3.  User adds items from their **Vault** (previously bought items).
4.  Grock auto-fills the price based on history at Trader Joe's.
5.  User sees the "Planned Total" update as items are added.

### Journey B: The Shopper

> "I am at the store and want to get in and out quickly while staying on budget."

1.  User taps "Start Shopping" on the cart.
2.  App enters **Shopping Mode** (distraction-free UI).
3.  User checks off items as they pick them up.
4.  If a price has changed, User updates it immediately.
5.  If User grabs an impulse item, they add it as a "Shopping-Only Item".
6.  User taps "Finish Trip" at the checkout.
7.  Grock updates the **Vault** with the new prices for next time.

---

## 4. Functional Requirements

### 4.1 The Vault (Database)

- **Categories:** Items must be organized by category (Produce, Dairy, etc.).
- **Item History:** Each item stores price history per Store.
- **Search:** Global search to find items across all categories.

### 4.2 Carts (Shopping Lists)

- **States:** A cart can be in `Planning`, `Shopping`, or `Completed` state.
- **Budgeting:** Visual progress bar showing Total vs. Budget.
- **Cloning:** Ability to duplicate previous carts (implied requirement for recurring trips).

### 4.3 Shopping Mode

- **Active Tracking:** Toggle items as "Fulfilled".
- **Edit on the Fly:** Ability to change quantity or price while shopping.
- **Impulse Buys:** Add items that don't need to be saved to the permanent Vault.

### 4.4 Insights (Roadmap)

- _Future Feature:_ Charts showing spending over time.
- _Future Feature:_ Price inflation tracking per item.

---

## 5. Non-Functional Requirements

- **Performance:** App must launch and be ready to input in < 2 seconds.
- **Privacy:** No account required; all data stored locally.
- **UI/UX:** Large tap targets for one-handed use while pushing a cart.
- **Feedback:** Haptic feedback when checking off items.
