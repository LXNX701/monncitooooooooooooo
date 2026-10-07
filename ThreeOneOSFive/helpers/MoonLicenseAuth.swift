import Foundation
import Combine
import Security
import UIKit

@MainActor
final class MoonLicenseAuth: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isChecking = true
    @Published private(set) var licenseKey: String?
    @Published private(set) var expiresAt: Date?
    @Published private(set) var plan: String?
    @Published private(set) var durationDays: Int?
    @Published var errorMessage: String?

    private let supabaseURL = URL(string: "https://qgetvnmrhrcagnvpfgmr.supabase.co")!
    private let publishableKey = "sb_publishable_fyPxGwyJtHFK9gxkYv6FKw_1xi15e_l"
    private let keychainService = "com.moonx7.license"
    private let licenseAccount = "license-key"
    private let deviceAccount = "device-token"

    init() {
        Task { await bootstrap() }
    }

    func bootstrap() async {
        isChecking = true

        guard let key = readKeychain(licenseAccount), !key.isEmpty else {
            isAuthenticated = false
            isChecking = false
            return
        }

        do {
            let device = try deviceToken()
            let response = try await rpc(
                "verify_license",
                body: ["p_license_key": key, "p_udid": device]
            )

            guard response.success, response.status == "active" else {
                clearSession()
                isChecking = false
                return
            }

            licenseKey = key
            expiresAt = parseDate(response.expiresAt)
            plan = response.plan
            durationDays = response.durationDays
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            errorMessage = "No se pudo validar la licencia. Revisa tu conexión."
        }

        isChecking = false
    }

    func signIn(key rawKey: String) {
        let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard !key.isEmpty else {
            errorMessage = "Introduce tu key de acceso."
            return
        }

        errorMessage = nil
        isChecking = true

        Task {
            do {
                let device = try deviceToken()

                let activation = try await rpc(
                    "activate_license",
                    body: ["p_license_key": key, "p_udid": device]
                )

                guard activation.success else {
                    errorMessage = activation.message ?? "La licencia no pudo activarse."
                    isAuthenticated = false
                    isChecking = false
                    return
                }

                let verified = try await rpc(
                    "verify_license",
                    body: ["p_license_key": key, "p_udid": device]
                )

                guard verified.success, verified.status == "active" else {
                    errorMessage = verified.message ?? "La licencia no pudo verificarse."
                    isAuthenticated = false
                    isChecking = false
                    return
                }

                guard writeKeychain(key, account: licenseAccount) else {
                    errorMessage = "No se pudo guardar la licencia en este dispositivo."
                    isAuthenticated = false
                    isChecking = false
                    return
                }

                licenseKey = key
                expiresAt = parseDate(verified.expiresAt)
                plan = verified.plan
                durationDays = verified.durationDays
                isAuthenticated = true
                isChecking = false
            } catch {
                errorMessage = "No se pudo conectar con el servidor de licencias."
                isAuthenticated = false
                isChecking = false
            }
        }
    }

    func signOut() {
        deleteKeychain(licenseAccount)
        licenseKey = nil
        expiresAt = nil
        plan = nil
        durationDays = nil
        isAuthenticated = false
        errorMessage = nil
    }

    private struct RPCResponse: Decodable {
        let success: Bool
        let status: String?
        let plan: String?
        let durationDays: Int?
        let expiresAt: String?
        let message: String?

        enum CodingKeys: String, CodingKey {
            case success, status, plan, message
            case durationDays = "duration_days"
            case expiresAt = "expires_at"
        }
    }

    private func rpc(_ function: String, body: [String: String]) async throws -> RPCResponse {
        let url = supabaseURL.appendingPathComponent("rest/v1/rpc/\(function)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.setValue(publishableKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw NSError(
                domain: "MoonX7Auth",
                code: (response as? HTTPURLResponse)?.statusCode ?? -1
            )
        }

        return try JSONDecoder().decode(RPCResponse.self, from: data)
    }

    private func deviceToken() throws -> String {
        if let saved = readKeychain(deviceAccount), !saved.isEmpty {
            return saved
        }

        let token = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

        guard writeKeychain(token, account: deviceAccount) else {
            throw NSError(domain: "MoonX7Auth", code: -2)
        }

        return token
    }

    private func readKeychain(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?

        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    private func writeKeychain(_ value: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account
        ]

        let data = Data(value.utf8)

        if SecItemUpdate(
            query as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        ) == errSecSuccess {
            return true
        }

        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    private func deleteKeychain(_ account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }

    private func clearSession() {
        deleteKeychain(licenseAccount)
        licenseKey = nil
        expiresAt = nil
        plan = nil
        durationDays = nil
        isAuthenticated = false
    }

    private func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: value) {
            return date
        }

        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}
