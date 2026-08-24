# CRUZARO ENT — Agent Instructions

> **Primary deployment target: Web (Vercel)**
> Live URL: `https://cruz-lake.vercel.app`

This document is the canonical reference for all AI agents, developers, and contributors working on this project. Read it fully before making any changes.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack](#2-tech-stack)
3. [MCP Tooling (Supabase)](#3-mcp-tooling-supabase)
4. [Project Structure](#4-project-structure)
5. [Architecture & Data Flow](#5-architecture--data-flow)
6. [Authentication & Roles](#6-authentication--roles)
7. [Feature Map](#7-feature-map)
8. [Business Cycles Architecture](#8-business-cycles-architecture)
9. [Data Models](#9-data-models)
10. [State Management (Riverpod)](#10-state-management-riverpod)
11. [Database Schema (Supabase)](#11-database-schema-supabase)
12. [Environment Variables](#12-environment-variables)
13. [Web / Vercel Deployment](#13-web--vercel-deployment)
14. [Responsive Design Rules](#14-responsive-design-rules)
15. [Design System & Theme](#15-design-system--theme)
16. [Coding Conventions](#16-coding-conventions)
17. [Known Gotchas & Defensive Coding](#17-known-gotchas--defensive-coding)

---

## 1. Project Overview

**CRUZARO ENT** is a Flutter web application for managing a box-scheme / installment sales business.

| Audience | Role | Purpose |
|---|---|---|
| Business owners | `ADMIN` | Oversee all customers, agents, products, payments, business cycles, and system settings |
| Sales staff | `AGENT` | Register customers, record daily collections, manage client ledger |

The app is deployed exclusively as a **Flutter web app on Vercel**.

---

## 2. Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter (Dart) — web target |
| Backend / DB | Supabase (PostgreSQL + Auth) |
| State management | Riverpod 2.x (`flutter_riverpod`) |
| Environment vars | `flutter_dotenv` (`.env` file bundled as asset) |
| Deployment | Vercel (static hosting of Flutter web build) |
| Auth redirect | `https://cruz-lake.vercel.app/reset-password` |
| DB tooling (AI) | **Supabase MCP** (`https://mcp.supabase.com/mcp`) |

---

## 3. MCP Tooling (Supabase)

> **All AI agents MUST use the Supabase MCP server** for any database-related tasks. Do NOT instruct the user to open the Supabase Dashboard manually unless there is no MCP equivalent.

### MCP Server Config

The Supabase MCP is configured in `C:\Users\user\.gemini\config\mcp_config.json`:

```json
"supabase": {
  "serverUrl": "https://mcp.supabase.com/mcp",
  "headers": {
    "Authorization": "Bearer <PAT>"
  }
}
```

- **Project ID**: `hutfslpjdbrevfwwafvz`
- **Name**: `cruzaroenterprise`

### Preferred MCP Tools for Common Tasks

| Task | MCP Tool to use |
|---|---|
| Run a SQL query | `execute_sql` |
| Apply a migration | `apply_migration` |
| List tables / schema | `list_tables` |
| Check query logs | `query_logs` |
| Get security advisors | `get_advisors` |
| List installed extensions | `list_extensions` |
| Get project URL / anon key | `get_project_url` / `get_publishable_keys` |

---

## 4. Project Structure

```
CRUZ/
├── lib/
│   ├── main.dart                   # Entry point — loads .env, inits Supabase
│   ├── core/
│   │   ├── constants.dart          # App-wide string constants
│   │   ├── providers.dart          # Repository providers (Riverpod)
│   │   ├── responsive.dart         # Responsive breakpoints & ResponsiveWrapper
│   │   └── theme.dart              # AppTheme (Admin Navy + Agent Green)
│   ├── data/
│   │   ├── models/                 # Pure Dart data classes
│   │   │   ├── customer.dart
│   │   │   ├── customer_product.dart
│   │   │   ├── cycle.dart          # Business cycles (Cycle 1, Cycle 2, etc.)
│   │   │   ├── payment.dart
│   │   │   ├── payment_edit_request.dart
│   │   │   ├── product.dart        # Single / Double products
│   │   │   ├── profile.dart        # UserRole enum (ADMIN / AGENT)
│   │   │   └── zone.dart
│   │   └── repositories/           # Supabase data access layer
│   │       ├── auth_repository.dart
│   │       ├── agent_repository.dart
│   │       ├── customer_repository.dart
│   │       ├── customer_product_repository.dart
│   │       ├── cycle_repository.dart
│   │       ├── payment_repository.dart
│   │       ├── payment_edit_request_repository.dart
│   │       ├── product_repository.dart
│   │       ├── settings_repository.dart
│   │       └── zone_repository.dart
│   ├── providers/
│   │   ├── auth_provider.dart      # authStateProvider, currentUserProvider
│   │   ├── admin_providers.dart    # All admin FutureProviders & Cycle scoping
│   │   └── agent_providers.dart    # All agent FutureProviders & Cycle lock
│   └── features/
│       ├── auth/
│       │   ├── login_screen.dart
│       │   ├── forgot_password_screen.dart
│       │   └── update_password_screen.dart
│       ├── admin/
│       │   ├── navigation/admin_nav_shell.dart   # Rail (desktop) + BottomNav (mobile)
│       │   ├── dashboard/admin_dashboard_screen.dart
│       │   ├── customers/customer_list_screen.dart
│       │   ├── agents/
│       │   │   ├── agent_management_screen.dart
│       │   │   └── agent_profile_screen.dart
│       │   ├── products/
│       │   │   ├── product_catalog_screen.dart
│       │   │   └── product_detail_screen.dart
│       │   └── settings/system_settings_screen.dart
│       └── agent/
│           ├── navigation/agent_nav_shell.dart   # BottomNav only
│           ├── dashboard/agent_dashboard_screen.dart
│           ├── customers/
│           │   ├── lookup_client_screen.dart
│           │   └── add_product_dialog.dart
│           ├── ledger/
│           │   ├── collection_ledger_screen.dart
│           │   └── payment_edit_dialog.dart
│           └── registration/new_registration_screen.dart
├── web/                            # Flutter web scaffolding (index.html, etc.)
├── vercel.json                     # Vercel SPA routing config
├── pubspec.yaml                    # Dependencies
└── .env                            # Bundled as asset
```

---

## 5. Architecture & Data Flow

```
┌─────────────────────────────────────────────────┐
│                Flutter Web UI                   │
│  Screens → Riverpod Providers → Repositories    │
└────────────────────┬────────────────────────────┘
                     │ HTTP (Supabase client)
                     ▼
┌─────────────────────────────────────────────────┐
│              Supabase (Backend)                 │
│  Auth  │  PostgreSQL DB  │  Row Level Security  │
└─────────────────────────────────────────────────┘
```

---

## 6. Authentication & Roles

| Role | Access |
|---|---|
| `ADMIN` | All admin management screens, cycle switcher, products CRUD, settings |
| `AGENT` | Agent screens, strictly locked to the currently active business cycle |

---

## 7. Feature Map

### Admin Portal (`AdminNavShell`)
- **Stats Tab (0)**: `AdminDashboardScreen` — Total collections, registered customers count, per-agent daily drill-down, and cycle switcher.
- **Customers Tab (1)**: `CustomerListScreen` — View all customer records per cycle, assign products, approve backdated payments, approve edit requests.
- **Agents Tab (2)**: `AgentManagementScreen` & `AgentProfileScreen` — Create/deactivate agents, per-agent totals and audit logs.
- **Products Tab (3)**: `ProductCatalogScreen` — Tabbed Single vs Double products catalog, code/name search bar, smart product creation modal, edit product, customer counts.
- **Settings Tab (4)**: `SystemSettingsScreen` — Cycle management (create, activate, close), registration fees, zones.

### Agent Portal (`AgentNavShell`)
- **Dashboard Tab (0)**: `AgentDashboardScreen` — Single hero card with today's collection, date picker, inline customer/registration chips, 2 equal-weight action cards (`Customers`, `Register New`), and `Collection Ledger` row.
- **Lookup Tab (1)**: `LookupClientScreen` — Search assigned customers, click "Collect" to immediately record and open the **Customer Payment History Modal** (receipt + full transaction ledger to prevent duplicate submissions), direct "HISTORY" button on customer cards.
- **Ledger Tab (2)**: `CollectionLedgerScreen` — Full payment transaction list and `PaymentEditDialog` for requesting corrections.
- **Register Tab (3)**: `NewRegistrationScreen` — Register new customer directly attached to the currently active business cycle.

---

## 8. Business Cycles Architecture

CRUZARO ENT operates in distinct business cycles (e.g., `Cycle 1`, `Cycle 2`).
- **Scoping**: When a new cycle is activated by Admin, all fresh products, customers, registrations, and payments are scoped to `cycle_id`.
- **Admin**: Can switch between cycles via `selectedCycleIdProvider` in the AppBars to view historical cycles (e.g. Cycle 1) or current active cycles (e.g. Cycle 2).
- **Agent**: Agents are strictly locked to `agentActiveCycleProvider` (active cycle). They cannot switch cycles manually; switching tabs automatically syncs the active cycle.

---

## 9. Data Models

### `Cycle` (`lib/data/models/cycle.dart`)
```dart
int id
String name
bool isActive
DateTime createdAt
DateTime? endedAt
String? notes
```

### `Product` (`lib/data/models/product.dart`)
```dart
int id
String name
String code
String type              // 'single' | 'double'
double boxRate, totalPrice // totalPrice is generated column
int totalBoxes
int? cycleId
bool isSingle, isDouble  // computed
String displayName       // computed: name (code)
```

### `Customer` (`lib/data/models/customer.dart`)
```dart
String id, fullName
String? phone
int? zoneId
String productId
String? assignedAgentId
int totalBoxesAssigned, boxesPaid
double balanceDue, registrationFeePaid
bool isActive
DateTime createdAt
int? cycleId
```

### `CustomerProduct` (`lib/data/models/customer_product.dart`)
```dart
String id, customerId
int productId
bool isActive, deletionRequested
int boxesAssigned, boxesPaid
double balanceDue, registrationFeePaid
DateTime createdAt
int? cycleId
```

### `Payment` (`lib/data/models/payment.dart`)
```dart
String id, customerId, agentId
double amountPaid
String? productId
int? boxesEquivalent
DateTime timestamp
bool isApproved        // false = backdated, requires admin approval
int? cycleId
```

---

## 10. State Management (Riverpod)

### Key Providers:
- `currentAdminCycleProvider`: Resolves active cycle or manual admin selection.
- `agentActiveCycleProvider`: Resolves currently active cycle for agent operations.
- `customerPaymentHistoryProvider(customerId)`: Fetches reverse-chronological payments for a customer scoped to active cycle.
- `productsListProvider`: Admin product list scoped to `currentAdminCycleProvider`.
- `agentProductsProvider`: Agent product list scoped to `agentActiveCycleProvider`.

---

## 11. Known Gotchas & Defensive Coding

1. **Foreign Key Joins in Supabase**:
   - Always use safe left joins (`products!left(...)`, `zones!left(...)`, `profiles!assigned_agent_id!left(...)`) in Supabase select queries to prevent crashes if a foreign key is `null`.
2. **Defensive Model Parsing**:
   - Always use helper parsing methods (e.g. `parseIntOrNull`, `parseDoubleOrZero`, `DateTime.tryParse`) in `.fromJson` factories instead of direct `as int` or `as double` casts.
3. **Generated Postgres Columns**:
   - `products.total_price` is a Postgres generated column (`box_rate * total_boxes`). Never send it in insert/update queries.
4. **Duplicate Prevention**:
   - Always launch `_showCustomerPaymentHistoryModal` after `recordPayment` in agent screens to provide an immediate receipt and visual proof of transaction.
