var { app, BrowserWindow } = require("electron");

app.on("ready", () => {
  new BrowserWindow({
    width: 1707,
    height: 960,
    titleBarStyle: "hiddenInset",
    backgroundColor: "#fff",
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false
    }
  }).loadFile("build/index.html");
});

app.on("window-all-closed", () => {
  app.quit();
});
