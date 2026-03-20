import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

function fullClubName(short as Lang.String) as Lang.String {
    if (short.equals("Dr"))  { return "Driver"; }
    if (short.equals("3W"))  { return "3 Wood"; }
    if (short.equals("Hy"))  { return "Hybrid"; }
    if (short.equals("4i"))  { return "4 Iron"; }
    if (short.equals("5i"))  { return "5 Iron"; }
    if (short.equals("6i"))  { return "6 Iron"; }
    if (short.equals("7i"))  { return "7 Iron"; }
    if (short.equals("8i"))  { return "8 Iron"; }
    if (short.equals("9i"))  { return "9 Iron"; }
    if (short.equals("PW"))  { return "Pitching W"; }
    if (short.equals("GW"))  { return "Gap W"; }
    if (short.equals("SW"))  { return "Sand W"; }
    if (short.equals("LW"))  { return "Lob W"; }
    return short;
}

class ConfirmationView extends WatchUi.View {

    private var _club     as Lang.String;
    private var _distance as Lang.Number;
    private var _timer    as Timer.Timer;

    function initialize(club as Lang.String, distance as Lang.Number) {
        View.initialize();
        _club     = club;
        _distance = distance;
        _timer    = new Timer.Timer();
    }

    function onShow() as Void {
        _timer.start(method(:dismiss), 2000, false);
    }

    function onHide() as Void {
        _timer.stop();
    }

    function dismiss() as Void {
        try {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } catch (e instanceof Lang.Exception) {}
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        // Dark background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Subtle dark card
        var cardW = (w * 0.78).toNumber();
        var cardH = (h * 0.58).toNumber();
        var cardX = cx - cardW / 2;
        var cardY = cy - cardH / 2;
        dc.setColor(0x1A1A1A, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(cardX, cardY, cardW, cardH, 18);

        // Green top accent bar
        var barH = 6;
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(cardX, cardY, cardW, barH * 2, 18);
        dc.fillRectangle(cardX, cardY + barH, cardW, barH);

        // Full club name
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cardY + (cardH * 0.18).toNumber(), Graphics.FONT_SMALL,
            fullClubName(_club), Graphics.TEXT_JUSTIFY_CENTER);

        // Distance (large)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cardY + (cardH * 0.36).toNumber(), Graphics.FONT_NUMBER_HOT,
            _distance.toString(), Graphics.TEXT_JUSTIFY_CENTER);

        // "meters" label
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cardY + (cardH * 0.80).toNumber(), Graphics.FONT_XTINY,
            "meters", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class ConfirmationDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onBack() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}