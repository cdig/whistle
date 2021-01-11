"use strict";

const { app, BrowserWindow } = require("electron");
const path = require("path");
require("electron-reload")(__dirname);

app.on("ready", () => {
  const win = new BrowserWindow({
    width: 1707,
    height: 960,
    backgroundColor: "#fff",
    webPreferences: {
      nodeIntegration: true
    }
  });
  win.loadFile("build/index.html");
  win.webContents.openDevTools();
});
