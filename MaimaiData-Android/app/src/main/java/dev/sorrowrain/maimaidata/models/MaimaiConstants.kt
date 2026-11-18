package dev.sorrowrain.maimaidata.models

import androidx.compose.ui.graphics.Color
import dev.sorrowrain.maimaidata.R
import dev.sorrowrain.maimaidata.theme.AppTheme
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

object MaimaiConstants {
    const val GENRE_UTAGE = "宴会場"
    const val CHART_TYPE_DX = "DX"
    const val CHART_TYPE_SD = "SD"

    val allGenres: List<String> = listOf(
        "流行&动漫",
        "niconico & VOCALOID",
        "东方Project",
        "其他游戏",
        "舞萌",
        "音击&中二节奏",
        "宴会場"
    )

    val allLevels: List<String> = listOf(
        "ALL", "1", "2", "3", "4", "5", "6", "7", "7+",
        "8", "8+", "9", "9+", "10", "10+", "11", "11+",
        "12", "12+", "13", "13+", "14", "14+", "15"
    )

    data class VersionAsset(val name: String, val asset: String)

    val cnVersions: List<VersionAsset> = listOf(
        VersionAsset("maimai", "maimai"),
        VersionAsset("maimai PLUS", "maimai_plus"),
        VersionAsset("maimai GreeN", "maimai_green"),
        VersionAsset("maimai GreeN PLUS", "maimai_green_plus"),
        VersionAsset("maimai ORANGE", "maimai_orange"),
        VersionAsset("maimai ORANGE PLUS", "maimai_orange_plus"),
        VersionAsset("maimai PiNK", "maimai_pink"),
        VersionAsset("maimai PiNK PLUS", "maimai_pink_plus"),
        VersionAsset("maimai MURASAKi", "maimai_murasaki"),
        VersionAsset("maimai MURASAKi PLUS", "maimai_murasaki_plus"),
        VersionAsset("maimai MiLK", "maimai_milk"),
        VersionAsset("maimai MiLK PLUS", "maimai_milk_plus"),
        VersionAsset("maimai FiNALE", "maimai_finale"),
        VersionAsset("舞萌DX", "maimaidx_cn"),
        VersionAsset("舞萌DX 2021", "maimaidx_2021"),
        VersionAsset("舞萌DX 2022", "maimaidx_2022"),
        VersionAsset("舞萌DX 2023", "maimaidx_2023"),
        VersionAsset("舞萌DX 2024", "maimaidx_2024"),
        VersionAsset("舞萌DX 2025", "maimaidx_2025"),
        VersionAsset("舞萌DX 2026", "maimaidx_2026")
    )

    val jpVersions: List<VersionAsset> = listOf(
        VersionAsset("maimai", "maimai"),
        VersionAsset("maimai PLUS", "maimai_plus"),
        VersionAsset("GreeN", "maimai_green"),
        VersionAsset("GreeN PLUS", "maimai_green_plus"),
        VersionAsset("ORANGE", "maimai_orange"),
        VersionAsset("ORANGE PLUS", "maimai_orange_plus"),
        VersionAsset("PiNK", "maimai_pink"),
        VersionAsset("PiNK PLUS", "maimai_pink_plus"),
        VersionAsset("MURASAKi", "maimai_murasaki"),
        VersionAsset("MURASAKi PLUS", "maimai_murasaki_plus"),
        VersionAsset("MiLK", "maimai_milk"),
        VersionAsset("MiLK PLUS", "maimai_milk_plus"),
        VersionAsset("FiNALE", "maimai_finale"),
        VersionAsset("maimaiでらっくす", "maimaidx"),
        VersionAsset("maimaiでらっくす PLUS", "maimaidx_plus"),
        VersionAsset("Splash", "maimaidx_splash"),
        VersionAsset("Splash PLUS", "maimaidx_splash_plus"),
        VersionAsset("UNiVERSE", "maimaidx_universe"),
        VersionAsset("UNiVERSE PLUS", "maimaidx_universe_plus"),
        VersionAsset("FESTiVAL", "maimaidx_festival"),
        VersionAsset("FESTiVAL PLUS", "maimaidx_festival_plus"),
        VersionAsset("BUDDiES", "maimaidx_buddies"),
        VersionAsset("BUDDiES PLUS", "maimaidx_buddies_plus"),
        VersionAsset("PRiSM", "maimaidx_prism"),
        VersionAsset("PRiSM PLUS", "maimaidx_prism_plus"),
        VersionAsset("CiRCLE", "maimaidx_circle"),
        VersionAsset("CiRCLE PLUS", "maimaidx_circle_plus"),
        VersionAsset("MAGiCAL", "maimaidx_magical")
    )

    private val classicEraChips = listOf(
        "maimai", "GreeN", "ORANGE", "PiNK", "MURASAKi", "MiLK", "FiNALE"
    )

    val searchVersions: List<String> = classicEraChips + listOf(
        "舞萌DX", "舞萌DX 2021", "舞萌DX 2022", "舞萌DX 2023",
        "舞萌DX 2024", "舞萌DX 2025", "舞萌DX 2026"
    )

    fun checklistVersions(region: ServerRegion): List<VersionAsset> = when (region) {
        ServerRegion.CN -> cnVersions
        ServerRegion.INTL -> jpVersions.filter { it.name != "MAGiCAL" }
        ServerRegion.JP -> jpVersions
    }

    fun searchVersionChips(region: ServerRegion): List<String> = when (region) {
        ServerRegion.CN -> searchVersions
        ServerRegion.INTL, ServerRegion.JP -> {
            val dxNames = checklistVersions(region).drop(13).map { it.name }
            classicEraChips + dxNames
        }
    }

    fun expandVersionFilter(selected: Collection<String>, region: ServerRegion = ServerRegion.CN): Set<String> {
        val result = mutableSetOf<String>()
        when (region) {
            ServerRegion.CN -> {
                for (item in selected) {
                    when {
                        item == "maimai" -> {
                            result += "maimai"
                            result += "maimai PLUS"
                        }
                        item == "FiNALE" -> result += "maimai FiNALE"
                        !item.startsWith("舞萌") && !item.contains("FiNALE") -> {
                            result += "maimai $item PLUS"
                            result += "maimai $item"
                        }
                        else -> result += item
                    }
                }
            }
            ServerRegion.INTL, ServerRegion.JP -> {
                val groupedClassic = setOf("GreeN", "ORANGE", "PiNK", "MURASAKi", "MiLK")
                for (item in selected) {
                    when {
                        item == "maimai" -> {
                            result += "maimai"
                            result += "maimai PLUS"
                        }
                        item in groupedClassic -> {
                            result += item
                            result += "$item PLUS"
                        }
                        else -> result += item
                    }
                }
            }
        }
        return result
    }

    data class GenreColorPair(val bg: Color, val stroke: Color)

    fun genreColors(genre: String): GenreColorPair = when (genre) {
        "流行&动漫" -> GenreColorPair(AppTheme.Palette.genrePopBg, AppTheme.Palette.genrePopStroke)
        "niconico & VOCALOID" -> GenreColorPair(AppTheme.Palette.genreNicoBg, AppTheme.Palette.genreNicoStroke)
        "东方Project" -> GenreColorPair(AppTheme.Palette.genreTouhouBg, AppTheme.Palette.genreTouhouStroke)
        "其他游戏" -> GenreColorPair(AppTheme.Palette.genreGameBg, AppTheme.Palette.genreGameStroke)
        "舞萌" -> GenreColorPair(AppTheme.Palette.genreMaimaiBg, AppTheme.Palette.genreMaimaiStroke)
        "宴会場" -> GenreColorPair(AppTheme.Palette.genreUtageBg, AppTheme.Palette.genreUtageStroke)
        else -> GenreColorPair(AppTheme.Palette.genreOtherBg, AppTheme.Palette.genreOtherStroke)
    }

    fun genreCardFill(genre: String): Color =
        if (genre == "其他游戏") AppTheme.Palette.genreGameCardFill else genreColors(genre).bg

    fun genreTextColor(genre: String, isDark: Boolean): Color {
        if (isDark) {
            return genreColors(genre).bg.brightened(minimumBrightness = 1.0f, maxSaturation = 0.5f)
        }
        return when (genre) {
            "流行&动漫" -> AppTheme.Palette.genrePopText
            "niconico & VOCALOID" -> AppTheme.Palette.genreNicoText
            "东方Project" -> AppTheme.Palette.genreTouhouText
            "其他游戏" -> AppTheme.Palette.genreGameText
            "舞萌" -> AppTheme.Palette.genreMaimaiText
            "宴会場" -> AppTheme.Palette.genreUtageText
            else -> AppTheme.Palette.genreOtherText
        }
    }

    fun shortGenreDisplayName(genre: String): String =
        if (genre == "niconico & VOCALOID") "VOCALOID" else genre

    fun jpVersionAsset(versionCode: String): String? {
        val map = listOf(
            "100" to "maimai", "110" to "maimai_plus",
            "120" to "maimai_green", "130" to "maimai_green_plus",
            "140" to "maimai_orange", "150" to "maimai_orange_plus",
            "160" to "maimai_pink", "170" to "maimai_pink_plus",
            "180" to "maimai_murasaki", "185" to "maimai_murasaki_plus",
            "190" to "maimai_milk", "195" to "maimai_milk_plus",
            "199" to "maimai_finale",
            "200" to "maimaidx", "205" to "maimaidx_plus",
            "210" to "maimaidx_splash", "215" to "maimaidx_splash_plus",
            "220" to "maimaidx_universe", "225" to "maimaidx_universe_plus",
            "230" to "maimaidx_festival", "235" to "maimaidx_festival_plus",
            "240" to "maimaidx_buddies", "245" to "maimaidx_buddies_plus",
            "250" to "maimaidx_prism", "255" to "maimaidx_prism_plus",
            "260" to "maimaidx_circle", "265" to "maimaidx_circle_plus",
            "270" to "maimaidx_magical"
        )
        return map.firstOrNull { versionCode.startsWith(it.first) }?.second
    }

    fun jpVersionFallbackTitle(versionCode: String): String {
        val trimmed = versionCode.trim()
        if (trimmed.isEmpty()) return "暂无数据"
        if (trimmed.startsWith("265")) return "maimai でらっくす CiRCLE PLUS"
        if (trimmed.startsWith("270")) return "maimai でらっくす MAGiCAL"
        return "Ver. $trimmed"
    }

    fun cnVersionAsset(fromName: String): String? =
        cnVersions.firstOrNull { it.name == fromName }?.asset

    fun jpVersionAssetByName(fromName: String): String? =
        jpVersions.firstOrNull { it.name == fromName }?.asset

    @Serializable
    enum class ServerRegion(val rawValue: String) {
        @SerialName("cn") CN("cn"),
        @SerialName("intl") INTL("intl"),
        @SerialName("jp") JP("jp");

        val displayName: String
            get() = when (this) {
                CN -> "国服（舞萌DX）"
                INTL -> "国际服（International）"
                JP -> "日服（日本版）"
            }

        val shortName: String
            get() = when (this) {
                CN -> "国服"
                INTL -> "国际服"
                JP -> "日服"
            }

        val usesAPBonus: Boolean
            get() = when (this) {
                CN -> false
                INTL, JP -> true
            }

        companion object {
            fun fromRawValue(raw: String?): ServerRegion =
                entries.firstOrNull { it.rawValue == raw } ?: CN
        }
    }

    enum class RankIconTheme(val rawValue: String) {
        PRISM("prism"),
        CIRCLE("circle")
    }

    val validRankKeys: Set<String> = setOf(
        "d", "c", "b", "bb", "bbb", "a", "aa", "aaa", "s", "sp", "ss", "ssp", "sss", "sssp"
    )

    fun rankIconTheme(region: ServerRegion): RankIconTheme = when (region) {
        ServerRegion.CN -> RankIconTheme.PRISM
        ServerRegion.INTL, ServerRegion.JP -> RankIconTheme.CIRCLE
    }

    fun rankAssetName(rate: String, region: ServerRegion): String {
        val lower = rate.lowercase()
        if (lower == "ap" || lower == "app") {
            return "mmd_player_rtsong_$lower"
        }
        val safeRate = if (lower in validRankKeys) lower else "d"
        return "mmd_rank_${rankIconTheme(region).rawValue}_$safeRate"
    }

    fun activeServerVersionDisplay(
        info: SongData.BasicInfo,
        region: ServerRegion = ServerRegion.CN
    ): Pair<String?, String> = when (region) {
        ServerRegion.CN -> {
            val asset = cnVersionAsset(info.from)
            val fallback = info.from.ifEmpty { "暂无数据" }
            asset to fallback
        }
        ServerRegion.JP, ServerRegion.INTL -> {
            val asset = jpVersionAssetByName(info.from) ?: jpVersionAsset(info.version)
            val fallback = info.from.ifEmpty { jpVersionFallbackTitle(info.version) }
            asset to fallback
        }
    }

    /** Compile-time R8-safe asset name -> R.drawable lookup (zero reflection). */
    private val drawableMap: Map<String, Int> = mapOf(
        "ic_deluxe" to R.drawable.ic_deluxe,
        "ic_standard" to R.drawable.ic_standard,
        "maimai" to R.drawable.maimai,
        "maimai_finale" to R.drawable.maimai_finale,
        "maimai_green" to R.drawable.maimai_green,
        "maimai_green_plus" to R.drawable.maimai_green_plus,
        "maimai_milk" to R.drawable.maimai_milk,
        "maimai_milk_plus" to R.drawable.maimai_milk_plus,
        "maimai_murasaki" to R.drawable.maimai_murasaki,
        "maimai_murasaki_plus" to R.drawable.maimai_murasaki_plus,
        "maimai_orange" to R.drawable.maimai_orange,
        "maimai_orange_plus" to R.drawable.maimai_orange_plus,
        "maimai_pink" to R.drawable.maimai_pink,
        "maimai_pink_plus" to R.drawable.maimai_pink_plus,
        "maimai_plus" to R.drawable.maimai_plus,
        "maimaidx" to R.drawable.maimaidx,
        "maimaidx_2021" to R.drawable.maimaidx_2021,
        "maimaidx_2022" to R.drawable.maimaidx_2022,
        "maimaidx_2023" to R.drawable.maimaidx_2023,
        "maimaidx_2024" to R.drawable.maimaidx_2024,
        "maimaidx_2025" to R.drawable.maimaidx_2025,
        "maimaidx_2026" to R.drawable.maimaidx_2026,
        "maimaidx_buddies" to R.drawable.maimaidx_buddies,
        "maimaidx_buddies_plus" to R.drawable.maimaidx_buddies_plus,
        "maimaidx_circle" to R.drawable.maimaidx_circle,
        "maimaidx_circle_plus" to R.drawable.maimaidx_circle_plus,
        "maimaidx_cn" to R.drawable.maimaidx_cn,
        "maimaidx_festival" to R.drawable.maimaidx_festival,
        "maimaidx_festival_plus" to R.drawable.maimaidx_festival_plus,
        "maimaidx_magical" to R.drawable.maimaidx_magical,
        "maimaidx_plus" to R.drawable.maimaidx_plus,
        "maimaidx_prism" to R.drawable.maimaidx_prism,
        "maimaidx_prism_plus" to R.drawable.maimaidx_prism_plus,
        "maimaidx_splash" to R.drawable.maimaidx_splash,
        "maimaidx_splash_plus" to R.drawable.maimaidx_splash_plus,
        "maimaidx_universe" to R.drawable.maimaidx_universe,
        "maimaidx_universe_plus" to R.drawable.maimaidx_universe_plus,
        "mmd_player_best50" to R.drawable.mmd_player_best50,
        "mmd_player_name_box" to R.drawable.mmd_player_name_box,
        "mmd_player_num_drating_0" to R.drawable.mmd_player_num_drating_0,
        "mmd_player_num_drating_1" to R.drawable.mmd_player_num_drating_1,
        "mmd_player_num_drating_2" to R.drawable.mmd_player_num_drating_2,
        "mmd_player_num_drating_3" to R.drawable.mmd_player_num_drating_3,
        "mmd_player_num_drating_4" to R.drawable.mmd_player_num_drating_4,
        "mmd_player_num_drating_5" to R.drawable.mmd_player_num_drating_5,
        "mmd_player_num_drating_6" to R.drawable.mmd_player_num_drating_6,
        "mmd_player_num_drating_7" to R.drawable.mmd_player_num_drating_7,
        "mmd_player_num_drating_8" to R.drawable.mmd_player_num_drating_8,
        "mmd_player_num_drating_9" to R.drawable.mmd_player_num_drating_9,
        "mmd_player_rating_box" to R.drawable.mmd_player_rating_box,
        "mmd_player_rtsong_ap" to R.drawable.mmd_player_rtsong_ap,
        "mmd_player_rtsong_app" to R.drawable.mmd_player_rtsong_app,
        "mmd_player_rtsong_fc" to R.drawable.mmd_player_rtsong_fc,
        "mmd_player_rtsong_fcp" to R.drawable.mmd_player_rtsong_fcp,
        "mmd_player_rtsong_fs" to R.drawable.mmd_player_rtsong_fs,
        "mmd_player_rtsong_fsd" to R.drawable.mmd_player_rtsong_fsd,
        "mmd_player_rtsong_fsdp" to R.drawable.mmd_player_rtsong_fsdp,
        "mmd_player_rtsong_fsp" to R.drawable.mmd_player_rtsong_fsp,
        "mmd_player_rtsong_icon_dx" to R.drawable.mmd_player_rtsong_icon_dx,
        "mmd_player_rtsong_icon_standard" to R.drawable.mmd_player_rtsong_icon_standard,
        "mmd_rank_circle_a" to R.drawable.mmd_rank_circle_a,
        "mmd_rank_circle_aa" to R.drawable.mmd_rank_circle_aa,
        "mmd_rank_circle_aaa" to R.drawable.mmd_rank_circle_aaa,
        "mmd_rank_circle_b" to R.drawable.mmd_rank_circle_b,
        "mmd_rank_circle_bb" to R.drawable.mmd_rank_circle_bb,
        "mmd_rank_circle_bbb" to R.drawable.mmd_rank_circle_bbb,
        "mmd_rank_circle_c" to R.drawable.mmd_rank_circle_c,
        "mmd_rank_circle_d" to R.drawable.mmd_rank_circle_d,
        "mmd_rank_circle_s" to R.drawable.mmd_rank_circle_s,
        "mmd_rank_circle_sp" to R.drawable.mmd_rank_circle_sp,
        "mmd_rank_circle_ss" to R.drawable.mmd_rank_circle_ss,
        "mmd_rank_circle_ssp" to R.drawable.mmd_rank_circle_ssp,
        "mmd_rank_circle_sss" to R.drawable.mmd_rank_circle_sss,
        "mmd_rank_circle_sssp" to R.drawable.mmd_rank_circle_sssp,
        "mmd_rank_prism_a" to R.drawable.mmd_rank_prism_a,
        "mmd_rank_prism_aa" to R.drawable.mmd_rank_prism_aa,
        "mmd_rank_prism_aaa" to R.drawable.mmd_rank_prism_aaa,
        "mmd_rank_prism_b" to R.drawable.mmd_rank_prism_b,
        "mmd_rank_prism_bb" to R.drawable.mmd_rank_prism_bb,
        "mmd_rank_prism_bbb" to R.drawable.mmd_rank_prism_bbb,
        "mmd_rank_prism_c" to R.drawable.mmd_rank_prism_c,
        "mmd_rank_prism_d" to R.drawable.mmd_rank_prism_d,
        "mmd_rank_prism_s" to R.drawable.mmd_rank_prism_s,
        "mmd_rank_prism_sp" to R.drawable.mmd_rank_prism_sp,
        "mmd_rank_prism_ss" to R.drawable.mmd_rank_prism_ss,
        "mmd_rank_prism_ssp" to R.drawable.mmd_rank_prism_ssp,
        "mmd_rank_prism_sss" to R.drawable.mmd_rank_prism_sss,
        "mmd_rank_prism_sssp" to R.drawable.mmd_rank_prism_sssp,
        "mmd_rating_board_adv" to R.drawable.mmd_rating_board_adv,
        "mmd_rating_board_bsc" to R.drawable.mmd_rating_board_bsc,
        "mmd_rating_board_exp" to R.drawable.mmd_rating_board_exp,
        "mmd_rating_board_mas" to R.drawable.mmd_rating_board_mas,
        "mmd_rating_board_rem" to R.drawable.mmd_rating_board_rem,
        "mmd_rating_diff_advanced" to R.drawable.mmd_rating_diff_advanced,
        "mmd_rating_diff_basic" to R.drawable.mmd_rating_diff_basic,
        "mmd_rating_diff_expert" to R.drawable.mmd_rating_diff_expert,
        "mmd_rating_diff_master" to R.drawable.mmd_rating_diff_master,
        "mmd_rating_diff_remaster" to R.drawable.mmd_rating_diff_remaster,
        "mmd_rating_plate_blue" to R.drawable.mmd_rating_plate_blue,
        "mmd_rating_plate_bronze" to R.drawable.mmd_rating_plate_bronze,
        "mmd_rating_plate_gold" to R.drawable.mmd_rating_plate_gold,
        "mmd_rating_plate_green" to R.drawable.mmd_rating_plate_green,
        "mmd_rating_plate_normal" to R.drawable.mmd_rating_plate_normal,
        "mmd_rating_plate_orange" to R.drawable.mmd_rating_plate_orange,
        "mmd_rating_plate_platinum" to R.drawable.mmd_rating_plate_platinum,
        "mmd_rating_plate_purple" to R.drawable.mmd_rating_plate_purple,
        "mmd_rating_plate_rainbow" to R.drawable.mmd_rating_plate_rainbow,
        "mmd_rating_plate_red" to R.drawable.mmd_rating_plate_red,
        "mmd_rating_plate_silver" to R.drawable.mmd_rating_plate_silver,
        "mmd_song_jacket_placeholder" to R.drawable.mmd_song_jacket_placeholder
    )

    fun drawableResId(assetName: String): Int? = drawableMap[assetName]
}
