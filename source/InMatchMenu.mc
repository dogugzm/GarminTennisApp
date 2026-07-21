import Toybox.WatchUi;
import Toybox.System;
import Toybox.Application;
import Toybox.Lang;

class InMatchMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title=>"Match Menu"});
        
        var app = Application.getApp() as GarminTennisApp;
        var pauseLabel = app.matchState.isPaused ? "Resume Match" : "Pause Match";
        var pauseSub = app.matchState.isPaused ? "Continue Playing" : "Pause Timer";
        
        addItem(new WatchUi.MenuItem(pauseLabel, pauseSub, "pause", null));
        addItem(new WatchUi.MenuItem("Match Stats", "View Calories & Stats", "stats", null));
        addItem(new WatchUi.MenuItem("End Match", "Finish & Save", "end", null));
    }
}

class InMatchMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId() as String;
        var app = Application.getApp() as GarminTennisApp;

        if (id.equals("pause")) {
            app.matchState.togglePause();
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (id.equals("stats")) {
            WatchUi.pushView(new StatsView(), new StatsDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id.equals("end")) {
            WatchUi.pushView(new SaveConfirmationView(), new SaveConfirmationDelegate(), WatchUi.SLIDE_LEFT);
        }
    }
}
