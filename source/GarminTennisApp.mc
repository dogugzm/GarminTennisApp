import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class GarminTennisApp extends Application.AppBase {

    var matchState;

    function initialize() {
        AppBase.initialize();
        matchState = new MatchState();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new GarminTennisMenu(), new GarminTennisMenuDelegate() ];
    }

}

function getApp() as GarminTennisApp {
    return Application.getApp() as GarminTennisApp;
}
