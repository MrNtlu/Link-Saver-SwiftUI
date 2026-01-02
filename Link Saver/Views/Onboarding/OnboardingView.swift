//
//  OnboardingView.swift
//  Link Saver
//
//  Created by Codex on 2026/01/01.
//

import SwiftUI

private enum OnboardingStep: Int, CaseIterable, Identifiable {
    case preferences
    case save
    case folders
    case tags
    case find

    var id: Int { rawValue }

    var systemImage: String {
        switch self {
        case .preferences: return "slider.horizontal.3"
        case .save: return "square.and.arrow.up"
        case .folders: return "folder"
        case .tags: return "tag"
        case .find: return "magnifyingglass"
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .preferences: return "onboarding.page.preferences.title"
        case .save: return "onboarding.page.share.title"
        case .folders: return "onboarding.page.folders.title"
        case .tags: return "onboarding.page.tags.title"
        case .find: return "onboarding.page.find.title"
        }
    }

    var bodyKey: LocalizedStringKey {
        switch self {
        case .preferences: return "onboarding.page.preferences.body"
        case .save: return "onboarding.page.share.body"
        case .folders: return "onboarding.page.folders.body"
        case .tags: return "onboarding.page.tags.body"
        case .find: return "onboarding.page.find.body"
        }
    }

    var bulletKeys: [LocalizedStringKey] {
        switch self {
        case .preferences:
            return []
        case .save:
            return [
                "onboarding.page.share.bullet1",
                "onboarding.page.share.bullet2",
                "onboarding.page.share.bullet3"
            ]
        case .folders:
            return [
                "onboarding.page.folders.bullet1",
                "onboarding.page.folders.bullet2"
            ]
        case .tags:
            return [
                "onboarding.page.tags.bullet1",
                "onboarding.page.tags.bullet2"
            ]
        case .find:
            return [
                "onboarding.page.find.bullet1",
                "onboarding.page.find.bullet2"
            ]
        }
    }
}

struct OnboardingView: View {
    let onFinished: () -> Void

    @State private var pageIndex: Int = 0
    @State private var isThemePickerPresented: Bool = false
    @State private var isLanguagePickerPresented: Bool = false

    @AppStorage(ThemePreferences.key, store: ThemePreferences.store)
    private var themeRawValue: String = ThemePreferences.defaultTheme.rawValue

    @AppStorage(LanguagePreferences.key, store: LanguagePreferences.store)
    private var languageRawValue: String = LanguagePreferences.defaultLanguage.rawValue

    private var selectedTheme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: themeRawValue) ?? ThemePreferences.defaultTheme },
            set: { themeRawValue = $0.rawValue }
        )
    }

    private var selectedLanguage: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage(rawValue: languageRawValue) ?? LanguagePreferences.defaultLanguage },
            set: { languageRawValue = $0.rawValue }
        )
    }

    private let steps = OnboardingStep.allCases

    private var isLastPage: Bool {
        pageIndex == steps.count - 1
    }

    private var isPreferencesPage: Bool {
        pageIndex == OnboardingStep.preferences.rawValue
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $pageIndex) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        stepView(step)
                            .tag(index)
                            .padding(.horizontal, 24)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                footer
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
            .navigationTitle(Text("onboarding.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isLastPage && !isPreferencesPage {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("onboarding.button.skip") {
                            onFinished()
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled(true)
        .environment(\.locale, selectedLanguage.wrappedValue.locale)
        .preferredColorScheme(selectedTheme.wrappedValue.colorScheme)
    }

    @ViewBuilder
    private func stepView(_ step: OnboardingStep) -> some View {
        switch step {
        case .preferences:
            preferencesView
        case .save, .folders, .tags, .find:
            infoPageView(step)
        }
    }

    private func infoPageView(_ step: OnboardingStep) -> some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)

            Image(systemName: step.systemImage)
                .font(.system(size: 72, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .padding(.bottom, 8)

            Text(step.titleKey)
                .font(.title.weight(.semibold))
                .multilineTextAlignment(.center)

            BulletCards(bulletKeys: step.bulletKeys)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 8)
    }

    private struct BulletCards: View {
        let bulletKeys: [LocalizedStringKey]

        var body: some View {
            VStack(spacing: 12) {
                ForEach(Array(bulletKeys.enumerated()), id: \.offset) { _, bulletKey in
                    bulletRowCard(bulletKey)
                }
            }
            .frame(maxWidth: .infinity)
        }

        private func bulletRowCard(_ bulletKey: LocalizedStringKey) -> some View {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)
                    .font(.system(size: 18, weight: .semibold))

                Text(bulletKey)
                    .font(.callout.weight(.regular))
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.secondary.opacity(0.18), lineWidth: 1)
            )
        }
    }

    private func preferenceRow(titleKey: LocalizedStringKey, systemImage: String, value: Text) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .frame(width: 22)

            Text(titleKey)
                .font(.subheadline.weight(.semibold))

            Spacer(minLength: 12)

            value
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .font(.callout)

            Image(systemName: "chevron.up.chevron.down")
                .foregroundStyle(.tertiary)
                .font(.caption.weight(.semibold))
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.secondary.opacity(0.18), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }

    private var preferencesView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)
            
            Image("linksaver-icon")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.secondary.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
                .accessibilityHidden(true)

            Text("onboarding.welcome.title")
                .font(.largeTitle.weight(.semibold))
                .multilineTextAlignment(.center)

            Text("onboarding.welcome.subtitle")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .font(.body)

            VStack(spacing: 14) {
                Button {
                    isThemePickerPresented = true
                } label: {
                    preferenceRow(
                        titleKey: "settings.theme",
                        systemImage: "paintbrush",
                        value: Text(selectedTheme.wrappedValue.displayNameKey)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    isLanguagePickerPresented = true
                } label: {
                    preferenceRow(
                        titleKey: "settings.language",
                        systemImage: "globe",
                        value: Text(selectedLanguage.wrappedValue.displayNameKey)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 10)
            .sheet(isPresented: $isThemePickerPresented) {
                OnboardingThemePickerView(selection: selectedTheme)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $isLanguagePickerPresented) {
                OnboardingLanguagePickerView(selection: selectedLanguage)
                    .presentationDetents([.medium, .large])
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 8)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if pageIndex > 0 {
                Button("onboarding.button.back") {
                    withAnimation {
                        pageIndex -= 1
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Spacer()

            let primaryTitle: LocalizedStringKey = {
                if isLastPage { return "onboarding.button.getStarted" }
                if isPreferencesPage { return "onboarding.button.continue" }
                return "onboarding.button.next"
            }()

            Button(primaryTitle) {
                if isLastPage {
                    onFinished()
                } else {
                    withAnimation {
                        pageIndex += 1
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .font(.headline)
    }
}

private struct OnboardingThemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: AppTheme

    var body: some View {
        NavigationStack {
            List {
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        selection = theme
                        dismiss()
                    } label: {
                        HStack {
                            Text(theme.displayNameKey)
                            Spacer()
                            if theme == selection {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle(Text("settings.theme"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct OnboardingLanguagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: AppLanguage

    var body: some View {
        NavigationStack {
            List {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        selection = language
                        dismiss()
                    } label: {
                        HStack {
                            Text(language.displayNameKey)
                            Spacer()
                            if language == selection {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle(Text("settings.language"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    OnboardingView(onFinished: {})
}
