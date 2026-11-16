import CryptoKit
import Foundation
import Security

/// 水鱼凭据只进入 Keychain；UserDefaults 继续保存非敏感界面设置。
enum AccountCredentialStore {
    private static let service = "dev.0xsr.maimaidata.accounts"
    private static let accountsKey = "saved_accounts"

    static func load(_ key: String) -> String {
        var query = baseQuery(key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else { return "" }
        return value
    }

    static func save(_ value: String, key: String) {
        let query = baseQuery(key)
        if value.isEmpty {
            SecItemDelete(query as CFDictionary)
            return
        }
        let attributes = [kSecValueData as String: Data(value.utf8)]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item.merge(attributes) { _, new in new }
            SecItemAdd(item as CFDictionary, nil)
        }
    }

    static func loadAccounts(legacyData: Data?) -> [SavedAccount] {
        let data = load(accountsKey).data(using: .utf8) ?? legacyData
        let accounts = data.flatMap { try? JSONDecoder().decode([SavedAccount].self, from: $0) } ?? []
        // 即使旧版本尚未生成 Keychain 记录，也立即完成迁移。
        if !accounts.isEmpty { saveAccounts(accounts) }
        return accounts
    }

    static func saveAccounts(_ accounts: [SavedAccount]) {
        guard let data = try? JSONEncoder().encode(accounts) else { return }
        let query = baseQuery(accountsKey)
        let attributes = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item.merge(attributes) { _, new in new }
            SecItemAdd(item as CFDictionary, nil)
        }
    }

    private static func baseQuery(_ key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
    }
}

extension String {
    /// 仅用于成绩缓存文件名，不暴露水鱼用户名，也不用于密码哈希。
    var sha256Hex: String {
        SHA256.hash(data: Data(utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
