package dev.sorrowrain.maimaidata.views

import androidx.compose.runtime.Composable
import dev.sorrowrain.maimaidata.bridges.PhotoPreviewDialog
import dev.sorrowrain.maimaidata.models.SongData

@Composable
fun CoverZoomDialog(
    song: SongData,
    onDismiss: () -> Unit,
    onSavedToast: (String) -> Unit = {},
    onError: (String) -> Unit = {}
) {
    PhotoPreviewDialog(
        title = song.title,
        bitmap = null,
        songForCover = song,
        onDismiss = onDismiss,
        onSavedToast = onSavedToast,
        onError = onError
    )
}
