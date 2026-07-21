import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Activity;
import Toybox.Application;
import Toybox.Lang;

class SaveConfirmationView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var app = Application.getApp() as GarminTennisApp;
        var state = app.matchState;

        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // 1. TOP RIGHT: SAVE (SELECT BUTTON)
        dc.setColor(0x00FF66, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(w - 40, 80, 22);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w - 40, 80, Graphics.FONT_SMALL, "✓", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        dc.setColor(0x00FF66, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w - 75, 80, Graphics.FONT_XTINY, "SAVE (SELECT)", Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        // 2. BOTTOM LEFT: DISCARD (DOWN BUTTON)
        dc.setColor(0xFF3333, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(40, h - 100, 22);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(40, h - 100, Graphics.FONT_SMALL, "✕", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        dc.setColor(0xFF3333, Graphics.COLOR_TRANSPARENT);
        dc.drawText(75, h - 100, Graphics.FONT_XTINY, "DISCARD (DOWN)", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // 3. CENTER: MATCH SUMMARY
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 60, Graphics.FONT_MEDIUM, "END MATCH?", Graphics.TEXT_JUSTIFY_CENTER);

        // Score Summary
        var scoreSummary = state.p1Sets + " - " + state.p2Sets + " Sets";
        dc.setColor(0x00E5FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 10, Graphics.FONT_MEDIUM, scoreSummary, Graphics.TEXT_JUSTIFY_CENTER);

        // Time & Calories
        var totalSecs = state.getMatchDurationSeconds();
        var mins = (totalSecs / 60).toNumber();
        var secs = (totalSecs % 60).toNumber();
        var timerStr = mins.format("%02d") + ":" + secs.format("%02d");

        var info = Activity.getActivityInfo();
        var calories = "--";
        if (info != null && info.calories != null) {
            calories = info.calories.toString();
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 30, Graphics.FONT_XTINY, "Time: " + timerStr + "  |  Cal: " + calories + " kcal", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class SaveConfirmationDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        saveAndExit();
        return true;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            saveAndExit();
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            discardAndExit();
            return true;
        }
        return false;
    }

    function onNextPage() as Boolean {
        discardAndExit();
        return true;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        var x = coords[0];
        var y = coords[1];
        var dev = System.getDeviceSettings();
        var cx = dev.screenWidth / 2;
        var cy = dev.screenHeight / 2;

        if (x > cx && y < cy) {
            saveAndExit();
            return true;
        } else if (x < cx && y > cy) {
            discardAndExit();
            return true;
        }
        return false;
    }

    function saveAndExit() {
        var app = Application.getApp() as GarminTennisApp;
        app.matchState.saveMatch();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function discardAndExit() {
        var app = Application.getApp() as GarminTennisApp;
        app.matchState.discardMatch();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
