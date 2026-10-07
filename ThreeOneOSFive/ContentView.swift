import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @State private var tab: Tab = .home
    @State private var selectedMode: MoonX7Mode = .ffth
    @State private var filesSession = FilesTabSession()
    @State private var showSettings = false
    @State private var showLogs = false

    private enum Tab: Hashable { case home, installed, previews, files }

    var body: some View {
        ZStack {
            MoonX7Background()
            TabView(selection: $tab) {
                MoonX7Home(
                    openInstalled: { tab = .installed },
                    openPreview: { tab = .previews },
                    mode: $selectedMode,
                    settings: { showSettings = true }
                )
                .tag(Tab.home)
                .tabItem { Label("Inicio", systemImage: "house.fill") }

                MoonX7Installed(mode: $selectedMode, settings: { showSettings = true })
                    .tag(Tab.installed)
                    .tabItem { Label("Installed", systemImage: "shippingbox.fill") }

                MoonX7Previews()
                    .tag(Tab.previews)
                    .tabItem { Label("Preview", systemImage: "play.rectangle.fill") }

                MoonX7Files(
                    session: $filesSession,
                    settings: { showSettings = true },
                    logs: { showLogs = true }
                )
                .tag(Tab.files)
                .tabItem { Label("Files", systemImage: "folder.fill") }
            }
            .tint(MoonX7Style.red)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showLogs) { LogView() }
        .patchStorePresentation(patchStore)
        .repositoryStorePresentation(repositoryStore, patchStore: patchStore)
        .onChange(of: patchDraftCoordinator.request?.id) { id in
            if id != nil { tab = .installed }
        }
        .onChange(of: patchDraftCoordinator.importRequest?.id) { id in
            if id != nil { tab = .installed }
        }
    }
}

private enum MoonX7Style {
    static let red = Color(red: 1, green: 0.045, blue: 0.16)
    static let pink = Color(red: 0.92, green: 0.08, blue: 0.48)
    static let purple = Color(red: 0.48, green: 0.10, blue: 0.98)
    static let cyan = Color(red: 0.04, green: 0.82, blue: 1)
    static let panel = Color.white.opacity(0.055)
    static let border = Color.white.opacity(0.11)
}

private enum MoonX7Mode: String, CaseIterable, Identifiable {
    case ffth, ffmax
    var id: String { rawValue }
    var title: String { rawValue.uppercased() }
    var icon: String { self == .ffth ? "bolt.fill" : "flame.fill" }
    var subtitle: String { self == .ffth ? "FAST / LIGHT" : "FULL / MAX" }
}

private struct MoonX7Background: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 0.18 : 0.04)) { context in
            let p = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 12) / 12
            ZStack {
                Color.black.ignoresSafeArea()
                Circle().fill(MoonX7Style.purple.opacity(0.20)).frame(width: 340).blur(radius: 90)
                    .offset(x: CGFloat(cos(p * .pi * 2)) * 120, y: -190)
                Circle().fill(MoonX7Style.red.opacity(0.13)).frame(width: 300).blur(radius: 85)
                    .offset(x: CGFloat(sin(p * .pi * 2)) * -130, y: 190)
                AngularGradient(
                    colors: [MoonX7Style.red.opacity(0.06), MoonX7Style.purple.opacity(0.06),
                             MoonX7Style.cyan.opacity(0.035), MoonX7Style.pink.opacity(0.06)],
                    center: .center,
                    angle: .degrees(p * 360)
                )
                .blur(radius: 30)
                .ignoresSafeArea()
            }
        }
        .allowsHitTesting(false)
    }
}

private struct MoonX7Header: View {
    let title: String
    let subtitle: String
    let settings: () -> Void
    var body: some View {
        HStack(spacing: 11) {
            AppLogo(size: 48)
                .shadow(color: MoonX7Style.red.opacity(0.38), radius: 18)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 17, weight: .black, design: .rounded))
                    .tracking(2).foregroundStyle(.white)
                Text(subtitle).font(.system(size: 8, weight: .black, design: .monospaced))
                    .tracking(1.4).foregroundStyle(MoonX7Style.red)
            }
            Spacer()
            Button(action: settings) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.06), in: Circle())
                    .overlay { Circle().stroke(MoonX7Style.border, lineWidth: 1) }
            }.buttonStyle(.plain)
        }
    }
}

private struct MoonX7Banner: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            MoonX7GIFBanner().frame(height: 170).frame(maxWidth: .infinity).clipped()
            LinearGradient(colors: [.clear, .black.opacity(0.84)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 3) {
                Text("SENSI MOON").font(.system(size: 22, weight: .black, design: .rounded))
                    .tracking(1.8).foregroundStyle(.white)
                Text("SELECT YOUR MODE").font(.system(size: 9, weight: .black, design: .monospaced))
                    .tracking(2).foregroundStyle(MoonX7Style.red)
            }.padding(15)
        }
        .background(.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(
                LinearGradient(colors: [MoonX7Style.red.opacity(0.65), MoonX7Style.purple.opacity(0.32), .white.opacity(0.05)],
                               startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        }
        .shadow(color: MoonX7Style.red.opacity(0.12), radius: 26, y: 12)
    }
}

private struct MoonX7ModePicker: View {
    @Binding var mode: MoonX7Mode
    let openInstalled: () -> Void
    var body: some View {
        HStack(spacing: 10) {
            ForEach(MoonX7Mode.allCases) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { mode = item }
                    openInstalled()
                } label: {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Image(systemName: item.icon)
                            Spacer()
                            Circle().fill(mode == item ? MoonX7Style.red : .white.opacity(0.12)).frame(width: 7)
                        }
                        Text(item.title).font(.system(size: 18, weight: .black, design: .rounded))
                        Text(item.subtitle).font(.system(size: 8, weight: .black, design: .monospaced))
                            .tracking(1.2).foregroundStyle(.white.opacity(0.42))
                    }
                    .foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
                    .padding(14)
                    .background(
                        mode == item
                        ? LinearGradient(colors: [MoonX7Style.red.opacity(0.24), MoonX7Style.pink.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [.white.opacity(0.06), .white.opacity(0.025)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 19, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 19, style: .continuous)
                            .stroke(mode == item ? MoonX7Style.red.opacity(0.72) : MoonX7Style.border,
                                    lineWidth: mode == item ? 1.2 : 0.8)
                    }
                    .shadow(color: mode == item ? MoonX7Style.red.opacity(0.20) : .clear, radius: 18, y: 7)
                }.buttonStyle(.plain)
            }
        }
    }
}

private struct MoonX7Home: View {
    let openInstalled: () -> Void
    let openPreview: () -> Void
    @Binding var mode: MoonX7Mode
    let settings: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 17) {
                    MoonX7Header(title: "MOON X7", subtitle: "PRIVATE PATCH HUB", settings: settings)
                    MoonX7Banner()

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Bienvenido a Sensi Moon")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Elige tu modo y entra a tus archivos 3105.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.50))
                    }.frame(maxWidth: .infinity, alignment: .leading)

                    MoonX7ModePicker(mode: $mode, openInstalled: openInstalled)

                    HStack(spacing: 10) {
                        MoonX7QuickCard(icon: "play.rectangle.fill", title: "PREVIEWS", subtitle: "Fotos • GIF • RGB", tint: MoonX7Style.cyan, action: openPreview)
                        MoonX7QuickCard(icon: "shippingbox.fill", title: "INSTALLED", subtitle: "Tus archivos 3105", tint: MoonX7Style.pink, action: openInstalled)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("REDES SOCIALES").font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(2.2).foregroundStyle(.white.opacity(0.40))
                        MoonX7DiscordCard()
                        HStack(spacing: 10) {
                            MoonX7MiniSocial(title: "DISCORD", icon: "message.fill", tint: MoonX7Style.red)
                            MoonX7MiniSocial(title: "SUPPORT", icon: "headphones", tint: MoonX7Style.cyan)
                            MoonX7MiniSocial(title: "NEWS", icon: "bell.fill", tint: MoonX7Style.pink)
                        }
                    }

                    HStack(spacing: 9) {
                        Circle().fill(MoonX7Style.red).frame(width: 8).shadow(color: MoonX7Style.red, radius: 8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SYSTEM READY").font(.system(size: 10, weight: .black, design: .monospaced)).foregroundStyle(.white)
                            Text("Login activo • motor 3105 disponible").font(.system(size: 9, weight: .medium)).foregroundStyle(.white.opacity(0.35))
                        }
                        Spacer()
                    }
                    .padding(13)
                    .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay { RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.07), lineWidth: 1) }

                    Text("MOONX7 • 3105 • PRIVATE").font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(2).foregroundStyle(.white.opacity(0.18)).padding(.vertical, 8)
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 32)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct MoonX7QuickCard: View {
    let icon: String; let title: String; let subtitle: String; let tint: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                Image(systemName: icon).font(.system(size: 18, weight: .black)).foregroundStyle(tint)
                Text(title).font(.system(size: 12, weight: .black, design: .rounded)).tracking(1).foregroundStyle(.white)
                Text(subtitle).font(.system(size: 9, weight: .medium)).foregroundStyle(.white.opacity(0.40))
            }
            .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading).padding(13)
            .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 18).stroke(tint.opacity(0.24), lineWidth: 1) }
        }.buttonStyle(MoonX7Press())
    }
}

private struct MoonX7DiscordCard: View {
    var body: some View {
        Button {
            if let url = URL(string: "https://discord.gg/cYdjSYQSk") { UIApplication.shared.open(url) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill").foregroundStyle(MoonX7Style.purple)
                    .frame(width: 42, height: 42).background(MoonX7Style.purple.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Discord MOON X7").font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(.white)
                    Text("Keys • Updates • Support").font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.42))
                }
                Spacer()
                Image(systemName: "arrow.up.right").foregroundStyle(MoonX7Style.purple)
            }
            .padding(12).background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 18).stroke(MoonX7Style.purple.opacity(0.25), lineWidth: 1) }
        }.buttonStyle(MoonX7Press())
    }
}

private struct MoonX7MiniSocial: View {
    let title: String; let icon: String; let tint: Color
    var body: some View {
        Button {
            if let url = URL(string: "https://discord.gg/cYdjSYQSk") { UIApplication.shared.open(url) }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .black)).foregroundStyle(tint)
                Text(title).font(.system(size: 7, weight: .black, design: .monospaced)).tracking(0.8).foregroundStyle(.white.opacity(0.58))
            }
            .frame(maxWidth: .infinity, minHeight: 62)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 16).stroke(tint.opacity(0.18), lineWidth: 1) }
        }.buttonStyle(MoonX7Press())
    }
}

private struct MoonX7Installed: View {
    @EnvironmentObject private var store: PatchProjectStore
    @Binding var mode: MoonX7Mode
    @State private var search = ""
    let settings: () -> Void

    private var items: [PatchLibraryItem] {
        let all = store.items
        let selected = all.filter { item in
            let n = (item.project?.name ?? item.packageURL.lastPathComponent).lowercased()
            if mode == .ffth { return n.contains("ffth") || (!n.contains("ffmax") && !n.contains("max")) }
            return n.contains("ffmax") || n.contains("max")
        }
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return q.isEmpty ? selected : selected.filter {
            ($0.project?.name ?? $0.packageURL.lastPathComponent).localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 15) {
                    MoonX7Header(title: "INSTALLED", subtitle: "3105 PATCH LIBRARY", settings: settings)
                    MoonX7Banner()

                    HStack(spacing: 10) {
                        ForEach(MoonX7Mode.allCases) { item in
                            Button { withAnimation(.easeInOut(duration: 0.2)) { mode = item } } label: {
                                HStack(spacing: 7) { Image(systemName: item.icon); Text(item.title) }
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(mode == item ? .white : .white.opacity(0.42))
                                    .frame(maxWidth: .infinity, minHeight: 42)
                                    .background(mode == item ? MoonX7Style.red.opacity(0.20) : .white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
                                    .overlay { RoundedRectangle(cornerRadius: 14).stroke(mode == item ? MoonX7Style.red.opacity(0.65) : MoonX7Style.border, lineWidth: 1) }
                            }.buttonStyle(.plain)
                        }
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(mode.title).font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(.white)
                            Text(mode.subtitle).font(.system(size: 8, weight: .black, design: .monospaced)).tracking(1.5).foregroundStyle(MoonX7Style.red)
                        }
                        Spacer()
                        Text("\(items.count) FILES").font(.system(size: 9, weight: .black, design: .monospaced)).foregroundStyle(.white.opacity(0.34))
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundStyle(MoonX7Style.red)
                        TextField("Buscar 3105…", text: $search).textInputAutocapitalization(.never).autocorrectionDisabled().foregroundStyle(.white)
                    }
                    .padding(.horizontal, 13).frame(height: 44)
                    .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
                    .overlay { RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.08), lineWidth: 1) }

                    if items.isEmpty {
                        VStack(spacing: 9) {
                            Image(systemName: mode.icon).font(.system(size: 30, weight: .black)).foregroundStyle(MoonX7Style.red)
                            Text("SIN ARCHIVOS \(mode.title)").font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(.white)
                            Text("Los paquetes 3105 de este modo aparecerán aquí.")
                                .font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.40)).multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 34)
                        .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 20))
                        .overlay { RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.07), lineWidth: 1) }
                    } else {
                        LazyVStack(spacing: 9) {
                            ForEach(items) { item in
                                NavigationLink {
                                    PatchProjectDetailView(store: store, projectID: item.id)
                                } label: {
                                    MoonX7PatchRow(item: item, mode: mode)
                                }.buttonStyle(MoonX7Press())
                            }
                        }
                    }

                    Text("Los botones y runners reales siguen usando el motor existente de 3105.")
                        .font(.system(size: 9, weight: .medium)).foregroundStyle(.white.opacity(0.25))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 32)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { store.reload() }
        }
    }
}

private struct MoonX7PatchRow: View {
    let item: PatchLibraryItem
    let mode: MoonX7Mode
    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 15).fill(
                    LinearGradient(colors: [(mode == .ffth ? MoonX7Style.red : MoonX7Style.purple).opacity(0.27), MoonX7Style.pink.opacity(0.07)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                Image(systemName: mode.icon).font(.system(size: 17, weight: .black)).foregroundStyle(.white)
            }.frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent)
                    .font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(.white).lineLimit(1)
                Text(item.project?.author ?? "MOONX7")
                    .font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundStyle(.white.opacity(0.40))
                HStack(spacing: 6) {
                    Text("3105")
                    Text(item.summary.isPasswordProtected ? "LOCKED" : "READY")
                }.font(.system(size: 7, weight: .black, design: .monospaced)).foregroundStyle(MoonX7Style.red)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 11, weight: .black)).foregroundStyle(.white.opacity(0.28))
        }
        .padding(10).background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 19))
        .overlay { RoundedRectangle(cornerRadius: 19).stroke(.white.opacity(0.08), lineWidth: 1) }
    }
}

private struct MoonX7Previews: View {
    @State private var mode: MoonX7Mode = .ffth
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 15) {
                    MoonX7Header(title: "PREVIEWS", subtitle: "VISUAL SHOWCASE", settings: {})
                    MoonX7Banner()
                    HStack(spacing: 10) {
                        ForEach(MoonX7Mode.allCases) { item in
                            Button { withAnimation(.easeInOut(duration: 0.22)) { mode = item } } label: {
                                Text(item.title).font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(mode == item ? .white : .white.opacity(0.40))
                                    .frame(maxWidth: .infinity, minHeight: 42)
                                    .background(mode == item ? MoonX7Style.red.opacity(0.20) : .white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
                                    .overlay { RoundedRectangle(cornerRadius: 14).stroke(mode == item ? MoonX7Style.red.opacity(0.62) : MoonX7Style.border, lineWidth: 1) }
                            }.buttonStyle(.plain)
                        }
                    }
                    Text("\(mode.title) PREVIEW").font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Solo visualización: fotos, GIF, RGB y mockups. Aquí no se inyecta ni se elimina.")
                        .font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.40))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        MoonX7PreviewCard(title: "Runner", label: "GIF / LIVE", tint: MoonX7Style.red) { MoonX7GIFBanner() }
                        MoonX7PreviewCard(title: "Patch Visual", label: "VIDEO STYLE", tint: MoonX7Style.purple) {
                            TimelineView(.animation(minimumInterval: 0.04)) { context in
                                let p = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 5) / 5
                                ZStack {
                                    LinearGradient(colors: [MoonX7Style.purple.opacity(0.75), MoonX7Style.pink.opacity(0.35), .black],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                    Circle().stroke(AngularGradient(colors: [MoonX7Style.cyan, MoonX7Style.red, MoonX7Style.pink, MoonX7Style.cyan], center: .center),
                                                    lineWidth: 3).frame(width: 78, height: 78).rotationEffect(.degrees(p * 360))
                                        .shadow(color: MoonX7Style.cyan.opacity(0.8), radius: 16)
                                }
                            }
                        }
                        MoonX7PreviewCard(title: "RGB Effects", label: "ANIMATED", tint: MoonX7Style.cyan) {
                            TimelineView(.animation(minimumInterval: 0.04)) { context in
                                let p = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 4) / 4
                                AngularGradient(colors: [MoonX7Style.red, MoonX7Style.purple, MoonX7Style.cyan, MoonX7Style.pink, MoonX7Style.red],
                                                center: .center, angle: .degrees(p * 360))
                                    .overlay { Text("RGB").font(.system(size: 18, weight: .black, design: .rounded)).tracking(3).foregroundStyle(.white) }
                            }
                        }
                        MoonX7PreviewCard(title: mode.title, label: mode.subtitle, tint: MoonX7Style.pink) {
                            VStack(spacing: 9) {
                                Image(systemName: mode.icon).font(.system(size: 32, weight: .black)).foregroundStyle(.white)
                                Text(mode.title).font(.system(size: 20, weight: .black, design: .rounded)).foregroundStyle(.white)
                                Text("READY").font(.system(size: 8, weight: .black, design: .monospaced)).tracking(1.5).foregroundStyle(MoonX7Style.red)
                            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 32)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct MoonX7PreviewCard<Content: View>: View {
    let title: String; let label: String; let tint: Color; let content: () -> Content
    var body: some View {
        VStack(spacing: 0) {
            content().frame(height: 132).frame(maxWidth: .infinity).clipped()
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(.white)
                Text(label).font(.system(size: 7, weight: .black, design: .monospaced)).tracking(1).foregroundStyle(tint)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(10)
        }
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(tint.opacity(0.20), lineWidth: 1) }
    }
}

private struct MoonX7Files: View {
    @Binding var session: FilesTabSession
    let settings: () -> Void
    let logs: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("FILES").font(.system(size: 18, weight: .black, design: .rounded)).foregroundStyle(.white)
                    Text("APP DATA • 3105 WORKSPACE").font(.system(size: 8, weight: .black, design: .monospaced)).tracking(1.2).foregroundStyle(MoonX7Style.red)
                }
                Spacer()
                Button(action: settings) { Image(systemName: "slider.horizontal.3").foregroundStyle(.white.opacity(0.75)) }.buttonStyle(.plain)
            }.padding(.horizontal, 16).padding(.vertical, 12)
            AppDataBrowserView(tabSession: $session, onOpenSettings: settings, onOpenLogs: logs)
        }
        .background(Color.black)
    }
}

private struct MoonX7Press: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.78 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
