import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Quickopia — Admin Portal",
  description: "Supermarket fulfillment, catalog management and driver dispatch",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
