import SwiftUI
import ImageIO
import UIKit

struct MoonX7LoginView: View {
    @ObservedObject var auth: MoonLicenseAuth
    @State private var licenseKey = ""
    @FocusState private var keyFocused: Bool

    private let accent = Color(red: 1.0, green: 0.08, blue: 0.18)
    private let violet = Color(red: 0.72, green: 0.10, blue: 0.32)

    var body: some View {
        ZStack {
            MoonX7AnimatedBackground(accent: accent, violet: violet)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 28)

                    AppLogo(size: 92)
                        .shadow(color: accent.opacity(0.50), radius: 24, y: 8)

                    Text("MOON X7")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(.white)
                        .padding(.top, 14)

                    Text("PRIVATE ACCESS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(3.2)
                        .foregroundStyle(accent.opacity(0.92))
                        .padding(.top, 5)

                    MoonX7GIFBanner()
                        .frame(maxWidth: .infinity)
                        .frame(height: 132)
                        .padding(.horizontal, 18)
                        .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Acceso privado")
                                .font(.system(size: 21, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Pega tu key MOONX7 para entrar a la aplicación.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.55))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("LICENSE KEY")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(1.5)
                                .foregroundStyle(.white.opacity(0.40))

                            HStack(spacing: 10) {
                                Image(systemName: "key.horizontal.fill")
                                    .foregroundStyle(accent)
                                    .frame(width: 20)

                                TextField("MOONX7-XXXX-XXXX", text: $licenseKey)
                                    .focused($keyFocused)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .foregroundStyle(.white)
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .submitLabel(.go)
                                    .onSubmit(submit)

                                Button {
                                    licenseKey = UIPasteboard.general.string ?? licenseKey
                                    keyFocused = true
                                } label: {
                                    Image(systemName: "doc.on.clipboard.fill")
                                        .foregroundStyle(.white.opacity(0.48))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Pegar key")
                            }
                            .padding(.horizontal, 13)
                            .frame(height: 52)
                            .background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .stroke(
                                        keyFocused ? accent.opacity(0.75) : .white.opacity(0.10),
                                        lineWidth: 1
                                    )
                            }
                        }

                        Button(action: submit) {
                            HStack(spacing: 9) {
                                if auth.isChecking {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                }

                                Text(auth.isChecking ? "VERIFICANDO..." : "ENTRAR")
                            }
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .tracking(1.0)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [accent, violet],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                            )
                            .shadow(color: accent.opacity(0.28), radius: 18, y: 8)
                        }
                        .buttonStyle(.plain)
                        .disabled(
                            auth.isChecking ||
                            licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                        .opacity(
                            auth.isChecking ||
                            licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? 0.55 : 1
                        )

                        HStack(spacing: 8) {
                            Image(
                                systemName: auth.errorMessage == nil
                                    ? "lock.shield.fill"
                                    : "exclamationmark.triangle.fill"
                            )
                            Text(
                                auth.errorMessage ??
                                "La licencia queda vinculada al dispositivo."
                            )
                            .lineLimit(3)
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(
                            auth.errorMessage == nil
                                ? .white.opacity(0.45)
                                : .red.opacity(0.95)
                        )
                    }
                    .padding(20)
                    .background(
                        .black.opacity(0.62),
                        in: RoundedRectangle(cornerRadius: 25, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        accent.opacity(0.55),
                                        violet.opacity(0.35),
                                        .white.opacity(0.06)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(0.45), radius: 30, y: 15)
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                    Text("MOONX7 • 3105")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.22))
                        .padding(.vertical, 22)
                }
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func submit() {
        auth.signIn(key: licenseKey)
    }
}

struct MoonX7GIFBanner: UIViewRepresentable {
    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 20
        view.backgroundColor = .clear
        load(into: view)
        return view
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        if uiView.image == nil {
            load(into: uiView)
        }
    }

    private func load(into imageView: UIImageView) {
        guard let url = Bundle.main.url(
            forResource: "banner gif app",
            withExtension: "gif"
        ) else {
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            guard
                let data = try? Data(contentsOf: url),
                let source = CGImageSourceCreateWithData(data as CFData, nil)
            else {
                return
            }

            var frames: [UIImage] = []
            var duration: TimeInterval = 0

            for index in 0..<CGImageSourceGetCount(source) {
                guard let image = CGImageSourceCreateThumbnailAtIndex(
                    source,
                    index,
                    [
                        kCGImageSourceCreateThumbnailFromImageAlways: true,
                        kCGImageSourceCreateThumbnailWithTransform: true,
                        kCGImageSourceThumbnailMaxPixelSize: 900
                    ] as CFDictionary
                ) else {
                    continue
                }

                frames.append(UIImage(cgImage: image))
                duration += Self.frameDuration(source: source, index: index)
            }

            guard !frames.isEmpty else { return }

            let animated = UIImage.animatedImage(
                with: frames,
                duration: max(duration, 0.8)
            )

            DispatchQueue.main.async {
                imageView.image = animated
                imageView.startAnimating()
            }
        }
    }

    private static func frameDuration(
        source: CGImageSource,
        index: Int
    ) -> TimeInterval {
        guard
            let properties = CGImageSourceCopyPropertiesAtIndex(
                source,
                index,
                nil
            ) as? [CFString: Any],
            let gif = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else {
            return 0.08
        }

        let unclamped = gif[kCGImagePropertyGIFUnclampedDelayTime] as? Double
        let clamped = gif[kCGImagePropertyGIFDelayTime] as? Double
        return max(unclamped ?? clamped ?? 0.08, 0.02)
    }
}

struct MoonX7AnimatedBackground: View {
    let accent: Color
    let violet: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 8) / 8

            ZStack {
                Color.black.ignoresSafeArea()

                Circle()
                    .fill(accent.opacity(0.22))
                    .frame(width: 340, height: 340)
                    .blur(radius: 80)
                    .offset(
                        x: CGFloat(sin(phase * .pi * 2)) * 110,
                        y: -150
                    )

                Circle()
                    .fill(violet.opacity(0.16))
                    .frame(width: 300, height: 300)
                    .blur(radius: 75)
                    .offset(
                        x: CGFloat(cos(phase * .pi * 2)) * 130,
                        y: 190
                    )

                LinearGradient(
                    colors: [.clear, accent.opacity(0.10), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .rotationEffect(.degrees(phase * 360))
            }
        }
    }
}

struct MoonX7HomeHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                AppLogo(size: 48)

                VStack(alignment: .leading, spacing: 3) {
                    Text("MOON X7")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .tracking(1.5)

                    Text("3105 • PRIVATE PATCH HUB")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            ZStack(alignment: .bottomLeading) {
                MoonX7GIFBanner()
                    .frame(height: 116)
                    .frame(maxWidth: .infinity)

                LinearGradient(
                    colors: [.clear, .black.opacity(0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text("WELCOME TO MOONX7")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.white)

                    Text("Tu centro de patches, archivos y herramientas.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(14)
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        AppTheme.accent.opacity(0.35),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: AppTheme.accent.opacity(0.15),
                radius: 18,
                y: 8
            )
        }
    }
}
