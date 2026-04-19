# PesaCrow Admin App: Technical Implementation Guide

This document outlines the architecture, existing features, and recently integrated administrative enhancements for the PesaCrow management console.

## 🎨 UI/UX Design System
- **Aesthetic**: Premium Dark Mode using Deep Slate (`#0B1120`) and Midnight Blue (`#0F172A`).
- **Accent**: Emerald Green (`#10B981`) for success/primary actions.
- **Pattern**: Collapsible Sidebar with permission-aware navigation.
- **Reactive State**: SSE-driven updates for balances and transaction changes.

---

## 📂 Core Modules & Features

### 1. 📊 Dashboard (Upgraded)
- **Current**: KPI cards for volume, earnings, and counts.
- **NEW [Integrated]**: Platform Revenue Statistics (`GET /admin/financials/stats`).
    - **Visuals**: Track "Realized Revenue" (fees collected) vs "Withdrawable Balance".
    - **Real-time**: Real-time update of platform profit as deals move to `released`.

### 2. 📝 Transactions (Enhanced)
- **Current**: Global search and slide-in detail panel.
- **NEW [Integrated]**: 
    - **CSV Export**: Filtered data downloads for accounting and compliance.
    - **Quick Query**: One-click check against Safaricom for any transaction's receipt.

### 3. 👤 User Management (New Capability)
- **Function**: Identity and Governance.
- **Key Feature**: **Account Freezing**.
    - Admins can soft-freeze users (locking deal creation but allowing login).
    - Dedicated **Frozen Accounts** tab to monitor restricted users.

### 4. ⚖️ Dispute Resolution (Refined)
- **Current**: Resolution flow (Release/Refund).
- **NEW [Integrated]**:
    - **Internal Admin Notes**: Collaborative thread for admins to discuss evidence before resolving.
    - **Evidence Viewer**: Direct links to buyer/seller uploaded proofs.

### 5. 💰 Financials & Fee Management
- **Function**: Revenue model config and withdrawal tracking.
- **Features**:
    - Manage tiered transaction/release fees.
    - Track platform-wide withdrawal history to ensure balance integrity.

### 6. 🛠️ M-Pesa Tools (Live Workspace)
- **Current**: SandBox simulations and URL registration.
- **NEW [Integrated]**: 
    - **Live Receipt Query**: Validate any M-Pesa receipt number (`QKB...`) directly from Safaricom API.
    - **Transaction Linking**: Automatically link a Safaricom query result to a local `ESC-KE` deal.

### 7. ⚙️ System Configuration (Advanced)
- **Features**:
    - **Webhook Control**: Dynamically update primary/secondary callback URLs.
    - **OTP Governance**: Manage the dedicated physical device number used for 2FA admin actions.

### 8. 💸 Manual Disbursement (Dual-Factor)
- **Security**: Heavily guarded by 2-Step verification.
- **Channels**: Supports B2C, Pochi, PayBill, and BuyGoods.

### 9. 👥 Admin & Access Control (RBAC)
- **System**: Granular Permission Registry (**27 unique keys**).
- **State**: `AuthProvider` fetches permissions via `GET /admin/my-permissions` to reflow sidebar navigation.

### 10. 📝 Audit Logs (Compliance)
- **Features**: 
    - Permanent record of all administrative changes.
    - **Export**: Full CSV download of logs for regulatory reporting.

---

## 🛠 Integration Requirements

### Permission Key Registry (Full List)
Frontend implementations of the `AdminShell` must map navigation to these specific backend keys in your `AdminService` and `AuthProvider`:
- `view_dashboard`, `view_revenue`, `manage_transactions`, `export_reports`, `manage_disputes`, `manage_fees`, `freeze_account`, `manage_announcements`, `manage_manual_payouts`, `query_mpesa_receipt`, `configure_otp`, `manage_webhooks`, `view_system_health`, etc.

### API Connectivity
- **Base URL**: `https://api.escrow.pesacrow.top/api`
- **Auth**: Always include `Authorization: Bearer {{adminToken}}` for protected routes.
- **SSE Connection**: Maintain `GET /admin/events` for real-time dashboard reactivity.
