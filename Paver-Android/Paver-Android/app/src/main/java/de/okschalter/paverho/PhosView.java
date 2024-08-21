// Android version of a Paverho/Sonne-16 simulator
// Copyr. 2018 Michael Mangelsdorf (mim@ok-schalter.de)

package de.okschalter.paverho;

import android.content.Context;
import android.content.res.AssetManager;
import android.opengl.GLSurfaceView;
import android.view.InputDevice;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;
import android.view.inputmethod.EditorInfo;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

class PhosView extends GLSurfaceView {

    private static String TAG = "PhosView";
    private static final boolean DEBUG = false;
    private static AssetManager assetMgr;
    private static String dataDirPath;

    @Override
     public boolean performClick() {
      // Calls the super implementation, which generates an AccessibilityEvent
            // and calls the onClick() listener on the view, if any
            super.performClick();

            // Handle the action for the custom click here

            return true;
     }

    public PhosView(final Context context, AssetManager mgr, java.io.File dataDir, final EditText editBox) {
        super(context);
        // Pick an EGLConfig with RGB8 color, 16-bit depth, no stencil,
        setEGLConfigChooser(8, 8, 8, 0, 16, 0);
        setEGLContextClientVersion(3);
        setRenderer(new Renderer());
        assetMgr = mgr;
        dataDirPath = dataDir.toString();

        editBox.setOnEditorActionListener(new OnEditorActionListener() {
            @Override
            public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
                int result = actionId & EditorInfo.IME_MASK_ACTION;
                switch (result) {
                    case EditorInfo.IME_ACTION_DONE:
                        // done stuff
                        PhosGlue.lineReady(editBox.getText().toString());
                        editBox.setText("");
                        break;
                    case EditorInfo.IME_ACTION_NEXT:
                        // next stuff
                        break;
                }
                return true; // Action consumed
            }
        });


        // Hardware keyboard hook
        this.setOnKeyListener(new OnKeyListener() {
            @Override
            public boolean onKey(View view, int i, KeyEvent keyEvent) {
                return false;
            }
        }); ;


        this.setOnTouchListener(new OnTouchListener() {
            public boolean onTouch(View v, MotionEvent event) {
                int actionIndex = event.getActionIndex();
                int action = event.getActionMasked();
                int myAction; /* phos action id */
                switch (action) {
                    case MotionEvent.ACTION_DOWN:
                        myAction = 1;
                        break;
                    case MotionEvent.ACTION_POINTER_DOWN:
                        myAction = 1;
                        break;
                    case MotionEvent.ACTION_UP:
                        myAction = 3;
                        break;
                    case MotionEvent.ACTION_POINTER_UP:
                        myAction = 3;
                        break;
                    case MotionEvent.ACTION_MOVE:
                        myAction = 2;
                        break;
                    case MotionEvent.ACTION_CANCEL:
                        myAction = 4;
                        break;
                    default:
                        myAction = 0; /* Ignore */
                }
                PhosGlue.handleTouch(
                        myAction,
                        event.getPointerId(actionIndex),
                        event.getX(actionIndex),
                        event.getY(actionIndex)
                );
                return true;
            }
        });

    }

    @Override
    public void onResume() {
        super.onResume();
        PhosGlue.phase(1); /* RESTORE */
    }

    @Override
    public void onPause() {
        super.onPause();
        PhosGlue.phase(2); /* PAUSE */
    }

    public void saveRequested()
    {
        PhosGlue.phase(3); /* SAVE */
    }

    public void exitRequested()
    {
        PhosGlue.phase(4); /* EXIT */
    }


    //onGenericMotionEvent  // Joystick, mouse hover, trackpad etc


    // Soft keyboard or game controllers
    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        boolean handled = false;
        if ((event.getSource() & InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD)
        {
            if (event.getRepeatCount() == 0) {
                switch (keyCode) {
                    default:
                        break;
                }
            }
            if (handled) {
                return true;
            }
        }
        return super.onKeyDown(keyCode, event);
    }


    // Ignore the GL10 parameter as and use GLES3 static methods
    private static class Renderer implements GLSurfaceView.Renderer {
        public void onDrawFrame(GL10 gl) {
            PhosGlue.step();
        }

        public void onSurfaceChanged(GL10 gl, int width, int height) {
            PhosGlue.changed(width, height);
        }

        public void onSurfaceCreated(GL10 gl, EGLConfig config) {
            PhosGlue.init( assetMgr, dataDirPath);
        }
    }
}
