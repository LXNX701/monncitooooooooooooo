import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @AppStorage(FeatureVisibility.developerModeStorageKey)
    private var developerModeEnabled = false
    @State private var tabNavigation: AppTabNavigationState
    @State private var showSettings = false
    @State private var showLogs = false

    init() {
#if targetEnvironment(simulator)
        let arguments = ProcessInfo.processInfo.arguments
        let initialTab: Int
        if arguments.contains("--simulate-new-tab") {
            initialTab = AppSection.search.rawValue
        } else if arguments.contains("--simulate-sources-tab") {
            initialTab = AppSection.home.rawValue
        } else if arguments.contains("--simulate-installed-tab")
                    || arguments.contains("--simulate-patch-tab")
                    || arguments.contains("--simulate-wallpaper-tab") {
            initialTab = AppSection.installed.rawValue
        } else if arguments.contains("--simulate-files-tab")
                    || arguments.contains("--simulate-search-tab") {
            initialTab = AppSection.search.rawValue
        } else {
            initialTab = AppSection.home.rawValue
        }
        _tabNavigation = State(initialValue: AppTabNavigationState(selectedTab: initialTab))
        _showSettings = State(initialValue: arguments.contains("--simulate-settings"))
#else
        _tabNavigation = State(initialValue: AppTabNavigationState())
#endif
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .tint(AppTheme.accent)
        .imageScale(.small)
        .onChange(of: patchDraftCoordinator.request?.id) { requestID in
            if requestID != nil { tabNavigation.select(AppSection.installed.rawValue) }
        }
        .onChange(of: patchDraftCoordinator.importRequest?.id) { requestID in
            if requestID != nil { tabNavigation.select(AppSection.installed.rawValue) }
        }
        .onChange(of: developerModeEnabled) { _ in
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .onAppear {
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showLogs) { LogView() }
        .patchStorePresentation(patchStore)
        .repositoryStorePresentation(repositoryStore, patchStore: patchStore)
    }

    private var compactLayout: some View {
        TabView(selection: tabSelection) {
            ForEach(primarySections) { section in
                sectionContent(section)
                    .tabItem {
                        CompactTabLabel(
                            title: language.text(section.titleKey),
                            systemImage: section.systemImage
                        )
                    }
                    .tag(section.rawValue)
            }
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }

    private var regularLayout: some View {
        NavigationSplitView {
            List {
                ForEach(primarySections) { section in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            tabNavigation.select(section.rawValue)
                        }
                    } label: {
                        Label(language.text(section.titleKey), systemImage: section.systemImage)
                            .fontWeight(section.rawValue == tabNavigation.selectedTab ? .semibold : .regular)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        section.rawValue == tabNavigation.selectedTab
                            ? AppTheme.accent.opacity(0.14)
                            : Color.clear
                    )
                    .accessibilityAddTraits(
                        section.rawValue == tabNavigation.selectedTab ? .isSelected : []
                    )
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.pageBackground)
            .navigationTitle("3105")
            .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 300)
        } detail: {
            sectionContent(selectedVisibleSection)
                .id(selectedVisibleSection.rawValue)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func sectionContent(_ section: AppSection) -> some View {
        switch section {
        case .home:
            RepositoryHomeView(onOpenSettings: openSettings, onOpenLogs: openLogs)
        case .installed:
            PatchProjectsView(onOpenSettings: openSettings, onOpenLogs: openLogs)
        case .search:
            SearchFilesHubView(
                filesTabSession: filesTabSession,
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .new, .sources, .files:
            RepositoryHomeView(onOpenSettings: openSettings, onOpenLogs: openLogs)
        }
    }

    private var primarySections: [AppSection] {
        [.home, .installed, .search]
    }

    private var tabSelection: Binding<Int> {
        Binding(get: { tabNavigation.selectedTab }, set: { tabNavigation.select($0) })
    }

    private var filesTabSession: Binding<FilesTabSession> {
        Binding(get: { tabNavigation.filesTabs }, set: { tabNavigation.setFilesTabs($0) })
    }

    private var featureVisibility: FeatureVisibility {
        FeatureVisibility(developerModeEnabled: developerModeActive)
    }

    private var developerModeActive: Bool {
#if targetEnvironment(simulator)
        developerModeEnabled
            || ProcessInfo.processInfo.arguments.contains("--simulate-developer-mode")
            || ProcessInfo.processInfo.arguments.contains("--simulate-files-tab")
#else
        developerModeEnabled
#endif
    }

    private var selectedVisibleSection: AppSection {
        let selected = AppSection(rawValue: tabNavigation.selectedTab)
        return selected.flatMap { primarySections.contains($0) ? $0 : nil } ?? .home
    }

    private func openSettings() { showSettings = true }
    private func openLogs() { showLogs = true }
}

private struct SearchFilesHubView: View {
    private enum Mode: String, CaseIterable {
        case search
        case files
    }

    @Environment(\.appLanguage) private var language
    @Binding var filesTabSession: FilesTabSession
    @State private var mode: Mode = .search

    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $mode) {
                Text(language.text("tab.search")).tag(Mode.search)
                Text(language.text("tab.files")).tag(Mode.files)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppTheme.pageInset)
            .padding(.vertical, 10)
            .background(.bar)

            Group {
                switch mode {
                case .search:
                    RepositorySearchView(onOpenSettings: onOpenSettings, onOpenLogs: onOpenLogs)
                case .files:
                    AppDataBrowserView(
                        tabSession: $filesTabSession,
                        onOpenSettings: onOpenSettings,
                        onOpenLogs: onOpenLogs
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppTheme.pageBackground)
        .animation(.easeInOut(duration: 0.18), value: mode)
    }
}

private struct CompactTabLabel: View {
    let title: String
    let systemImage: String

    @ViewBuilder
    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 17, weight: .medium))
        Text(title)
    }
}

private extension AppSection {
    var titleKey: String {
        switch self {
        case .home: return "tab.home"
        case .new: return "tab.new"
        case .sources: return "tab.sources"
        case .installed: return "tab.installed"
        case .files: return "tab.files"
        case .search: return "tab.search"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .new: return "clock.fill"
        case .sources: return "shippingbox.fill"
        case .installed: return "tray.full.fill"
        case .files: return "folder.fill"
        case .search: return "magnifyingglass"
        }
    }
}
