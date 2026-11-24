import type { NextConfig } from "next";
import path from "path";
import createNextIntlPlugin from "next-intl/plugin";

const withNextIntl = createNextIntlPlugin("./i18n/request.ts");

// Normalize the Windows drive letter (c:\ -> C:\). A lowercase drive letter coming
// from the IDE terminal makes Turbopack fail to resolve `next` during HMR
// ("Next.js package not found"), which causes an endless browser reload loop.
const projectRoot = path
  .resolve(__dirname)
  .replace(/^([a-z]):/, (_, d: string) => `${d.toUpperCase()}:`);

const nextConfig: NextConfig = {
  turbopack: {
    root: projectRoot,
  },
  experimental: {
    // Disable Turbopack's persistent dev disk cache on Windows/NTFS:
    // stale cache entries across git pulls, builds, and concurrent route compilations
    // can trigger ChunkLoadError and RSC fetch failures during local development.
    turbopackFileSystemCacheForDev: false,
    // Optimize heavy barrel packages so dev chunks compile cleanly and stay stable across routes.
    optimizePackageImports: [
      "lucide-react",
      "recharts",
      "framer-motion",
      "date-fns",
    ],
  },
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "api.dicebear.com",
      },
      {
        protocol: "https",
        hostname: "i.pravatar.cc",
      },
      {
        protocol: "https",
        hostname: "images.unsplash.com",
      },
    ],
  },
};

export default withNextIntl(nextConfig);
