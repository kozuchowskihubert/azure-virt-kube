const path = require('path');

/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  reactStrictMode: true,
  poweredByHeader: false,
  
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
    NEXT_PUBLIC_WINE_VNC_URL: process.env.NEXT_PUBLIC_WINE_VNC_URL || 'http://localhost:8080',
  },
  
  async rewrites() {
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    return [
      {
        source: '/api/:path*',
        destination: `${apiUrl}/api/:path*`,
      },
    ];
  },

  webpack: (config) => {
    config.resolve.fallback = { fs: false, net: false, tls: false };
    
    // Ensure proper alias resolution
    config.resolve.alias = {
      ...config.resolve.alias,
      '@': path.resolve(__dirname, 'src'),
    };
    
    return config;
  },
};

module.exports = nextConfig;
