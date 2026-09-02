# 🛒 Supermarket On-Demand Ordering, Express Delivery & Click-and-Collect Platform

A complete multi-platform solution designed for on-demand supermarket grocery shopping, order fulfillment, and delivery management, optimized for the Tanzanian urban market.

---

## 🌟 Key Features & Problem Solved

Traditional supermarket shopping often means traffic, long queues, and wasted time wandering aisles. This platform provides a streamlined, digital shopping experience:

- **🛵 Express Doorstep Delivery**:
  - Customer orders via mobile app or website.
  - Driver assigned automatically or by supermarket dispatch.
  - Real-time navigation via native map intent (Google Maps / Apple Maps) without expensive API fees.
  - Landmark-based addressing designed specifically for Tanzania (City, Neighborhood, Landmark, House details).

- **🏬 Click & Collect (Store Pickup)**:
  - Avoid moving around looking for goods!
  - Order ahead; supermarket staff pack and sort items in bags.
  - Customer walks into the supermarket, shows their pickup code, collects the ready parcel, and leaves in under a minute.

- **📱 Multi-Surface Experience**:
  - **Flutter Mobile App**: Fast, smooth mobile experience on Android & iOS.
  - **Vercel Web Storefront**: Accessible directly in mobile/desktop browsers for users who haven't downloaded the app.
  - **Supermarket Admin & Packing Portal**: Dashboard for store staff to manage stock, check off packed items, and dispatch drivers.
  - **Driver Companion**: Simple mobile view for drivers to view customer phone, destination landmark, and launch GPS navigation.

- **💳 Localized Tanzanian Payments**:
  - **Phase 1 (Lean MVP)**: Cash on Delivery (COD), Cash at Pickup, and Manual Lipa Namba (Vodacom M-Pesa, Tigo Pesa, Airtel Money).
  - **Phase 2 (Automated Gateway)**: Integrated USSD push prompts via AzamPay, Selcom, or Beem Africa.

---

## 🗺️ Map Integration (Zero-Cost & Zero Billing Traps)

To eliminate credit-card registration hurdles and expensive Google Maps API bills:
1. **Interactive Pin Picker**: Powered by **OpenStreetMap** (`flutter_map`) — 100% free and open-source.
2. **Turn-by-Turn Driver Navigation**: Uses native device URL intents (`google.navigation:q=lat,lng`) to launch the driver's pre-installed Google Maps / Apple Maps app with free voice navigation.
3. **Landmark Addressing**: City + Ward + Famous Landmark fallback ensuring drivers reach destinations without needing exact street numbers.

---

## 🏗️ Architecture & Ecosystem

```
                  ┌───────────────────────────────────────────────┐
                  │           SUPABASE / FIREBASE BACKEND         │
                  │  (PostgreSQL/Firestore, Auth, Storage, PubSub) │
                  └──────┬─────────────┬─────────────┬────────────┘
                         │             │             │            │
            ┌────────────┴──┐   ┌──────┴──────┐   ┌──┴─────────┐  └──────────┐
            ▼               ▼   ▼             ▼   ▼            ▼             ▼
  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
  │ CUSTOMER FLUTTER │ │ CUSTOMER WEB APP │ │ SUPERMARKET ADMIN│ │ DRIVER COMPANION │
  │    MOBILE APP    │ │ (Vite/Next.js on │ │ & PACKING PORTAL │ │ (Lightweight PWA │
  │  (Android/iOS)   │ │     Vercel)      │ │   (Web/Tablet)   │ │  or Mobile View) │
  └──────────────────┘ └──────────────────┘ └──────────────────┘ └──────────────────┘
```

Detailed architectural diagrams, database schemas, and AI prompt templates can be found in [PROJECT_PLAN.md](file:///c:/Users/MWIJAY%20TECH/Desktop/PROJECTS/E-commerce-App-UI-Flutter-master/PROJECT_PLAN.md).

---

## 📁 Repository Structure

```
├── assets/                    # Icons and product imagery
├── lib/                       # Flutter Application source code
│   ├── constants.dart         # Global theme colors and spacing tokens
│   ├── main.dart              # Flutter application entry point
│   ├── models/                # Data models (Product, CartItem, Order, Category)
│   ├── providers/             # State management (CartProvider, OrderProvider)
│   └── screens/
│       ├── home/              # Supermarket catalog, category filters, search
│       ├── details/           # Product detail view with quantity selector
│       ├── checkout/          # Delivery vs Pickup toggle, address & payment
│       └── orders/            # Live order timeline & driver tracking
├── PROJECT_PLAN.md            # Master Blueprint, Tanzanian context & AI prompts
├── pubspec.yaml               # Flutter dependencies and asset registrations
└── README.md                  # Project overview and documentation
```

---

## 🚀 Getting Started with the Flutter App

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.5.0 or higher)
- Android Studio / VS Code with Flutter extension
- Android device or emulator

### Installation
1. Clone the repository:
   ```bash
   git clone <repository_url>
   cd E-commerce-App-UI-Flutter-master
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

---

## 🎯 Next Steps & Implementation Sprints

Check out [PROJECT_PLAN.md](file:///c:/Users/MWIJAY%20TECH/Desktop/PROJECTS/E-commerce-App-UI-Flutter-master/PROJECT_PLAN.md) for:
- Detailed database schemas for orders, products, and branches.
- Ready-to-use AI prompts to build the next phases (Cart State, Checkout Screen, Vercel Web Landing, Admin Packing Dashboard).
- Step-by-step roadmap from small-scale launch to full multi-branch rollout.
