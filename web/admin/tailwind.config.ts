import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        quickopia: {
          navy: "#0B2545",
          dark: "#07192E",
          amber: "#F5A623",
          orange: "#E89415",
          light: "#F7F8FA",
          muted: "#8E8E93",
        },
      },
    },
  },
  plugins: [],
};
export default config;
