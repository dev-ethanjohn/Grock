# Grock Technical Architecture

This document outlines the technical architecture of the Grock application. It includes data models, service layer responsibilities, and data flow diagrams.

## 1. High-Level Architecture

Grock follows a **Modern SwiftUI Architecture** pattern:

- **UI Framework:** SwiftUI
- **Data Persistence:** SwiftData
- **State Management:** Observation (`@Observable`)
- **Architecture Pattern:** MVVM-S (Model-View-ViewModel-Service)

### Core Components

- **Views:** Declarative UI components.
- **ViewModels:** Handle view-specific logic and state (e.g., `CartDetailViewModel`, `HomeViewModel`).
- **Services:** `VaultService` acts as the singleton-like source of truth for domain logic and data persistence.
- **Models:** SwiftData entities defining the schema.

---

## 2. Data Model Diagram

The following class diagram illustrates the SwiftData entities and their relationships.

```mermaid
classDiagram
    class User {
        +String id
        +String name
        +Vault userVault
    }

    class Vault {
        +String uid
        +Category[] categories
        +Cart[] carts
        +Store[] stores
    }

    class Category {
        +String uid
        +String name
        +Int sortOrder
        +Item[] items
    }

    class Item {
        +String id
        +String name
        +PriceOption[] priceOptions
        +Bool isTemporaryShoppingItem
    }

    class PriceOption {
        +String store
        +PricePerUnit pricePerUnit
    }

    class PricePerUnit {
        +Double priceValue
        +String unit
    }

    class Cart {
        +String id
        +String name
        +Double budget
        +CartStatus status
        +CartItem[] cartItems
        +totalSpent()
    }

    class CartItem {
        +String itemId
        +Double quantity
        +Bool isFulfilled
        +String plannedStore
        +Double plannedPrice
        +String actualStore
        +Double actualPrice
    }

    class Store {
        +String name
        +Date createdAt
    }

    User "1" -- "1" Vault : owns
    Vault "1" -- "*" Category : contains
    Vault "1" -- "*" Cart : contains
    Vault "1" -- "*" Store : contains
    Category "1" -- "*" Item : contains
    Item "1" -- "*" PriceOption : has prices at
    PriceOption "1" -- "1" PricePerUnit : defines
    Cart "1" -- "*" CartItem : contains
```

---

## 3. Application Data Flow

Grock uses `VaultService` as the central hub for data mutations. Views do not modify SwiftData models directly; they request changes via `VaultService`.

```mermaid
flowchart TD
    subgraph UI_Layer [UI Layer]
        HomeView
        CartDetailView
        ItemSheet
    end

    subgraph Logic_Layer [Business Logic]
        HomeViewModel
        CartDetailViewModel
        VaultService
    end

    subgraph Data_Layer [Persistence Layer]
        ModelContext[SwiftData ModelContext]
        Disk[(SQLite Store)]
    end

    HomeView -- User Action --> HomeViewModel
    CartDetailView -- User Action --> CartDetailViewModel

    HomeViewModel -- Calls --> VaultService
    CartDetailViewModel -- Calls --> VaultService

    VaultService -- CRUD Operations --> ModelContext
    ModelContext -- Auto-Save --> Disk

    VaultService -- @Observable Updates --> UI_Layer
```

---

## 4. Key Workflows

### Shopping Trip Lifecycle

The core feature of Grock is the transition of a Cart from **Planning** to **Shopping** to **Completed**.

```mermaid
stateDiagram-v2
    [*] --> Planning

    Planning --> Shopping: Start Trip
    note right of Planning
        - Edit Quantities
        - Select Stores
        - Estimate Budget
    end note

    Shopping --> Completed: Finish Trip
    Shopping --> Planning: Abort/Reset
    note right of Shopping
        - Mark Fulfilled
        - Record Actual Prices
        - Add Surprise Items
    end note

    Completed --> Shopping: Reopen Cart
    Completed --> [*]
    note right of Completed
        - Read-Only History
        - Vault Prices Updated
    end note
```

## 5. Directory Structure

```text
Grock/
├── App/                # App entry point and dependency injection
├── Core/               # Feature modules
│   ├── Detail Cart/    # Shopping list and execution views
│   ├── Home/           # Dashboard and cart management
│   ├── Menu/           # Settings and app navigation
│   ├── Onboarding/     # First-time user experience
│   └── Vault/          # Item and category management
├── Models/             # SwiftData entity definitions
├── Service/            # VaultService and business logic
└── Utils/              # Helpers and extensions
```
