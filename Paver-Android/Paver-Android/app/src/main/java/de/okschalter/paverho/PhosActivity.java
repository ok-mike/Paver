// Android version of a Paverho/Sonne-16 simulator
// Copyr. 2018 Michael Mangelsdorf (mim@ok-schalter.de)

package de.okschalter.paverho;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.graphics.Color;
import android.os.Bundle;
import android.view.Surface;
import android.widget.EditText;

import android.content.Context;
import android.widget.LinearLayout;
import android.widget.RelativeLayout.LayoutParams;

import android.text.InputType;
import android.util.DisplayMetrics;
import android.view.View;

public class PhosActivity extends Activity {

    PhosView mView;

    // OnCreate
    // You must implement this callback, which fires when the system first creates the activity.
    // On activity creation, the activity enters the Created state.
    // In the onCreate() method, you perform basic application startup logic that
    // should happen only once for the entire life of the activity.
    // OnCreate can be called after onStop (onDestroy being suppressed if activity swapped out!)

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Prevent screen rotation
        if (getWindowManager().getDefaultDisplay().getRotation()== Surface.ROTATION_0)
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        if (getWindowManager().getDefaultDisplay().getRotation()== Surface.ROTATION_90)
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
        if (getWindowManager().getDefaultDisplay().getRotation()== Surface.ROTATION_270)
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE);

        final Context context = getApplication();
        EditText editBox = new EditText(context);
        int editBoxId = View.generateViewId();
        editBox.setId(editBoxId);
        mView = new PhosView(context, getAssets(), getFilesDir(), editBox);

        DisplayMetrics metrics = new DisplayMetrics();
        getWindowManager().getDefaultDisplay().getMetrics(metrics); // Define metrics for use below

        LinearLayout linearlayout = new LinearLayout(this);
        linearlayout.setOrientation(LinearLayout.VERTICAL);
        LayoutParams linearlayoutlayoutparams = new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
        setContentView(linearlayout, linearlayoutlayoutparams);
        LayoutParams LayoutParamsview = new LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);

        editBox.setWidth(metrics.widthPixels - 32);

        if (savedInstanceState == null) {
            editBox.setHint("Type here");
        } else {
            editBox.setHint("Type here (again)");;
        }

        editBox.setHintTextColor(Color.WHITE);
        editBox.setSingleLine();
        editBox.setTextColor(Color.WHITE);
        editBox.setInputType(InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD);

        editBox.setLayoutParams(LayoutParamsview);
        mView.setLayoutParams(LayoutParamsview);
        linearlayout.addView(mView, metrics.widthPixels,metrics.heightPixels - 100);
        linearlayout.addView(editBox);
    }

    // onStart()
    // When the activity enters the Started state, the system invokes this callback.
    // The onStart() call makes the activity visible to the user, as the app prepares
    // for the activity to enter the foreground and become interactive.
    @Override
    public void onStart() {
        super.onStart();  // Always call the superclass method first
    }

    // onResume()
    // When the activity enters the Resumed state, it comes to the foreground, and then
    // the system invokes the onResume() callback. This is the state in which the app interacts with the user.
    // The app stays in this state until something happens to take focus away from the app.
    // Such an event might be, for instance, receiving a phone call, the user’s navigating to
    // another activity, or the device screen’s turning off.
    // Be aware that the system calls this method every time your activity comes into the foreground,
    // including when it's created for the first time. As such, you should implement onResume() to initialize
    // components that you release during onPause(), and perform any other initializations that must occur
    // each time the activity enters the Resumed state.
    @Override
    public void onResume() {
        super.onResume();  // Always call the superclass method first
        mView.onResume();
    }

    // onPause()
    // The system calls this method as the first indication that the user is leaving your activity
    // (though it does not always mean the activity is being destroyed).
    // onPause() execution is very brief, and does not necessarily afford enough time to perform save operations.
    // For this reason, you should not use onPause() to save application or user data.
    @Override
    protected void onPause() {
        super.onPause();
        mView.onPause();
    }

    // onStop()
    // When your activity is no longer visible to the user, it has entered the Stopped state,
    // and the system invokes the onStop() callback. This may occur, for example, when a newly launched
    // activity covers the entire screen. The system may also call onStop() when the activity has finished running,
    // and is about to be terminated.
    //You should also use onStop() to perform relatively CPU-intensive shutdown operations.
    //When your activity enters the Stopped state, the Activity object is kept resident in memory:
    // It maintains all state and member information, but is not attached to the window manager.
    // When the activity resumes, the activity recalls this information.
    // You don’t need to re-initialize components that were created during any of the callback methods
    // leading up to the Resumed state. The system also keeps track of the current state for each View
    // object in the layout, so if the user entered text into an EditText widget, that content is retained so
    // you don't need to save and restore it.
    // OnCreate can be called after onStop (onDestroy being suppressed if activity swapped out!)
    protected void onStop() {
        super.onStop();
        mView.saveRequested();
        finish();
    }


    // onDestroy()
    // Called before the activity is destroyed. This is the final call that the activity receives.
    // The system either invokes this callback because the activity is finishing due to someone's calling finish(),
    // or because the system is temporarily destroying the process containing the activity to save space.
    // You can distinguish between these two scenarios with the isFinishing() method.
    // The system may also call this method when an orientation change occurs, and then immediately call onCreate()
    // to recreate the process (and the components that it contains) in the new orientation.
    // The onDestroy() callback releases all resources that have not yet been released by earlier callbacks
    // such as onStop().
    protected void onDestroy() {
        super.onDestroy();
        mView.exitRequested();
        android.os.Process.killProcess(android.os.Process.myPid());
    }


    // This callback is called only when there is a saved instance that is previously saved by using
    // onSaveInstanceState().
    // The savedInstanceState Bundle is same as the one used in onCreate().
    @Override
    public void onRestoreInstanceState(Bundle savedInstanceState) {
        //mTextView.setText(savedInstanceState.getString(TEXT_VIEW_KEY));
    }

    // invoked when the activity may be temporarily destroyed, save the instance state here
    @Override
    public void onSaveInstanceState(Bundle outState) {
        //outState.putString(GAME_STATE_KEY, mGameState);
        //outState.putString(TEXT_VIEW_KEY, mTextView.getText());
        // call superclass to save any view hierarchy
        super.onSaveInstanceState(outState);
    }


}
