import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class ClubMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => "Club" });
        var clubs = ["Dr", "3W", "Hy", "4i", "5i", "6i", 
            "7i", "8i", "9i", "PW", "GW", "SW", "LW"];
        for (var i = 0; i < clubs.size(); i++) {
            addItem(new WatchUi.MenuItem(clubs[i], null, clubs[i], {}));
        }
    }
}

class ClubDelegate extends WatchUi.Menu2InputDelegate {
    private var _shotData as Lang.Dictionary;

    function initialize(shotData as Lang.Dictionary) {
        Menu2InputDelegate.initialize();
        _shotData = shotData;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        _shotData["club"] = item.getId() as Lang.String;
        var defaultDist = defaultDistanceForClub(_shotData["club"] as Lang.String);
        var pickerView = new DistancePickerView(_shotData, defaultDist);
        WatchUi.pushView(
            pickerView,
            new DistancePickerDelegate(_shotData, pickerView),
            WatchUi.SLIDE_LEFT
        );
    }

    private function defaultDistanceForClub(club as Lang.String) as Lang.Number {
        if (club.equals("Dr"))  { return 210; }
        if (club.equals("3W"))  { return 190; }
        if (club.equals("Hy"))  { return 175; }
        if (club.equals("4i"))  { return 160; }
        if (club.equals("5i"))  { return 150; }
        if (club.equals("6i"))  { return 140; }
        if (club.equals("7i"))  { return 130; }
        if (club.equals("8i"))  { return 120; }
        if (club.equals("9i"))  { return 110; }
        if (club.equals("PW"))  { return 100; }
        if (club.equals("GW"))  { return  90; }
        if (club.equals("SW"))  { return  80; }
        if (club.equals("LW"))  { return  60; }
        return 100;
    }
}