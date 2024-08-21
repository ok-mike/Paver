// Android version of a Paverho/Sonne-16 simulator
// Copyr. 2018 Michael Mangelsdorf (mim@ok-schalter.de)

#include <jni.h>

#include <sys/types.h>
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <android/log.h>
#include <android/input.h>
#include <GLES3/gl3.h>

#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <math.h>
#include <pthread.h>

enum Phase {CREATE=0, RESTORE=1, PAUSE=2, SAVE=3, EXIT=4};


extern double viewaspect;

int phos_runthread(void *(*start_routine) (void *));

extern const char* phos_applicationpath;
extern void phos_cb_touch( int action, int id, float x, float y );
extern void line_ready(const char* linestr);
extern void application_phase(enum Phase e);
extern void draw_frame(void);
extern void update_model(void);

extern "C" {
JNIEXPORT void JNICALL Java_de_okschalter_paverho_PhosGlue_handleTouch(
        JNIEnv* env, jobject obj, jint action, jint id, jfloat x, jfloat y);

JNIEXPORT void JNICALL Java_de_okschalter_paverho_PhosGlue_lineReady(
        JNIEnv* env, jobject obj, jstring lineStr);

JNIEXPORT void JNICALL Java_de_okschalter_paverho_PhosGlue_init(
        JNIEnv* env, jobject obj, jobject assetManager, jstring dataDirPath);

JNIEXPORT void JNICALL Java_de_okschalter_paverho_PhosGlue_changed(
        JNIEnv* env, jobject obj, jint width, jint height);

JNIEXPORT void JNICALL Java_de_okschalter_paverho_PhosGlue_step(
        JNIEnv* env, jobject obj);

JNIEXPORT void JNICALL Java_de_okschalter_paverho_PhosGlue_phase(
        JNIEnv* env, jobject obj, jint e);
};

AAssetManager* mgr;

char*
getAssetPtr( const char* fname, size_t *length)
{
    char* buffer = NULL;
    size_t assetLength = 0;
    AAsset* asset = AAssetManager_open( mgr, fname, AASSET_MODE_UNKNOWN);
    if (asset)
    {
        assetLength = (size_t)AAsset_getLength(asset);
        buffer = (char*) malloc( assetLength + 1 );
        AAsset_read(asset, buffer, assetLength);
        buffer[assetLength] = 0;
        AAsset_close(asset);
        //free(buffer);
    }
    *length = assetLength + 1;
    //__android_log_print(ANDROID_LOG_VERBOSE, "Phos", "asset ptr: %s %p ", fname, buffer );
    return buffer;
}


/*
 * Pass through multi-touch events to Phos
 */
JNIEXPORT void JNICALL
Java_de_okschalter_paverho_PhosGlue_handleTouch(
        JNIEnv* env, jobject obj, jint action, jint id, jfloat x, jfloat y)
{
    phos_cb_touch( (int)action, (int)id, x, y );
}

/*
 * Pass through an input line from device keyboard to Phos
 */
JNIEXPORT void JNICALL
Java_de_okschalter_paverho_PhosGlue_lineReady(
        JNIEnv * env, jobject obj, jstring lineStr)
{
    line_ready(env->GetStringUTFChars( lineStr, 0));
}


/*
 * Called once in GLSurfaceView.Renderer method onSurfaceCreated)
 */
JNIEXPORT void JNICALL
Java_de_okschalter_paverho_PhosGlue_changed(
        JNIEnv * env, jobject obj, jint w, jint h)
{
    glViewport(0, 0, w, h);
    if (w>h) viewaspect = fabs(w / h); else viewaspect = fabs (h/w);
}


/*
 * Called once in view constructor
 */
JNIEXPORT void JNICALL
Java_de_okschalter_paverho_PhosGlue_init(
        JNIEnv * env, jobject obj, jobject assetManager, jstring dataDirPath)
{
    mgr = AAssetManager_fromJava(env, assetManager);
    phos_applicationpath = env->GetStringUTFChars(dataDirPath, 0);
    //__android_log_print(ANDROID_LOG_VERBOSE, "Phos", "appPath: %s ", appPath );

    application_phase(CREATE);
    __android_log_print(ANDROID_LOG_VERBOSE, "Phos", "Init done! i=%d ", 5 );
}


/*
 * Called for each frame (GLSurfaceView.Renderer method onDrawFrame)
 */
JNIEXPORT void JNICALL
Java_de_okschalter_paverho_PhosGlue_step(
        JNIEnv * env, jobject obj)
{
    update_model();
    draw_frame();
}


/*
 * Called for application phase transitions such as create, pause etc
 */
JNIEXPORT void JNICALL
Java_de_okschalter_paverho_PhosGlue_phase(
        JNIEnv * env, jobject obj, jint e)
{
    application_phase( (enum Phase) e);
}


int phos_runthread(void *(*start_routine) (void *))
{
    pthread_t t;
    pthread_create(&t, NULL, start_routine, NULL);
    return 0;
}



