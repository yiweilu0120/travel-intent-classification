# travel-intent-classification
End-to-end machine learning solution for travel intent classification built on session-level features, covering large-scale ETL pipelines, feature engineering, model training, and deployment.

## Table of Contents

- [1. Project Background](#1-project-background)
  - [Current Rule-based Travel Intent Classification System](#current-rule-based-travel-intent-classification-system)
  - [User Research on Travel and Necessary-purpose Intent](#user-research-on-travel-and-necessary-purpose-intent)
- [2. Travel Intent Classification Model Upgrade Plan](#2-travel-intent-classification-model-upgrade-plan)
  - [Objective](#objective)
  - [Development Plan](#development-plan)
  - [Travel Behavior Feature Engineering](#travel-behavior-feature-engineering)
  - [User Behavior Tracking Mechanism](#user-behavior-tracking-mechanism)
  - [Model Training and Evaluation](#model-training-and-evaluation)
  - [Data Warehouse Deployment](#data-warehouse-deployment)
- [Related Resources](#related-resources)
- [Terminology](#terminology)

---

# 1. Project Background

## Current Rule-based Travel Intent Classification System

The previous version of the **STP (Travel Intent Classification Model)** classified user travel intent based on three manually defined rules:

- Destination
- Travel distance
- Travel date

### 1. Leisure Travel Intent

Users were classified as having **leisure travel intent** if:

- The destination was a **tourism-oriented city** or a **tourism-related urban AOI**, and the travel distance was greater than 50 km.

- The destination was a **non-tourism urban AOI** or a **non-tourism city**, the check-in date fell on a weekend or public holiday, and the travel distance was greater than 50 km.

### 2. Necessary-purpose Intent

Users were classified as having **necessary-purpose intent** if:

- **Inter-city necessary travel**:
  - The trip was not classified as leisure travel, and the travel distance was greater than 50 km.

- **Local necessary travel**:
  - The trip was neither leisure travel nor inter-city necessary travel.

> ⚠️ **Key Limitation:**  
> The previous version classified all trips within 50 km as local necessary travel, leading to systematic under-identification of leisure travel.
>
> User interviews showed that travel intent is not determined by distance alone. Local leisure activities, such as nearby hot spring trips and city camping, are still perceived by users as leisure travel.

---

## User Research on Travel and Necessary-purpose Intent

### Definition and Scenario Framework

Based on previous user research and business experience, initial definitions and scenario hypotheses were developed. After validation and iteration through user interviews, the following intent framework was established.

### Necessary-purpose Intent

**Necessary-purpose intent** refers to travel where completing an essential task or obligation is the primary goal.

Typical scenarios include:

- Business trips
- Conferences and training
- Medical visits
- Exams and interviews
- Visiting family or friends
- Weddings, funerals, and other ceremonies

### Leisure Travel Intent

**Leisure travel intent** refers to travel without mandatory task pressure, where the primary goals are:

- Relaxation and recovery
- Exploration and experiences
- Social and emotional fulfillment

Leisure travel is not limited to inter-city trips; local leisure activities are also included.

Typical scenarios include:

- Inter-city sightseeing
- Local wellness trips (camping, self-driving trips, hot springs)
- Family and parent-child vacations
- Couple trips
- Friend gatherings
- Concerts and sporting events
- Popular destination visits
- Long-stay travel and slow travel
- Wellness vacations
- Traveling with pets

---

## Distribution Analysis

### Intent Distribution by Date Type

| Date Type | Leisure Travel Share |
|---|---:|
| Public Holidays | 68% |
| Weekends | 60% |
| Weekdays | 32% |

---

### Leisure Travel Scenario Distribution

| Scenario | Share |
|---|---:|
| Weekend / Short Holiday Nearby Trips | 18.8% |
| Local / City Leisure Activities | 18.5% |
| Couple City Trips | 15.7% |
| Long-distance Trips with Friends | 15.2% |
| Long-distance Family / Parent-child Trips | 9.2% |
| Business Trips with Leisure Activities | 7.7% |
| Visiting Hometown / Relatives with Leisure Activities | 5.1% |
| Group Family Trips with Friends | 4.1% |
| Anniversary / Special Event Trips | 3.2% |
| Long-stay Travel / Slow Travel | 2.2% |

---

### Necessary-purpose Scenario Distribution

| Scenario | Share |
|---|---:|
| Business Trips / Conferences / Training | 46.6% |
| Visiting Family or Friends (Primary Purpose: Visiting) | 13.5% |
| Weddings / Funerals and Other Ceremonies | 12.4% |
| Business Trips with Leisure Activities | 10.1% |
| Exams / Interviews | 9.7% |
| Medical Visits / Accompanying Patients | 5.9% |
| Moving / Temporary Accommodation | 1.8% |

# 2. Travel Intent Classification Model Upgrade Plan

## Objective

Build a **behavior-based Travel Intent Classification Model** to replace the existing rule-based classification system, covering the entire user journey from **user visit (UV) to payment conversion**.

The model aims to identify whether a user session represents **leisure travel intent** or **necessary-purpose intent** by leveraging multi-dimensional behavioral signals.

---

## Development Plan

User intent is often expressed outside the platform, while existing in-platform product interactions lack sufficient intent signals.

Therefore, in the short term, the model leverages existing platform features, including:

- Temporal features
- Spatial features
- User profile features
- Product features
- Behavioral sequences
- Cross-business interactions

Combined with session-level user behavior analysis, the model focuses on building a **Travel Intent Classification Model** based on in-platform behavioral signals.

---

## Model Architecture

The intent recognition framework consists of three layers:

| Layer 1: User Demand Layer | Layer 2: Intent Expression Layer | Layer 3: In-platform Capture Layer |
|---|---|---|
| Travel / necessary-purpose demand (including pseudo-intents, such as merchants monitoring their own or competitors' prices, which require future filtering) | Off-platform expressions (approximately 30% of research samples showed sparse in-platform behavior) | — |
| — | In-platform expressions | User intent signals not captured due to limitations of general product flows |

### Current Focus

This iteration focuses on the **in-platform capture layer**.

The model integrates multi-dimensional data, including:

- Time
- Location
- Product information
- User profile
- Behavioral sequences
- Cross-business activities

to identify user travel intent.

The model only addresses **behavior-level intent classification**. When behavioral intent differs from underlying motivation, external information is required for further correction.

**Example:**

A user visiting Jiuhua Mountain for religious purposes:

- Motivation level: necessary-purpose intent
- Behavioral level: leisure travel intent

---

# Travel Behavior Feature Engineering

At the **session level**, model input features are constructed from multiple dimensions:

- Time
- Location
- Product
- User profile
- Decision-making behavior
- Cross-business/platform behavior

| Category | Sub-category | Features |
|---|---|---|
| **Time** | Check-in Date Type | Public holiday / Weekend / Summer vacation / Weekday |
| | Booking Behavior | Advance booking days |
| **Location** | City Type | City tier: Tier 1 / New Tier 1 / Tier 2 / Tier 3 / Tier 4 / Tier 5 and below; Tourism characteristics: tourism-dependent city / large-scale tourism revenue city / seasonal tourism city / non-tourism city |
| | AOI Type | Scenic spots / Transportation hubs / Universities / Hospitals / Sports & cultural venues / Convention centers / Industrial parks, etc. |
| | Travel Distance | Distance between origin and destination |
| **Product** | POI Type | POI rating: 0-2 stars / 3 stars / 4 stars / 5 stars; POI category: economy / business / themed / couple / apartment / homestay / resort hotel / villa / family-friendly / esports; POI quality: scarce resources / differentiated quality / low-price homogeneous products; high-quality vs. standard products |
| | Goods Type | King room / Single room / Double room / Triple room / Suite / Standard room / Dormitory-style room |
| **User** | Demographics | Age group: minor / young adult / middle-aged / senior; Family status: single / married without children / married with children |
| | User Value | User value segment: high / medium / low; Membership level: L1-L3 / L4+ |
| | User Segment | Campus youth / Business professionals / Social lifestyle users / Practical consumers / Family caregivers / Adventure travelers / Quality slow travelers / Family explorers / Occasional travelers |
| **Decision Behavior** | Browsing Behavior | Total browsing duration; page-level visits and duration: search page / POI list page / POI detail page / Goods list page / Goods detail page / Order creation page / Review page |
| | Search Behavior | Searches for scenic spots vs. non-scenic spots |
| **Cross-business / Platform** | Ticketing & Vacation | Ticketing and vacation-related behaviors |
| | External Traffic Source | Traffic from Xiaohongshu |

---

# User Behavior Tracking Mechanism

## Motivation

Users may conduct long-term travel planning but complete booking within a short period, which can lead to incorrect intent classification when analyzing individual sessions independently.

To address this issue, a cross-session tracking mechanism was introduced.

---

## Session Aggregation Strategy

Multiple sessions belonging to the same travel demand are aggregated into a **session bundle**.

All aggregated behavioral features are combined and fed into the model for unified intent prediction.

The predicted intent label is then propagated back to all associated `session_id`s.

---

## Tracking Rules

For sessions belonging to the same user:

1. **Overlapping Check-in Dates**
   - Two sessions have overlapping check-in dates.

2. **Same Holiday Period**
   - Two sessions' check-in dates belong to the same public holiday.

3. **Check-in Date Difference ≤ 1 Day + Same City**
   - The difference between check-in dates is within 1 day, and the destination city is identical.

4. **Check-in Date Difference ≤ 3 Days + Same POI**
   - The difference between check-in dates is within 3 days, and the POI is identical.

---

## Tracking Time Window

- Weekdays and weekends:
  - Look back 14 days

- Public holidays:
  - Look back 30 days
 
# Model Training and Evaluation

## Training Data Construction

Training samples were constructed based on post-consumption user review orders by integrating multi-dimensional behavioral and user information.

### Label Sources

- **TravelType User-provided Labels**
  - User-declared travel purposes, including business trips, family trips, couple trips, friend trips, and other travel categories.

- **Review Intent Mining**
  - Natural Language Processing (NLP) was applied to analyze user review semantics and extract travel purpose signals.

Two major categories of training samples were constructed:

- **Necessary-purpose Intent**
  - Business trips
  - Exams
  - Medical visits
  - Other essential-purpose scenarios

- **Leisure Travel Intent**
  - Family and parent-child trips
  - Couple vacations
  - Friend gatherings
  - Concerts and entertainment events
  - Other leisure scenarios

---

## Model Algorithm

The model uses **LightGBM (Light Gradient Boosting Machine)** to perform binary classification at the session level, predicting whether a user session represents:

- **Leisure travel intent**
- **Necessary-purpose intent**

### Core Principle

LightGBM builds multiple decision trees sequentially. Each new tree focuses on correcting the prediction errors from previous trees by learning residuals.

Through iterative optimization, the model gradually reduces prediction errors. The final classification result is obtained by combining the weighted outputs of all decision trees.

---

# Feature Correlation Analysis and Business Interpretation

## Leisure Travel Intent

### Spatial Features

Leisure travelers show stronger interest in tourism-related locations.

Scenic spot AOI features are among the most significant factors:

- Whether the user booked a scenic spot AOI: **0.328**
- Number of scenic spot AOI views: **0.224**

### Temporal Features

Leisure travelers tend to plan trips around holidays and weekends in advance:

- Whether the user booked holidays/weekends in advance: **0.265**
- Number of views for holiday/weekend check-in dates: **0.256**

### Decision Behavior Features

Leisure travelers typically have longer decision-making processes and deeper browsing behavior:

- AOI page views: **0.235**
- POI page views: **0.225**
- Goods page views: **0.205**
- Total browsing duration: **0.194**

### Cross-business Features

Hotel bookings combined with ticketing and vacation-related activities are strong indicators:

- Whether the user browsed ticketing/vacation products: **0.252**

---

## Necessary-purpose Intent

### User Profile Features

Necessary-purpose travelers tend to have more mature and business-oriented user profiles:

- Business professional segment: **-0.306** (strongest negative correlation)
- High-value users: **-0.181**
- Middle-aged users: **-0.170**
- L4+ membership users: **-0.063**

### Temporal Features

Necessary-purpose travelers often book temporarily on weekdays with shorter decision cycles:

- Same-day weekday booking: **-0.289**

### Spatial Features

Necessary-purpose travelers tend to choose hotels located near functional destinations:

- Hospital AOI views: **-0.102**
- University AOI views: **-0.101**
- Transportation hub AOI views: **-0.097**

### Product Features

Necessary-purpose travelers show stronger preference for individual accommodation:

- Booking king rooms: **-0.110**
- Booking single rooms: **-0.086**

> **Note:** Correlation does not equal model feature importance.  
> Correlation only reflects linear relationships, while the model can capture nonlinear patterns and feature interactions through its tree-based structure.

---

# Model Performance

## Classification Results

| Class | Precision | Recall | F1-score |
|---|---:|---:|---:|
| Necessary-purpose Intent | 0.81 | 0.84 | **0.82** |
| Leisure Travel Intent | 0.87 | 0.84 | **0.86** |
| **Accuracy** | **0.84** | | |

The model achieved:

- **Overall accuracy: 0.84**
- **F1-score: 0.82 for necessary-purpose intent**
- **F1-score: 0.86 for leisure travel intent**

The model demonstrates strong classification performance across both intent categories.

---

# User Research Consistency Evaluation

The predicted intent labels from the Travel Intent Classification Model were compared against user interview results.

Initial matching accuracy between:

- User-reported travel intent
- Model-predicted intent

was **70%**.

After manually reviewing inconsistent cases, most mismatches were found to be caused by:

- Separation between user motivation and observed behavior
- Insufficient in-platform signals

rather than incorrect model predictions.

After validation, the matching accuracy increased to **80%**.

---

## Error Analysis Distribution

| Category | Count | Share |
|---|---:|---:|
| Not a model error (behavior and motivation mismatch) | 9 | 64.3% |
| Model classification error | 2 | 14.3% |
| Mixed leisure and necessary-purpose demand | 1 | 7.1% |
| Unable to determine (insufficient in-platform signals) | 2 | 14.3% |

---

# Data Warehouse Deployment

The **Travel Intent Classification Model** has been deployed across the complete user journey from **user visit (UV) to payment conversion**.

Intent labels are directly integrated into core traffic and order data warehouse tables:

- **Traffic Intent Table**
  - `app_hotel.dws_log_pv_stp_di`

- **Order Intent Table**
  - `app_hotel.dws_log_order_trade_stp_di`

> **Note:**  
> Due to the cross-session tracking mechanism, historical records within the previous 30 days may be updated. The expected change rate is approximately **4%**.

---

# Related Resources

- [STP Definition: Travel and Necessary-purpose Scenario Research Report](https://km.sankuai.com/collabpage/2756685709)
- [User Travel / Necessary-purpose Sample Collection Results (0610)](https://km.sankuai.com/collabpage/2767367001)
- [Training Dataset V3](https://km.sankuai.com/collabpage/2771389860)
- [STP Algorithm Model Documentation](https://km.sankuai.com/collabpage/2772429500)

---

# Terminology

| Term | Description |
|---|---|
| Session | A user visit session identifier. All user activities from opening the app until closing the app (or timing out after inactivity) belong to the same `session_id`. |
| LightGBM | Light Gradient Boosting Machine, an efficient gradient boosting decision tree framework optimized for training speed, memory usage, and high-dimensional feature processing. |
| AOI | Area of Interest, a geographic region representing a specific area or destination type. |
| POI | Point of Interest, referring to hotel merchants or accommodation locations in this project. |
| Goods | Hotel room products, including different room types and packages. |
