import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.System;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.Weather;
import Toybox.Math;

class GarminTennisView extends WatchUi.View {

    public static var activePage = 0; // 0 = Match UI, 1 = Stats/Calories UI
    var updateTimer;

    function initialize() {
        View.initialize();
        updateTimer = new Timer.Timer();
    }

    function onLayout(dc as Dc) as Void {
        // Pure DC drawing, ignoring layout.xml
    }

    function onShow() as Void {
        updateTimer.start(method(:onTimerTick), 1000, true);
    }
    
    function onTimerTick() as Void {
        WatchUi.requestUpdate();
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

        if (!state.isMatchStarted) {
            // Split background: Top OPPONENT (Red), Bottom YOU (Blue)
            dc.setColor(0x330000, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(0, 0, w, cy);
            
            dc.setColor(0x002233, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(0, cy, w, h - cy);
            
            // Text
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 100, Graphics.FONT_MEDIUM, "OPPONENT", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 50, Graphics.FONT_XTINY, "UP Key (Opponent)", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + 60, Graphics.FONT_MEDIUM, "YOU", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + 110, Graphics.FONT_XTINY, "DOWN Key (You)", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            
            // Middle band for serve selection
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(0, cy - 18, w, 36);
            
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy, Graphics.FONT_TINY, "WHO SERVES?", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            
            return;
        }

        // --- MATCH SCREEN UI ---

        // 0. BACKGROUND: BUTTON INDICATORS
        var upX = 0;
        var upY = cy;
        for (var r = 60; r > 0; r -= 5) {
            var intensity = (60 - r) + 10; 
            var col = intensity << 16;
            dc.setColor(col, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(upX, upY, r);
        }

        var downX = 20;
        var downY = 355;
        for (var r = 60; r > 0; r -= 5) {
            var intensity = (60 - r) + 10; 
            var col = (intensity << 8) | intensity; 
            dc.setColor(col, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(downX, downY, r);
        }

        // 1. TOP ARC: SET INDICATOR & TIMER
        var currentSet = state.p1Sets + state.p2Sets;
        var maxSets = state.maxSets;
        
        var setDotW = 10;
        var setGap = 15;
        var totalSetW = maxSets * setDotW + (maxSets - 1) * setGap;
        var startSetX = cx - (totalSetW / 2);
        
        for(var i=0; i<maxSets; i++) {
            var dx = startSetX + i*(setDotW + setGap);
            if (i < currentSet && i < state.completedSets.size()) {
                var winner = (state.completedSets[i][0] > state.completedSets[i][1]) ? 1 : 2;
                dc.setColor((winner == 1) ? 0x00E5FF : 0xFF3333, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dx + setDotW/2, 20, setDotW/2);
            } else if (i == currentSet) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(2);
                dc.drawCircle(dx + setDotW/2, 20, setDotW/2);
                dc.setPenWidth(1);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dx + setDotW/2, 20, setDotW/2);
            }
        }
        
        var totalSecs = state.getMatchDurationSeconds();
        var mins = (totalSecs / 60).toNumber();
        var secs = (totalSecs % 60).toNumber();
        var timerStr = mins.format("%02d") + ":" + secs.format("%02d");
        if (state.isPaused) { timerStr = "[ PAUSED ]"; }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 35, Graphics.FONT_MEDIUM, timerStr, Graphics.TEXT_JUSTIFY_CENTER);

        // 1.5 WIND ARROW
        if (Toybox has :Weather) {
            var conditions = Weather.getCurrentConditions();
            if (conditions != null && conditions.windBearing != null) {
                var windAngle = (conditions.windBearing + 180) % 360;
                var theta = windAngle * Math.PI / 180.0;
                var ax = cx + 70;
                var ay = 45;
                var ar = 7;
                
                var angle1 = theta + Math.PI * 0.8;
                var angle2 = theta - Math.PI * 0.8;
                
                var pts = [
                    [ax + ar * Math.sin(theta), ay - ar * Math.cos(theta)],
                    [ax + ar * Math.sin(angle1), ay - ar * Math.cos(angle1)],
                    [ax + ar * Math.sin(angle2), ay - ar * Math.cos(angle2)]
                ];
                
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.fillPolygon(pts);
                
                if (conditions.windSpeed != null) {
                    var speed = (conditions.windSpeed * 3.6).toNumber();
                    dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(ax + 12, ay - 8, Graphics.FONT_TINY, speed.toString(), Graphics.TEXT_JUSTIFY_LEFT);
                }
            }
        }

        // 2. PLAYERS & SERVE INDICATOR
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 140, 130, Graphics.FONT_SMALL, "YOU", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx + 140, 130, Graphics.FONT_SMALL, "OPPONENT", Graphics.TEXT_JUSTIFY_CENTER);
        
        var serveStateStr = (state.serveState == 1) ? "1st" : "2nd";
        dc.setColor(0x00FF66, Graphics.COLOR_TRANSPARENT);
        
        if (state.server == 1) {
            dc.fillCircle(cx - 120, 115, 6);
            dc.drawText(cx - 105, 105, Graphics.FONT_TINY, serveStateStr, Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.fillCircle(cx + 105, 115, 6);
            dc.drawText(cx + 120, 105, Graphics.FONT_TINY, serveStateStr, Graphics.TEXT_JUSTIFY_LEFT);
        }

        // 3. MAIN SCORE
        var p1Score = state.getP1PointString();
        var p2Score = state.getP2PointString();
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 140, 230, Graphics.FONT_NUMBER_HOT, p1Score, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx + 140, 230, Graphics.FONT_NUMBER_HOT, p2Score, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 220, Graphics.FONT_LARGE, "-", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 4. GAME BOXES
        var boxW = 22;
        var boxH = 8;
        var gap = 6;
        var totalW = 6 * boxW + 5 * gap;
        var startX = cx - (totalW / 2);
        
        var p1Color = 0x00E5FF;
        var p2Color = 0xFF3333;
        var emptyColor = 0x222222;

        for(var i = 0; i < 6; i++) {
            dc.setColor((i < state.p1Games) ? p1Color : emptyColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(startX + i * (boxW + gap), 320, boxW, boxH, 3);
            
            dc.setColor((i < state.p2Games) ? p2Color : emptyColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(startX + i * (boxW + gap), 335, boxW, boxH, 3);
        }

        // 5. HEART RATE ARC GAUGE
        var hrStr = "--";
        var zone = 0;
        var hr = 0;
        var info = Activity.getActivityInfo();
        
        if (info != null && info.currentHeartRate != null) {
            hr = info.currentHeartRate;
            hrStr = hr.toString();
            if (hr < 114) { zone = 1; }
            else if (hr < 133) { zone = 2; }
            else if (hr < 152) { zone = 3; }
            else if (hr < 171) { zone = 4; }
            else { zone = 5; }
        }
        
        var r = cx - 15;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(zone == 1 ? 12 : 6);
        dc.drawArc(cx, cy, r, Graphics.ARC_COUNTER_CLOCKWISE, 220, 240);
        
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(zone == 2 ? 12 : 6);
        dc.drawArc(cx, cy, r, Graphics.ARC_COUNTER_CLOCKWISE, 240, 260);
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(zone == 3 ? 12 : 6);
        dc.drawArc(cx, cy, r, Graphics.ARC_COUNTER_CLOCKWISE, 260, 280);
        
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(zone == 4 ? 12 : 6);
        dc.drawArc(cx, cy, r, Graphics.ARC_COUNTER_CLOCKWISE, 280, 300);
        
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(zone == 5 ? 12 : 6);
        dc.drawArc(cx, cy, r, Graphics.ARC_COUNTER_CLOCKWISE, 300, 320);
        
        dc.setPenWidth(1);
        
        var hrColor = Graphics.COLOR_WHITE;
        if (zone == 1) { hrColor = Graphics.COLOR_LT_GRAY; }
        else if (zone == 2) { hrColor = Graphics.COLOR_BLUE; }
        else if (zone == 3) { hrColor = Graphics.COLOR_GREEN; }
        else if (zone == 4) { hrColor = Graphics.COLOR_ORANGE; }
        else if (zone == 5) { hrColor = Graphics.COLOR_RED; }

        dc.setColor(hrColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h - 65, Graphics.FONT_TINY, hrStr + " bpm", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function onHide() as Void {
        updateTimer.stop();
    }
}
