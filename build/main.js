"use strict";

const { app, BrowserWindow, session } = require("electron");
const path = require("path");
require("electron-reload")(__dirname);

app.on("ready", () => {
  const win = new BrowserWindow({
    width: 1707,
    height: 960,
    backgroundColor: "#fff",
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false
    }
  });
  win.loadFile("build/index.html");
  win.webContents.openDevTools();
});
