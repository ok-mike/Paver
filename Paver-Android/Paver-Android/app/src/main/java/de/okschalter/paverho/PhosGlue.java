// Android version of a Paverho/Sonne-16 simulator
// Copyr. 2018 Michael Mangelsdorf (mim@ok-schalter.de)

package de.okschalter.paverho;


import android.content.res.AssetManager;

public class PhosGlue {

     static {
         System.loadLibrary("phoslib");
     }

     public static native void handleTouch( int action, int id, float x, float y);

     public static native void lineReady( String lineText);

     public static native void init(AssetManager mgr, String dataDirPath);

     public static native void changed(int width, int height);

     public static native void step();

     public static native void phase(int e);
}
