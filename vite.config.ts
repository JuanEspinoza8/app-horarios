import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import { VitePWA } from "vite-plugin-pwa";

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: "autoUpdate",
      includeAssets: ["plantilla.docx", "favicon.svg", "icon.svg"],
      manifest: {
        name: "Horas Extras",
        short_name: "Horas Extras",
        description: "Cargá tus horas extras y generá la planilla HSX en Word.",
        theme_color: "#1f6feb",
        background_color: "#0d1117",
        display: "standalone",
        orientation: "portrait",
        lang: "es-AR",
        icons: [
          { src: "icon.svg", sizes: "any", type: "image/svg+xml", purpose: "any maskable" },
        ],
      },
      workbox: {
        // La plantilla .docx puede superar el límite por defecto; la incluimos igual.
        globPatterns: ["**/*.{js,css,html,svg,png,docx,woff2}"],
        maximumFileSizeToCacheInBytes: 5 * 1024 * 1024,
      },
    }),
  ],
  test: {
    globals: true,
    environment: "node",
  },
});
