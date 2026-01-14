loadTemplate("org.kde.plasma.desktop.defaultPanel");

var panel = panels()[0];

if (panel) {
    var launcher = panel.addWidget("org.kde.plasma.kickerdash");
    launcher.writeConfig("icon", "kokoplay-menu");

    var transparency = panel.addWidget("org.kde.panel.transparency.toggle");
    transparency.writeConfig("enabled", true);  
    transparency.writeConfig("opacity", 0.85);


}

var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = 'org.kde.image';
}


