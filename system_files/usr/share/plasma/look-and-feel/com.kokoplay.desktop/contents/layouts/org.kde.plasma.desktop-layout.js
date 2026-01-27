loadTemplate("org.kde.plasma.desktop.defaultPanel");

var panel = panels()[0];

if (panel) {
    
    var widgets = panel.widgets();

    for (var i = 0; i < widgets.length; i++) {
        var w = widgets[i];

        if (w.type === "org.kde.plasma.kickoff" ||
            w.type === "org.kde.plasma.kicker" ||
            w.type === "org.kde.plasma.kickerdash") {

            w.writeConfig("icon", "kokoplay-menu");
        }
    }


    var transparency = panel.addWidget("org.kde.panel.transparency.toggle");
    transparency.writeConfig("enabled", true);  
    transparency.writeConfig("opacity", 0.85);
    transparency.writeConfig("hideInEditModeEnabled", true);



}

var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = 'org.kde.image';
}


