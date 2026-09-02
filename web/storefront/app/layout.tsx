import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Quickopia — On-Demand Supermarket & Delivery",
  description: "Express supermarket delivery & Click and Collect pickup in Tanzania",
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
