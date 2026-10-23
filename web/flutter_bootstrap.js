{{flutter_js}}
{{flutter_build_config}}

const splash = document.getElementById("splash-screen");

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    if (splash) {
      splash.style.opacity = "0";
      setTimeout(() => {
        try {
          splash.remove();
        } catch (_) {}
      }, 400);
    }
  }
});
