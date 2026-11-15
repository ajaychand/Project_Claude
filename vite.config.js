import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

// https://vite.dev/config/
// Production builds are served from GitHub Pages at /Project_Claude/
export default defineConfig(({ command }) => ({
  base: command === "build" ? "/Project_Claude/" : "/",
  plugins: [react(), tailwindcss()],
}));
