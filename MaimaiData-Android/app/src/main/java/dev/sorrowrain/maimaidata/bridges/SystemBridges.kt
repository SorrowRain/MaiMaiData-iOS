package dev.sorrowrain.maimaidata.bridges

import android.app.Activity
import android.content.ClipData
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.browser.customtabs.CustomTabColorSchemeParams
import androidx.browser.customtabs.CustomTabsIntent
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Download
import androidx.compose.material.icons.rounded.Share
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.core.content.FileProvider
import dev.sorrowrain.maimaidata.models.SongData
import dev.sorrowrain.maimaidata.services.CoverImageManager
import dev.sorrowrain.maimaidata.services.CoverImageView
import dev.sorrowrain.maimaidata.theme.AppTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

/**
 * Saves PNG bitmaps into `Pictures/MaimaiData` via [MediaStore.Images.Media] on [Dispatchers.IO].
 */
object MediaStoreSaver {
    suspend fun saveBitmapToGallery(
        context: Context,
        bitmap: Bitmap,
        displayNamePrefix: String = "MaimaiData"
    ): Result<Unit> = withContext(Dispatchers.IO) {
        runCatching {
            val safePrefix = sanitizeFilePrefix(displayNamePrefix)
            val fileName = "${safePrefix}_${System.currentTimeMillis()}.png"
            val resolver = context.contentResolver

            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                put(MediaStore.Images.Media.DATE_ADDED, System.currentTimeMillis() / 1000L)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/MaimaiData")
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }
            }

            val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            } else {
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            }

            val uri = resolver.insert(collection, values)
                ?: throw IOException("无法创建系统相册记录")

            try {
                val exportBitmap = ensureSoftwareBitmap(bitmap)
                resolver.openOutputStream(uri)?.use { out ->
                    if (!exportBitmap.compress(Bitmap.CompressFormat.PNG, 100, out)) {
                        throw IOException("PNG 图片写入失败")
                    }
                    out.flush()
                } ?: throw IOException("无法打开系统相册写入流")

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val completeValues = ContentValues().apply {
                        put(MediaStore.Images.Media.IS_PENDING, 0)
                    }
                    resolver.update(uri, completeValues, null, null)
                }
            } catch (e: Throwable) {
                runCatching { resolver.delete(uri, null, null) }
                throw e
            }
        }
    }
}

/**
 * Shares a PNG [Bitmap] via [FileProvider] (`cacheDir/shared_images`) and Android's system Sharesheet.
 */
object ShareBridge {
    fun shareBitmap(
        context: Context,
        bitmap: Bitmap,
        fileNamePrefix: String = "MaimaiData_B50"
    ) {
        val uri = writeSharedBitmapUri(context, bitmap, fileNamePrefix)
        launchShareChooser(context, uri, fileNamePrefix)
    }

    suspend fun shareBitmapAsync(
        context: Context,
        bitmap: Bitmap,
        fileNamePrefix: String = "MaimaiData_B50"
    ): Result<Unit> = runCatching {
        val uri = withContext(Dispatchers.IO) {
            writeSharedBitmapUri(context, bitmap, fileNamePrefix)
        }
        withContext(Dispatchers.Main) {
            launchShareChooser(context, uri, fileNamePrefix)
        }
    }

    private fun writeSharedBitmapUri(
        context: Context,
        bitmap: Bitmap,
        fileNamePrefix: String
    ): Uri {
        val sharedDir = File(context.cacheDir, "shared_images").apply { mkdirs() }
        val now = System.currentTimeMillis()
        sharedDir.listFiles()?.forEach { existing ->
            if (now - existing.lastModified() > 3_600_000L) {
                runCatching { existing.delete() }
            }
        }

        val safePrefix = sanitizeFilePrefix(fileNamePrefix)
        val outFile = File(sharedDir, "${safePrefix}_$now.png")
        val exportBitmap = ensureSoftwareBitmap(bitmap)
        FileOutputStream(outFile).use { out ->
            if (!exportBitmap.compress(Bitmap.CompressFormat.PNG, 100, out)) {
                throw IOException("生成分享图片失败")
            }
            out.flush()
        }

        return FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            outFile
        )
    }

    private fun launchShareChooser(
        context: Context,
        uri: Uri,
        label: String
    ) {
        val sendIntent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            clipData = ClipData.newRawUri(label, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        val chooser = Intent.createChooser(sendIntent, "分享图片").apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            if (context !is Activity) {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }
        context.startActivity(chooser)
    }
}

/**
 * Launches Chrome Custom Tabs with brand toolbar color `#1668DC`, falling back to `ACTION_VIEW`.
 */
object CustomTabOAuthLauncher {
    private const val BRAND_TOOLBAR_COLOR = 0xFF1668DC.toInt()

    fun launch(context: Context, url: String) {
        val uri = Uri.parse(url)
        try {
            val colorParams = CustomTabColorSchemeParams.Builder()
                .setToolbarColor(BRAND_TOOLBAR_COLOR)
                .build()
            val customTabsIntent = CustomTabsIntent.Builder()
                .setDefaultColorSchemeParams(colorParams)
                .setShowTitle(true)
                .build()
            if (context !is Activity) {
                customTabsIntent.intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            customTabsIntent.launchUrl(context, uri)
        } catch (_: Exception) {
            val fallback = Intent(Intent.ACTION_VIEW, uri).apply {
                if (context !is Activity) {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            }
            runCatching { context.startActivity(fallback) }
        }
    }
}

/**
 * Interactive pinch-to-zoom (`1.0x`–`4.5x`), bounded pan, and double-tap (`1.0x` / `2.5x`) container.
 */
@Composable
fun ZoomableImageBox(
    modifier: Modifier = Modifier,
    minScale: Float = 1.0f,
    maxScale: Float = 4.5f,
    doubleTapScale: Float = 2.5f,
    content: @Composable BoxScope.() -> Unit
) {
    val scope = rememberCoroutineScope()
    val scaleAnim = remember { Animatable(1f) }
    val offsetXAnim = remember { Animatable(0f) }
    val offsetYAnim = remember { Animatable(0f) }
    var containerSize by remember { mutableStateOf(IntSize.Zero) }

    Box(
        modifier = modifier
            .clipToBounds()
            .onSizeChanged { containerSize = it }
            .pointerInput(minScale, maxScale, doubleTapScale) {
                detectTapGestures(
                    onDoubleTap = { tapOffset ->
                        if (scaleAnim.value > 1.05f) {
                            scope.launch {
                                launch { scaleAnim.animateTo(1f, tween(220)) }
                                launch { offsetXAnim.animateTo(0f, tween(220)) }
                                launch { offsetYAnim.animateTo(0f, tween(220)) }
                            }
                        } else {
                            val targetScale = doubleTapScale.coerceIn(minScale, maxScale)
                            val centerX = containerSize.width / 2f
                            val centerY = containerSize.height / 2f
                            val rawX = (centerX - tapOffset.x) * (targetScale - 1f)
                            val rawY = (centerY - tapOffset.y) * (targetScale - 1f)
                            val clamped = clampPanOffset(rawX, rawY, targetScale, containerSize)
                            scope.launch {
                                launch { scaleAnim.animateTo(targetScale, tween(220)) }
                                launch { offsetXAnim.animateTo(clamped.x, tween(220)) }
                                launch { offsetYAnim.animateTo(clamped.y, tween(220)) }
                            }
                        }
                    }
                )
            }
            .pointerInput(minScale, maxScale) {
                detectTransformGestures { _, pan, zoom, _ ->
                    val newScale = (scaleAnim.value * zoom).coerceIn(minScale, maxScale)
                    val rawX = if (newScale > 1.001f) offsetXAnim.value + pan.x else 0f
                    val rawY = if (newScale > 1.001f) offsetYAnim.value + pan.y else 0f
                    val clamped = clampPanOffset(rawX, rawY, newScale, containerSize)
                    scope.launch {
                        scaleAnim.snapTo(newScale)
                        offsetXAnim.snapTo(clamped.x)
                        offsetYAnim.snapTo(clamped.y)
                    }
                }
            },
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer {
                    scaleX = scaleAnim.value
                    scaleY = scaleAnim.value
                    translationX = offsetXAnim.value
                    translationY = offsetYAnim.value
                },
            contentAlignment = Alignment.Center,
            content = content
        )
    }
}

/**
 * Convenience composable rendering a [Bitmap] inside [ZoomableImageBox].
 */
@Composable
fun ZoomableBitmapPreview(
    bitmap: Bitmap,
    contentDescription: String?,
    modifier: Modifier = Modifier
) {
    val imageBitmap = remember(bitmap) { bitmap.asImageBitmap() }
    ZoomableImageBox(modifier = modifier) {
        Image(
            bitmap = imageBitmap,
            contentDescription = contentDescription,
            contentScale = ContentScale.Fit,
            modifier = Modifier
                .fillMaxSize()
                .padding(AppTheme.Space.m)
        )
    }
}

/**
 * Full-screen edge-to-edge black photo preview dialog supporting `1.0x`–`4.5x` pinch-to-zoom,
 * pan, double-tap `1x`/`2.5x` toggle, top bar close button, and bottom **保存相册** / **分享** actions.
 */
@Composable
fun PhotoPreviewDialog(
    title: String,
    bitmap: Bitmap?,
    songForCover: SongData? = null,
    onDismiss: () -> Unit,
    onSavedToast: (String) -> Unit = {},
    onError: (String) -> Unit = {}
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var fallbackBitmap by remember(songForCover?.id) { mutableStateOf<Bitmap?>(null) }
    var isSaving by remember { mutableStateOf(false) }
    var isSharing by remember { mutableStateOf(false) }

    val effectiveBitmap = bitmap ?: fallbackBitmap

    LaunchedEffect(bitmap, songForCover?.id) {
        if (bitmap == null && songForCover != null && fallbackBitmap == null) {
            fallbackBitmap = CoverImageManager.loadCoverBitmap(
                context = context,
                song = songForCover,
                targetPx = 0
            )
        }
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            usePlatformDefaultWidth = false,
            decorFitsSystemWindows = false
        )
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black)
        ) {
            // Zoomable center viewport
            when {
                effectiveBitmap != null -> {
                    ZoomableBitmapPreview(
                        bitmap = effectiveBitmap,
                        contentDescription = "$title，可双击或双指缩放",
                        modifier = Modifier.fillMaxSize()
                    )
                }
                songForCover != null -> {
                    ZoomableImageBox(modifier = Modifier.fillMaxSize()) {
                        CoverImageView(
                            song = songForCover,
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(AppTheme.Space.l),
                            contentScale = ContentScale.Fit
                        )
                    }
                }
                else -> {
                    Column(
                        modifier = Modifier.align(Alignment.Center),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(AppTheme.Space.m)
                    ) {
                        CircularProgressIndicator(
                            color = Color.White,
                            strokeWidth = 2.5.dp,
                            modifier = Modifier.size(32.dp)
                        )
                        Text(
                            text = "正在加载图片…",
                            style = AppTheme.AppTypography.caption,
                            color = Color.White.copy(alpha = 0.75f)
                        )
                    }
                }
            }

            // Top bar with subtle gradient scrim + title + close button
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .align(Alignment.TopCenter)
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(Color.Black.copy(alpha = 0.72f), Color.Transparent)
                        )
                    )
                    .statusBarsPadding()
                    .padding(horizontal = AppTheme.pagePadding, vertical = AppTheme.Space.s),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(AppTheme.Space.m)
            ) {
                Text(
                    text = title,
                    style = AppTheme.AppTypography.cardTitle,
                    color = Color.White,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )

                Surface(
                    shape = CircleShape,
                    color = Color.White.copy(alpha = 0.14f),
                    contentColor = Color.White
                ) {
                    IconButton(
                        onClick = onDismiss,
                        modifier = Modifier.size(36.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Rounded.Close,
                            contentDescription = "关闭",
                            tint = Color.White,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            }

            // Bottom action bar with 保存相册 & 分享 buttons
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .align(Alignment.BottomCenter)
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.80f))
                        )
                    )
                    .navigationBarsPadding()
                    .padding(horizontal = AppTheme.pagePadding, vertical = AppTheme.Space.m),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(AppTheme.Space.m)
            ) {
                OutlinedButton(
                    onClick = {
                        val target = effectiveBitmap ?: return@OutlinedButton
                        isSharing = true
                        scope.launch {
                            ShareBridge.shareBitmapAsync(
                                context = context,
                                bitmap = target,
                                fileNamePrefix = if (songForCover != null) {
                                    "MaimaiData_Cover_${songForCover.id}"
                                } else {
                                    "MaimaiData_B50"
                                }
                            ).onFailure { err ->
                                onError(err.message ?: "分享失败")
                            }
                            isSharing = false
                        }
                    },
                    enabled = effectiveBitmap != null && !isSharing,
                    shape = RoundedCornerShape(AppTheme.Radius.button),
                    colors = ButtonDefaults.outlinedButtonColors(
                        containerColor = Color.White.copy(alpha = 0.12f),
                        contentColor = Color.White,
                        disabledContainerColor = Color.White.copy(alpha = 0.05f),
                        disabledContentColor = Color.White.copy(alpha = 0.40f)
                    ),
                    border = BorderStroke(1.dp, Color.White.copy(alpha = 0.28f)),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 0.dp),
                    modifier = Modifier
                        .weight(1f)
                        .defaultMinSize(minHeight = 48.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(AppTheme.Space.s)
                    ) {
                        Icon(
                            imageVector = Icons.Rounded.Share,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp)
                        )
                        Text(
                            text = "分享",
                            style = AppTheme.AppTypography.songTitle
                        )
                    }
                }

                Button(
                    onClick = {
                        val target = effectiveBitmap ?: return@Button
                        isSaving = true
                        scope.launch {
                            MediaStoreSaver.saveBitmapToGallery(
                                context = context,
                                bitmap = target,
                                displayNamePrefix = if (songForCover != null) {
                                    "MaimaiData_Cover_${songForCover.id}"
                                } else {
                                    "MaimaiData_B50"
                                }
                            ).fold(
                                onSuccess = { onSavedToast("已保存到系统相册") },
                                onFailure = { err -> onError(err.message ?: "保存相册失败") }
                            )
                            isSaving = false
                        }
                    },
                    enabled = effectiveBitmap != null && !isSaving,
                    shape = RoundedCornerShape(AppTheme.Radius.button),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = AppTheme.accent,
                        contentColor = Color.White,
                        disabledContainerColor = AppTheme.accent.copy(alpha = 0.45f),
                        disabledContentColor = Color.White.copy(alpha = 0.70f)
                    ),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 0.dp),
                    modifier = Modifier
                        .weight(1f)
                        .defaultMinSize(minHeight = 48.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(AppTheme.Space.s)
                    ) {
                        if (isSaving) {
                            CircularProgressIndicator(
                                color = Color.White,
                                strokeWidth = 2.dp,
                                modifier = Modifier.size(18.dp)
                            )
                        } else {
                            Icon(
                                imageVector = Icons.Rounded.Download,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp)
                            )
                        }
                        Text(
                            text = "保存相册",
                            style = AppTheme.AppTypography.songTitle
                        )
                    }
                }
            }
        }
    }
}

private fun clampPanOffset(
    rawX: Float,
    rawY: Float,
    scale: Float,
    size: IntSize
): Offset {
    if (scale <= 1.001f || size.width <= 0 || size.height <= 0) {
        return Offset.Zero
    }
    val maxX = (size.width * (scale - 1f)) / 2f
    val maxY = (size.height * (scale - 1f)) / 2f
    return Offset(
        x = rawX.coerceIn(-maxX, maxX),
        y = rawY.coerceIn(-maxY, maxY)
    )
}

private fun ensureSoftwareBitmap(bitmap: Bitmap): Bitmap {
    return if (bitmap.config == Bitmap.Config.HARDWARE) {
        bitmap.copy(Bitmap.Config.ARGB_8888, false) ?: bitmap
    } else {
        bitmap
    }
}

private fun sanitizeFilePrefix(raw: String): String {
    val cleaned = raw.replace(Regex("[^A-Za-z0-9_\\-]"), "_").trim('_')
    return cleaned.ifEmpty { "MaimaiData" }
}
