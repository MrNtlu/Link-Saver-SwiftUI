# Link Saver - Project Guidelines

## Overview
iOS Link Saver app with offline URL storage, metadata previews, folder/tag organization, and Share Extension support. Targets iOS 18+ with conditional Liquid Glass UI for iOS 26+.

## Tech Stack
- **Language**: Swift 6
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Minimum iOS**: 18.0
- **Liquid Glass**: iOS 26+ (conditional)

## Project Structure

```
Link Saver/
├── App/
│   ├── Link_SaverApp.swift           # App entry point
│   └── AppConstants.swift            # App Group ID, constants
│
├── Models/
│   ├── Link.swift                    # Link SwiftData model
│   ├── Tag.swift                     # Tag SwiftData model
│   ├── Folder.swift                  # Folder SwiftData model
│   └── ModelContainerFactory.swift   # Shared container for App Groups
│
├── Views/
│   ├── MainTabView.swift             # Root TabView
│   ├── Links/                        # Links tab views
│   ├── Folders/                      # Folders tab views
│   ├── Settings/                     # Settings tab views
│   └── Components/                   # Reusable UI components
│
├── Services/
│   ├── MetadataService.swift         # LPMetadataProvider wrapper
│   └── LinkImportService.swift       # URL parsing/validation
│
├── Utilities/
│   └── Extensions/                   # Swift extensions
│
└── Assets.xcassets/

LinkSaverShareExtension/              # Share Extension target
├── ShareViewController.swift
├── ShareView.swift
├── Info.plist
└── Action.js
```

## Architecture Principles

### 1. MVVM Pattern
- Views observe SwiftData models directly via `@Query`
- Use `@Bindable` for two-way binding to model properties
- Services are actors for thread-safe async operations

### 2. SwiftData Best Practices
- Use `@Model` macro for all data models
- Use `@Attribute(.externalStorage)` for large Data (images > 100KB)
- Use `@Relationship` with explicit inverse relationships
- Share ModelContainer via App Groups for Share Extension

### 3. iOS Version Handling
Always use conditional compilation for iOS 26 features:
```swift
if #available(iOS 26, *) {
    // Liquid Glass implementation
} else {
    // Fallback for iOS 18-25
}
```

## Coding Standards

### Naming Conventions
- **Views**: `[Feature]View.swift` (e.g., `LinksView.swift`)
- **Components**: Descriptive name (e.g., `TagChip.swift`)
- **Models**: Singular noun (e.g., `Link.swift`)
- **Services**: `[Feature]Service.swift` (e.g., `MetadataService.swift`)

### SwiftUI Guidelines
- Prefer `NavigationStack` over `NavigationView`
- Use `@Environment(\.modelContext)` for data operations
- Extract reusable views into Components/
- Use SF Symbols for icons

### Theming (Light/Dark)
- **Default**: Light (overrides system appearance until user changes it)
- **Preference storage**: `@AppStorage(ThemePreferences.key, store: ThemePreferences.store)` (App Group `UserDefaults`, falls back to standard defaults if needed)
- **Global application**: `Link Saver/App/Link_SaverApp.swift` applies `.preferredColorScheme(...)` so changes update live without relaunch
- **Settings UI**: `Link Saver/Views/Settings/SettingsView.swift` → `Appearance` section with a Light/Dark segmented picker
- **Style rule**: Prefer semantic colors/materials (`.primary`, `.secondary`, system backgrounds) and avoid hard-coded `.white/.black` so both themes stay correct

### Localization & Translation
- **Source of truth**: `Link Saver/Localization/Localizable.xcstrings` (String Catalog).
- **No hard-coded UI text**: All user-facing strings must use `LocalizedStringKey` (SwiftUI `Text("key")`, `Button("key")`) or `String(localized:)` for non-SwiftUI contexts.
- **Supported languages**: Must include translations for every language in `Link Saver/App/AppLanguage.swift` (`de`, `en`, `es-ES`, `es-419`, `fr`, `ja`, `ko`, `pt-BR`, `tr`, `zh-Hans`, `zh-Hant`).
- **Key naming**: Use stable, descriptive dot-separated keys (e.g. `onboarding.page.share.title`), never embed English in keys.
- **Editing rules**:
  - When adding a key, add all localizations in the same change (do not land partial translations).
  - Prefer reusing existing phrasing and terminology across features (e.g. “Links”, “Folders”, “Tags”, “Share”).
  - Keep strings short and UI-friendly; avoid trailing punctuation unless it’s part of the sentence.
- **Behavior**:
  - App language is controlled via `@AppStorage(LanguagePreferences.key, store: LanguagePreferences.store)` and applied globally in `Link Saver/App/Link_SaverApp.swift`.
  - Onboarding should respect the selected language immediately (apply `.environment(\\.locale, ...)` inside onboarding if needed).
- **Verification**: Before merging, ensure every key has every supported localization. Quick check:
```bash
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("Link Saver/Localization/Localizable.xcstrings").read_text())
langs = ["de", "en", "es-ES", "es-419", "fr", "ja", "ko", "pt-BR", "tr", "zh-Hans", "zh-Hant"]
missing = []

for key, entry in data.get("strings", {}).items():
    locs = entry.get("localizations")
    if not locs or "en" not in locs:
        continue
    miss = [lang for lang in langs if lang not in locs]
    if miss:
        missing.append((key, miss))

print("missing:", len(missing))
for key, miss in missing[:25]:
    print(key, miss)
PY
```

### Error Handling
- Use `Result` type or `throws` for error propagation
- Never crash on recoverable errors
- Show user-friendly error messages

## Liquid Glass Design System

### When to Use Glass Effects
- Navigation bars and toolbars
- Tab bars and bottom accessories
- Floating action buttons
- Sheets, popovers, and menus

### When NOT to Use Glass Effects
- Content layer (lists, tables, media)
- Full-screen backgrounds
- Scrollable content
- Stacked glass layers (no glass on glass)

### Key APIs (iOS 26+)
```swift
// Basic glass effect
.glassEffect(.regular)

// Interactive glass (for buttons)
.glassEffect(.regular.interactive())

// Tinted glass
.glassEffect(.regular.tint(.blue))

// Grouped glass elements
GlassEffectContainer {
    // Child views with .glassEffect()
}

// Morphing transitions
.glassEffectID("id", in: namespace)
```

### Fallback Pattern (iOS 18-25)
```swift
extension View {
    @ViewBuilder
    func conditionalGlassEffect() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular.interactive())
        } else {
            self.background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
```

## Tab Bar Implementation

### iOS 26+ (Liquid Glass)
```swift
TabView {
    Tab("Links", systemImage: "link", value: 0) {
        LinksView()
    }
    Tab("Folders", systemImage: "folder", value: 1) {
        FoldersView()
    }
    Tab("Settings", systemImage: "gear", value: 2) {
        SettingsView()
    }
}
.tabViewBottomAccessory {
    // Floating plus button
}
.tabBarMinimizeBehavior(.onScrollDown)
```

### iOS 18-25 (Legacy)
```swift
TabView {
    LinksView()
        .tabItem { Label("Links", systemImage: "link") }
        .tag(0)
    // ...
}
// Use ZStack overlay for floating button
```

## Data Models

### Link
- `id: UUID` - Unique identifier
- `url: String` - The saved URL
- `title: String?` - Page title from metadata
- `linkDescription: String?` - Page description
- `favicon: Data?` - Cached favicon image
- `previewImage: Data?` - Cached preview image
- `dateAdded: Date` - Creation timestamp
- `isFavorite: Bool` - Favorite flag
- `folder: Folder?` - Parent folder (optional)
- `tags: [Tag]` - Associated tags
- `metadataFetched: Bool` - Metadata fetch status

### Tag
- `id: UUID` - Unique identifier
- `name: String` - Tag name
- `colorHex: String` - Color as hex string
- `dateCreated: Date` - Creation timestamp

### Folder
- `id: UUID` - Unique identifier
- `name: String` - Folder name
- `iconName: String` - SF Symbol name
- `dateCreated: Date` - Creation timestamp
- `links: [Link]` - Contained links

## Share Extension

### App Group ID
`group.linksaver.share`

### Required Capabilities
1. App Groups (both targets)
2. Share Extension activation rules for web URLs

### URL Extraction
Use Action.js for Safari integration to extract:
- Page URL
- Page title
- Selected text (optional)

## Testing Checklist

### Core Functionality
- [ ] Add link manually
- [ ] Add link via Share Extension
- [ ] View link preview (favicon + metadata)
- [ ] Create/edit/delete folders
- [ ] Create/edit/delete tags
- [ ] Assign links to folders
- [ ] Assign tags to links
- [ ] Search links
- [ ] Filter by tags
- [ ] Sort links

### iOS Version Testing
- [ ] iOS 18 - Basic functionality
- [ ] iOS 26 - Liquid Glass effects

### Offline Testing
- [ ] Links viewable offline
- [ ] Cached images display offline
- [ ] Metadata retry when online

## Performance Guidelines

### Images
- Compress JPEG to 70% quality
- Limit preview images to 300x300 max
- Use `.externalStorage` for images > 100KB
- Provide placeholders for missing images

### Lists
- Use `LazyVStack` in ScrollView for large lists
- Implement pagination if > 100 items
- Use `@Query` predicates to filter at database level

## Dependencies
**None** - Uses only Apple frameworks:
- SwiftUI
- SwiftData
- LinkPresentation
- UniformTypeIdentifiers

# Working on Tasks
You are expert on iOS/Swift UI Engineering.
Read the apple docs via sosumi mcp or internet.
When you are working on a task, separate it into small pieces, go small task by task, after you finish each task, double check your implementation and when you validate, continue to the next one.
When you finish the task, build and run tests via XcodeBuildMCP.