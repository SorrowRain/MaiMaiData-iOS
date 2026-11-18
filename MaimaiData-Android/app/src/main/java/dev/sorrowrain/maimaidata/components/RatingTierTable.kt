package dev.sorrowrain.maimaidata.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import dev.sorrowrain.maimaidata.models.MaimaiConstants
import dev.sorrowrain.maimaidata.models.RatingCalculator
import dev.sorrowrain.maimaidata.theme.AppTheme

/**
 * Shared 2-column / 3-column achievement-to-Rating reference table used by `SongDetailView` and `RatingCalculatorView`.
 */
@Composable
fun RatingTierTable(
    rows: List<RatingCalculator.TierRow>,
    showB50Column: Boolean = false,
    region: MaimaiConstants.ServerRegion = MaimaiConstants.ServerRegion.CN,
    modifier: Modifier = Modifier
) {
    AppInsetGroup(modifier = modifier) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = AppTheme.Space.m, vertical = AppTheme.Space.s),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(AppTheme.Space.s)
        ) {
            Text(
                text = "达成率 / 等级",
                style = AppTheme.AppTypography.caption2Bold,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                modifier = Modifier.weight(1f)
            )
            if (showB50Column) {
                Text(
                    text = "单曲分",
                    style = AppTheme.AppTypography.caption2Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.width(72.dp)
                )
                Text(
                    text = "B50 可加",
                    style = AppTheme.AppTypography.caption2Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.width(72.dp)
                )
            } else {
                Text(
                    text = "单曲分",
                    style = AppTheme.AppTypography.caption2Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.weight(1f)
                )
            }
        }

        rows.forEach { row ->
            AppInsetDivider()
            TierRowItem(
                row = row,
                showB50Column = showB50Column,
                region = region
            )
        }
    }
}

@Composable
private fun TierRowItem(
    row: RatingCalculator.TierRow,
    showB50Column: Boolean,
    region: MaimaiConstants.ServerRegion
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .appInsetRowHighlight(row.isCurrentTier)
            .alpha(if (row.isPassed) 0.52f else 1f)
            .semantics(mergeDescendants = true) {}
            .padding(horizontal = AppTheme.Space.m, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(AppTheme.Space.s)
    ) {
        Box(
            modifier = Modifier.weight(1f),
            contentAlignment = Alignment.Center
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(AppTheme.Space.xs)
            ) {
                TierRankSprite(row = row, region = region)

                Text(
                    text = row.achievementText,
                    style = AppTheme.AppTypography.captionMono,
                    color = MaterialTheme.colorScheme.onSurface,
                    textAlign = TextAlign.End,
                    maxLines = 1,
                    softWrap = false,
                    modifier = Modifier.defaultMinSize(minWidth = 74.dp)
                )
            }
        }

        if (showB50Column) {
            Text(
                text = "${row.singleRating}",
                style = AppTheme.AppTypography.captionMeta,
                color = MaterialTheme.colorScheme.onSurface,
                textAlign = TextAlign.Center,
                maxLines = 1,
                softWrap = false,
                modifier = Modifier.width(72.dp)
            )

            val gain = row.b50Gain ?: 0
            if (gain > 0) {
                Text(
                    text = "+$gain",
                    style = AppTheme.AppTypography.captionMetaBold,
                    color = AppTheme.accentText,
                    textAlign = TextAlign.Center,
                    maxLines = 1,
                    softWrap = false,
                    modifier = Modifier.width(72.dp)
                )
            } else {
                Text(
                    text = "—",
                    style = AppTheme.AppTypography.captionMono,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.60f),
                    textAlign = TextAlign.Center,
                    maxLines = 1,
                    softWrap = false,
                    modifier = Modifier.width(72.dp)
                )
            }
        } else {
            Text(
                text = "${row.singleRating}",
                style = AppTheme.AppTypography.captionMeta,
                color = MaterialTheme.colorScheme.onSurface,
                textAlign = TextAlign.Center,
                maxLines = 1,
                softWrap = false,
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun TierRankSprite(
    row: RatingCalculator.TierRow,
    region: MaimaiConstants.ServerRegion
) {
    val resId = MaimaiConstants.drawableResId(row.badgeAssetName(region))
    Box(
        modifier = Modifier.size(width = 46.dp, height = 18.dp),
        contentAlignment = Alignment.CenterStart
    ) {
        if (resId != null) {
            if (row.isAPRow) {
                Box(
                    modifier = Modifier.size(width = 38.4.dp, height = 18.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Image(
                        painter = painterResource(resId),
                        contentDescription = "AP",
                        contentScale = ContentScale.Fit,
                        modifier = Modifier.size(20.dp)
                    )
                }
            } else {
                Image(
                    painter = painterResource(resId),
                    contentDescription = row.rate.uppercase(),
                    contentScale = ContentScale.Fit,
                    modifier = Modifier
                        .height(18.dp)
                        .offset(x = opticalLetterOffset(row.rate, region))
                )
            }
        }
    }
}

private fun opticalLetterOffset(
    rate: String,
    region: MaimaiConstants.ServerRegion
): Dp = when (MaimaiConstants.rankIconTheme(region)) {
    MaimaiConstants.RankIconTheme.PRISM -> when (rate) {
        "sssp" -> 2.25.dp
        "ssp" -> 2.40.dp
        "sp" -> 2.55.dp
        else -> 0.dp
    }
    MaimaiConstants.RankIconTheme.CIRCLE -> when (rate) {
        "sssp" -> 2.55.dp
        "ssp" -> 2.25.dp
        "sp" -> 3.45.dp
        else -> 0.dp
    }
}
