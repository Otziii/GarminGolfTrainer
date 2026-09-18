import Toybox.Application;
import Toybox.Lang;

module ShotHistory {

    const KEY = "shots";
    const KEY_UNITS = "units";
    const KEY_LOG_SHOTS = "logShots";
    const KEY_LOG_DISTANCE = "logDistance";

    function addShot(shot as Lang.Dictionary) as Void {
        var shots = getShots();
        shots.add(shot);
        Application.Storage.setValue(KEY, shots);
    }

    function getShots() as Lang.Array {
        var stored = Application.Storage.getValue(KEY);
        return stored != null ? stored : ([] as Lang.Array);
    }

    function getShotCount() as Lang.Number {
        return getShots().size();
    }

    function getClubAverages() as Lang.Dictionary {
        var shots = getShots();
        var totals = {} as Lang.Dictionary;

        for (var i = 0; i < shots.size(); i++) {
            var shot = shots[i] as Lang.Dictionary;
            var club = shot.get("club") as Lang.String?;
            var dist = shot.get("distance") as Lang.Number?;
            if (club == null || dist == null) { continue; }

            if (!totals.hasKey(club)) {
                totals[club] = { "count" => 0, "total" => 0 };
            }
            var entry = totals[club] as Lang.Dictionary;
            entry["count"] = (entry["count"] as Lang.Number) + 1;
            entry["total"] = (entry["total"] as Lang.Number) + dist;
        }

        var averages = {} as Lang.Dictionary;
        var keys = totals.keys();
        for (var i = 0; i < keys.size(); i++) {
            var club = keys[i];
            var entry = totals[club] as Lang.Dictionary;
            var count = entry["count"] as Lang.Number;
            averages[club] = {
                "count"       => count,
                "avgDistance" => ((entry["total"] as Lang.Number) / count).toNumber()
            };
        }
        return averages;
    }

    // Units: "metric" (default) or "imperial"
    function getUnits() as Lang.String {
        var stored = Application.Storage.getValue(KEY_UNITS);
        return stored != null ? stored as Lang.String : "metric";
    }

    function setUnits(units as Lang.String) as Void {
        Application.Storage.setValue(KEY_UNITS, units);
    }

    function isMetric() as Lang.Boolean {
        return getUnits().equals("metric");
    }

    function getUnitText() as Lang.String {
        return isMetric() ? "meters" : "yards";
    }

    // Controls shot logging during a range session: both swing-detected
    // prompts and the manual SELECT action. The home menu's explicit
    // "Log Shot" is a deliberate user action and stays available either way.
    function shouldLogShots() as Lang.Boolean {
        var stored = Application.Storage.getValue(KEY_LOG_SHOTS);
        return stored != null ? stored as Lang.Boolean : true;
    }

    function setLogShots(enabled as Lang.Boolean) as Void {
        Application.Storage.setValue(KEY_LOG_SHOTS, enabled);
    }

    // When off, the distance picker is skipped and shots are stored without
    // a "distance" key. Every consumer treats that as "unknown", not zero.
    function shouldLogDistance() as Lang.Boolean {
        var stored = Application.Storage.getValue(KEY_LOG_DISTANCE);
        return stored != null ? stored as Lang.Boolean : true;
    }

    function setLogDistance(enabled as Lang.Boolean) as Void {
        Application.Storage.setValue(KEY_LOG_DISTANCE, enabled);
    }

    function clearAll() as Void {
        Application.Storage.deleteValue(KEY);
    }
}