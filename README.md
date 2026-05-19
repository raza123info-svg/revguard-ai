# RevGuard AI — Autonomous Revenue Protection Agent

RevGuard AI is a state-of-the-art autonomous revenue protection mobile and desktop dashboard designed for retail and wholesale businesses in Pakistan. It defends inventories and revenue by analyzing supply chain blockages, consumer demand spikes, supplier failures, and budget constraints across an 8-stage sequential reasoning agent pipeline.

---

## 🚀 8-Stage Autonomous Pipeline

The engine executes 8 distinct tools sequentially to validate risk and suggest immediate actions:

1. **Tool 1: News Service (`NewsAPI`)**: Fetches supply chain, transit, and logistics headlines for the Pakistani region matching the target product.
2. **Tool 2: Warehouse Stock Parser**: Examines stock levels and checks database update dates. Sets `STALE` if the database has not refreshed within 48 hours.
3. **Tool 3: Sales Velocity Analyser**: Detects demand spikes. Flags `CRITICAL` warnings if the current demand surpasses twice the baseline average.
4. **Tool 4: Supplier Reliability Reader**: Audits the supplier's reliability database and checks for active delay flags.
5. **Tool 5: Complaints Spike Processor**: Normalizes incoming customer complaint frequency against a historical baseline (6 cases/day) to capture local stockout reports.
6. **Tool 6: Contradiction Engine**: Assigns credibility scores to channels based on date freshness and overrides low-confidence positive reports with high-confidence negative alerts.
7. **Tool 7: Constraint Engine**: Ensures any suggested purchase order cost stays within a strict **PKR 500,000** limit. Trims quantities recursively by 5% until the proposal is compliant.
8. **Tool 8: Gemini 1.5 Flash AI Reasoning**: Combines the structured findings of Tools 1-7, evaluates threats, and generates a 5-step serialized action chain in JSON.

---

## 📊 File Format Schemas

To upload custom business streams, format your files as follows:

### 1. `warehouse.csv`
```csv
units_available,Last_Updated,location
500,2026-05-19 14:00:00,Karachi Store
```

### 2. `sales.csv`
```csv
date,demand_units,Demand_Trend
2026-05-18,200,NORMAL
2026-05-19,880,CRITICAL
```

### 3. `supplier.json`
```json
{
  "supplier_name": "Karachi Logistics Partner",
  "reliability_score": 43,
  "delay_alert": true
}
```

### 4. `complaints.csv`
```csv
date,complaint_count,severity
2026-05-19,47,HIGH
```

---

## 🛠️ Project Setup & Launch

### Prerequisites
- Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (Flutter 3.41+ / Dart 3.11+).

### Environment Setup
Create a `.env` file in the root of the project with your API credentials (pre-filled inside the repository):
```env
GEMINI_KEY=AIzaSyCSVSJj2cS_UZg5CAKgG9FGpjO5son-HbI
NEWSAPI_KEY=fb33cad4e15243b5ae01bb5ca8510c7e
```

### Commands
Get dependencies:
```bash
flutter pub get
```

Run the application:
```bash
flutter run
```

Build for Web:
```bash
flutter build web
```
