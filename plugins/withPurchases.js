const { withAndroidManifest } = require("expo/config-plugins");
module.exports = (config) =>
  withAndroidManifest(config, (c) => {
    const activity = c.modResults.manifest.application?.[0]?.activity?.find(
      (a) => a.$["android:name"] === ".MainActivity",
    );
    if (activity) activity.$["android:launchMode"] = "singleTop";
    return c;
  });
