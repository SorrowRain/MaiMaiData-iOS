import Foundation

/// UserDefaults / Keychain key names used by DataStore.
enum PreferenceKeys {
    static let favorites = "favorite_ids"
    static let searchHistory = "search_history"
    static let savedAccounts = "saved_accounts"
    static let username = "df_username"
    static let password = "df_password"
    static let cookie = "df_cookie"
    static let dfNickname = "df_nickname"
    static let dataVersion = "song_data_version"
    static let chartStatsSync = "chart_stats_sync_ts"
    static let showAlias = "enable_show_alias"
    static let aliasSearch = "enable_alias_search"
    static let charterSearch = "enable_charter_search"
    static let useDFNickname = "use_df_nickname"
    static let customNickname = "custom_nickname"
    static let lastVersionCheck = "last_version_check"
    static let lastLevelCheck = "last_level_check"
}

extension PreferenceKeys {
    /// Default values for boolean settings (registered once at launch).
    static func registerDefaults(in defaults: UserDefaults) {
        defaults.register(defaults: [
            showAlias: true,
            aliasSearch: true,
            charterSearch: false,
            useDFNickname: true
        ])
    }
}
