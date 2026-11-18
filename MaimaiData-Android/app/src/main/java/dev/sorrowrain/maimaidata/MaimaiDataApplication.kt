package dev.sorrowrain.maimaidata

import android.app.Application
import dev.sorrowrain.maimaidata.services.CoverImageManager
import dev.sorrowrain.maimaidata.services.DataStore

class MaimaiDataApplication : Application() {
    lateinit var dataStore: DataStore
        private set

    override fun onCreate() {
        super.onCreate()
        CoverImageManager.imageLoader(this)
        dataStore = DataStore(this)
        dataStore.launchBootstrap()
    }
}
