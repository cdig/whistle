fs = require("fs");

var { app, BrowserWindow } = require("electron");

app.on("ready", () => {
  let win = new BrowserWindow({
    width: 1707,
    height: 960,
    titleBarStyle: "hiddenInset",
    backgroundColor: "#fff",
    webPreferences: {
      contextIsolation: false,
      nodeIntegration: true
    }
  });

  win.loadFile("build/index.html");

  fs.watch("build", {recursive: true, persistent: false}, ()=>win.reload());
});

app.on("window-all-closed", () => {
  app.quit();
});
