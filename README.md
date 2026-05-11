# NutritionTracker

A SwiftUI nutrition-planning iOS app: targets, weekly meal plan, grocery list,
meal-prep scheduling, and "what to cook now". Built deterministically in Swift —
AI is used only for food research, suggestions, substitutions, and parsing free-text
preferences. Every AI response is parsed into a Codable struct and validated before
use.

## Tech stack

- Swift 5, SwiftUI, SwiftData (iOS 17+)
- UserNotifications for reminders
- `AIProvider` protocol with a `MockAIProvider` (swap in OpenAI/Claude later)

## What's in the repo

```
NutritionTracker.xcodeproj/        # Xcode project (filesystem-synchronized groups)
NutritionTracker/
├── NutritionTrackerApp.swift      # @main entry, ModelContainer schema
├── Models/                        # 11 @Model classes + NutritionFacts
├── Services/                      # NutritionCalculator, MealPlanner, etc.
├── AI/                            # AIProvider protocol + MockAIProvider + FoodResearchService
├── ViewModels/                    # DashboardViewModel
├── Views/                         # 7 MVP screens + RootTabView + shared components
├── SeedData/                      # Seed foods, meal templates, user profile
├── Utils/                         # Date+formatting helpers, AppEnvironment DI
├── Assets.xcassets/               # AccentColor, AppIcon set
└── Preview Content/               # Preview assets
```

## MVP screens

1. **Dashboard** — today's plan, next meal, remaining macros, prep + grocery alerts
2. **Targets** — age, sex, height, weight, BMR, calorie/protein/fiber/sugar/sodium targets, workout schedule
3. **Preferences** — proteins/avoided/dairy/fruits/legumes/supplements + AI free-text parser
4. **Weekly Plan** — 7-day plan with macro validation per day; tap to swap a meal; regenerate
5. **Grocery List** — aggregated from the plan minus current inventory; check off buys (auto-adds to inventory)
6. **Meal Prep** — Sunday prep (Sun–Wed) + Wednesday prep (Thu–Sat) with container-by-container steps
7. **Cook Today** — pulls the next uncooked meal for the current time-of-day window, shows ingredients, steps, and AI substitution suggestions

## Planner algorithm (deterministic, in Swift)

1. Load user profile + targets + preferences + inventory
2. Lock fixed breakfast if there is exactly one allowed
3. Generate lunch × dinner pairings; apply hard constraints (calorie envelope, protein min, sugar/sodium max, red-meat cap, egg cap, fiber floor)
4. Score valid pairings on calorie distance, protein band, fiber band, sugar headroom, volume preference, effort match, inventory reuse, variety
5. Pick highest score per day; fall back gracefully if no pairing passes
6. Aggregate ingredients into grocery list, subtracting inventory
7. Split prep into Sun (covers Sun–Wed) and Wed (covers Thu–Sat) sessions
8. Schedule local notifications for prep + cook + expiring inventory

## AI boundaries

AI **can** research nutrition, suggest meals, suggest substitutions, parse free-text preferences. AI **cannot** silently change targets, edit inventory, produce final plans without validation, decide reminders, override hard constraints, or be the only source of macro math.

Every AI DTO (`AIResearchResponse`, `AISuggestionResponse`, `AISubstitutionResponse`, `AIPreferenceParseResponse`) is a `Codable` struct. `FoodResearchService.validate(_:)` rejects bogus numbers (negative, >1000 kcal per 100g, etc.). The view layer merges AI output only after this validation pass.

## Build & run

```sh
open NutritionTracker.xcodeproj
# Pick an iPhone simulator and run.
```

### Note on Xcode 26 + iOS 26 simulator runtime

This Mac has Xcode 26 but no iOS 26 simulator runtime installed. From the command line, `xcodebuild` cannot finish the asset-thinning step against an older simulator runtime when the SDK is iOS 26. Two options:

- **Xcode IDE**: open the project, pick an iOS 17/18 simulator, and run — Xcode's IDE handles the runtime mismatch.
- **Install the iOS 26 simulator runtime** (Xcode → Settings → Components → iOS 26) to fully enable `xcodebuild`.

The Swift module is verified to compile clean against the iOS simulator SDK (zero errors, zero warnings) via:

```sh
xcrun -sdk iphonesimulator swiftc \
  -target arm64-apple-ios17.0-simulator \
  -typecheck \
  -module-name NutritionTracker \
  $(find NutritionTracker -name "*.swift")
```

## Seed profile

The bundled seed matches the spec:

- 1800 kcal/day, 100–120 g protein, 35–38 g fiber, <10 g sugar, ≤2300 mg sodium
- Max 3 meals/day, morning workout (Mon–Fri), recomp goal, low-volume meals
- Proteins: chicken, salmon, cod, shrimp; ≤1 red-meat day/week
- Greek yogurt, 2 whole eggs/day max, no egg whites
- Protein powder + 5 g creatine
- Raspberries, blackberries, chickpeas, black beans
- Sunday + Wednesday prep
