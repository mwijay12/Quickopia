# Quickopia Web (Storefront & Admin Portal)

This directory contains the Next.js application for Quickopia, deployable to **Vercel**.

## Surfaces Included:
1. **Public Web Storefront**:
   - For customers accessing via web/mobile browser without installing the APK.
   - Live product browsing, cart, and "Order via WhatsApp" / manual checkout.
2. **Supermarket Admin & Packing Portal**:
   - Protected dashboard for supermarket inventory management, order packing checklists, and driver dispatching.

## Quick Start
```bash
cd web
npm install
npm run dev
```

## Environment Variables
Ensure `.env.local` has:
```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=your_cloud_name
NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET=quickopia_products
GEMINI_API_KEY=your_gemini_key
```
