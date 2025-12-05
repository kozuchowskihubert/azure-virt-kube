'use client'

import { motion } from 'framer-motion'
import { useState, useEffect } from 'react'
import { FaWindows, FaDocker, FaCloud, FaRocket, FaCode, FaCogs, FaPlay, FaChevronRight, FaGithub } from 'react-icons/fa'
import { SiKubernetes } from 'react-icons/si'

interface LandingPageProps {
  onGetStarted: () => void
}

export default function HAOSLandingPage({ onGetStarted }: LandingPageProps) {
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 })
  const [currentText, setCurrentText] = useState(0)

  const rotatingTexts = [
    "RUN WINDOWS APPS",
    "DEPLOY ANYWHERE",
    "SCALE INFINITELY",
    "BUILD FASTER"
  ]

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentText((prev) => (prev + 1) % rotatingTexts.length)
    }, 3000)
    return () => clearInterval(interval)
  }, [])

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      setMousePosition({ x: e.clientX, y: e.clientY })
    }
    window.addEventListener('mousemove', handleMouseMove)
    return () => window.removeEventListener('mousemove', handleMouseMove)
  }, [])

  return (
    <div className="min-h-screen bg-black text-white overflow-hidden relative">
      {/* Gradient Orb Following Mouse */}
      <div 
        className="fixed w-96 h-96 rounded-full blur-3xl opacity-20 pointer-events-none transition-all duration-1000 ease-out"
        style={{
          background: 'radial-gradient(circle, #00ff88 0%, #0088ff 50%, transparent 70%)',
          left: mousePosition.x - 192,
          top: mousePosition.y - 192,
        }}
      />

      {/* Grid Background */}
      <div className="fixed inset-0 opacity-10">
        <div className="absolute inset-0" style={{
          backgroundImage: `
            linear-gradient(to right, #00ff88 1px, transparent 1px),
            linear-gradient(to bottom, #00ff88 1px, transparent 1px)
          `,
          backgroundSize: '80px 80px',
        }}></div>
      </div>

      {/* Hero Section */}
      <div className="relative min-h-screen flex items-center justify-center px-4">
        <div className="max-w-7xl mx-auto text-center">
          {/* Logo Badge */}
          <motion.div
            initial={{ scale: 0, rotate: -180 }}
            animate={{ scale: 1, rotate: 0 }}
            transition={{ type: "spring", stiffness: 200, damping: 20 }}
            className="inline-block mb-8"
          >
            <div className="relative">
              <div className="absolute inset-0 bg-gradient-to-r from-[#00ff88] to-[#0088ff] blur-xl opacity-50 rounded-full"></div>
              <div className="relative bg-black border-2 border-[#00ff88] px-6 py-3 rounded-full font-mono text-[#00ff88] text-sm tracking-wider">
                HAOS.FM × WINE PLATFORM
              </div>
            </div>
          </motion.div>

          {/* Main Headline */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="space-y-4 mb-12"
          >
            <h1 className="text-7xl md:text-9xl font-black tracking-tighter">
              <span className="bg-clip-text text-transparent bg-gradient-to-r from-white via-[#00ff88] to-[#0088ff]">
                WINE
              </span>
            </h1>
            
            <motion.div
              key={currentText}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              className="h-24 flex items-center justify-center"
            >
              <h2 className="text-4xl md:text-6xl font-bold text-[#00ff88] font-mono">
                {rotatingTexts[currentText]}
              </h2>
            </motion.div>

            <p className="text-xl md:text-2xl text-gray-400 max-w-3xl mx-auto font-light">
              Next-generation Windows emulation platform.
              <br />
              <span className="text-[#00ff88]">Containerized. Cloud-native. Limitless.</span>
            </p>
          </motion.div>

          {/* CTA Buttons */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 }}
            className="flex flex-col sm:flex-row gap-4 justify-center items-center mb-16"
          >
            <button
              onClick={onGetStarted}
              className="group relative px-8 py-4 bg-[#00ff88] text-black font-bold text-lg rounded-none overflow-hidden transform transition-all hover:scale-105 active:scale-95"
            >
              <span className="relative z-10 flex items-center gap-2">
                LAUNCH PLATFORM
                <FaRocket className="group-hover:translate-x-1 transition-transform" />
              </span>
              <div className="absolute inset-0 bg-[#0088ff] transform scale-x-0 group-hover:scale-x-100 transition-transform origin-left"></div>
            </button>

            <button className="group px-8 py-4 border-2 border-[#00ff88] text-[#00ff88] font-bold text-lg rounded-none hover:bg-[#00ff88] hover:text-black transition-all">
              <span className="flex items-center gap-2">
                VIEW DOCS
                <FaChevronRight className="group-hover:translate-x-1 transition-transform" />
              </span>
            </button>
          </motion.div>

          {/* Stats Bar */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6 }}
            className="grid grid-cols-2 md:grid-cols-4 gap-8 max-w-4xl mx-auto"
          >
            {[
              { value: "99.9%", label: "UPTIME" },
              { value: "<50ms", label: "LATENCY" },
              { value: "∞", label: "SCALE" },
              { value: "24/7", label: "ACTIVE" }
            ].map((stat, i) => (
              <div key={i} className="text-center border border-gray-800 p-4 hover:border-[#00ff88] transition-colors group">
                <div className="text-4xl font-black text-[#00ff88] font-mono group-hover:scale-110 transition-transform inline-block">
                  {stat.value}
                </div>
                <div className="text-xs text-gray-500 mt-2 font-mono tracking-wider">
                  {stat.label}
                </div>
              </div>
            ))}
          </motion.div>
        </div>

        {/* Scroll Indicator */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1, duration: 1 }}
          className="absolute bottom-8 left-1/2 transform -translate-x-1/2"
        >
          <motion.div
            animate={{ y: [0, 10, 0] }}
            transition={{ repeat: Infinity, duration: 2 }}
            className="w-6 h-10 border-2 border-[#00ff88] rounded-full flex items-start justify-center p-2"
          >
            <div className="w-1 h-2 bg-[#00ff88] rounded-full"></div>
          </motion.div>
        </motion.div>
      </div>

      {/* Features Section */}
      <div className="relative py-32 px-4">
        <div className="max-w-7xl mx-auto">
          {/* Section Header */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-center mb-20"
          >
            <div className="text-[#00ff88] font-mono text-sm tracking-wider mb-4">// CAPABILITIES</div>
            <h2 className="text-5xl md:text-7xl font-black mb-6">
              UNLIMITED <span className="text-[#00ff88]">POWER</span>
            </h2>
          </motion.div>

          {/* Feature Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[
              {
                icon: <FaWindows />,
                title: "WINDOWS ANYWHERE",
                description: "Run any Windows app on Linux, macOS, or cloud with Wine 8.0",
                color: "#00ff88"
              },
              {
                icon: <FaDocker />,
                title: "CONTAINERIZED",
                description: "Each app isolated in Docker with full resource control",
                color: "#0088ff"
              },
              {
                icon: <SiKubernetes />,
                title: "K8S READY",
                description: "Deploy on Kubernetes, scale automatically, zero-downtime",
                color: "#00ff88"
              },
              {
                icon: <FaCloud />,
                title: "AZURE NATIVE",
                description: "Fully managed on Azure Container Apps, enterprise-grade",
                color: "#0088ff"
              },
              {
                icon: <FaCode />,
                title: "LOW-CODE UI",
                description: "Build interfaces visually, no coding required",
                color: "#00ff88"
              },
              {
                icon: <FaCogs />,
                title: "ARM64 SUPPORT",
                description: "Native ARM with x86/x64 translation via Box86/Box64",
                color: "#0088ff"
              }
            ].map((feature, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
                className="group relative border border-gray-800 p-8 hover:border-[#00ff88] transition-all"
              >
                {/* Corner Accents */}
                <div className="absolute top-0 left-0 w-4 h-4 border-t-2 border-l-2 border-[#00ff88] opacity-0 group-hover:opacity-100 transition-opacity"></div>
                <div className="absolute bottom-0 right-0 w-4 h-4 border-b-2 border-r-2 border-[#00ff88] opacity-0 group-hover:opacity-100 transition-opacity"></div>

                <div className="text-4xl mb-4 group-hover:scale-110 transition-transform" style={{ color: feature.color }}>
                  {feature.icon}
                </div>
                <h3 className="text-xl font-black mb-3 font-mono tracking-tight">
                  {feature.title}
                </h3>
                <p className="text-gray-400 text-sm leading-relaxed">
                  {feature.description}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </div>

      {/* Tech Stack */}
      <div className="relative py-32 px-4 bg-gradient-to-b from-black via-gray-900 to-black">
        <div className="max-w-7xl mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-center mb-20"
          >
            <div className="text-[#00ff88] font-mono text-sm tracking-wider mb-4">// TECHNOLOGY</div>
            <h2 className="text-5xl md:text-7xl font-black">
              BUILT WITH <span className="text-[#0088ff]">FUTURE</span>
            </h2>
          </motion.div>

          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-8 gap-4"
          >
            {[
              "DOCKER", "K8S", "AZURE", "WINE",
              "NEXT.JS", "FASTAPI", "POSTGRES", "REDIS"
            ].map((tech, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, scale: 0.8 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.05 }}
                whileHover={{ scale: 1.1, borderColor: '#00ff88' }}
                className="border border-gray-800 p-6 text-center font-mono font-bold text-sm hover:bg-gray-900 transition-all cursor-pointer"
              >
                {tech}
              </motion.div>
            ))}
          </motion.div>
        </div>
      </div>

      {/* CTA Section */}
      <div className="relative py-32 px-4">
        <div className="max-w-4xl mx-auto text-center">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            className="relative border-4 border-[#00ff88] p-16"
          >
            {/* Corner Decorations */}
            <div className="absolute top-0 left-0 w-8 h-8 border-t-4 border-l-4 border-white -translate-x-1 -translate-y-1"></div>
            <div className="absolute top-0 right-0 w-8 h-8 border-t-4 border-r-4 border-white translate-x-1 -translate-y-1"></div>
            <div className="absolute bottom-0 left-0 w-8 h-8 border-b-4 border-l-4 border-white -translate-x-1 translate-y-1"></div>
            <div className="absolute bottom-0 right-0 w-8 h-8 border-b-4 border-r-4 border-white translate-x-1 translate-y-1"></div>

            <div className="space-y-8">
              <h2 className="text-5xl md:text-7xl font-black">
                READY TO <span className="text-[#00ff88]">DEPLOY?</span>
              </h2>
              <p className="text-xl text-gray-400">
                Start running Windows applications in the cloud today.
                <br />
                No limits. No compromises.
              </p>
              <button
                onClick={onGetStarted}
                className="group relative px-12 py-6 bg-[#00ff88] text-black font-black text-xl rounded-none overflow-hidden transform hover:scale-105 transition-all"
              >
                <span className="relative z-10 flex items-center gap-3">
                  <FaPlay />
                  LAUNCH NOW
                </span>
                <div className="absolute inset-0 bg-[#0088ff] transform scale-x-0 group-hover:scale-x-100 transition-transform origin-left"></div>
              </button>
            </div>
          </motion.div>
        </div>
      </div>

      {/* Footer */}
      <div className="relative border-t border-gray-800 py-12 px-4">
        <div className="max-w-7xl mx-auto">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-8">
            <div>
              <div className="font-black text-2xl mb-4 text-[#00ff88]">WINE PLATFORM</div>
              <p className="text-gray-500 text-sm">
                Next-generation Windows emulation for the cloud era.
              </p>
            </div>
            <div>
              <div className="font-bold mb-4 text-sm font-mono">QUICK LINKS</div>
              <div className="space-y-2 text-sm text-gray-500">
                <div className="hover:text-[#00ff88] cursor-pointer transition-colors">Documentation</div>
                <div className="hover:text-[#00ff88] cursor-pointer transition-colors">API Reference</div>
                <div className="hover:text-[#00ff88] cursor-pointer transition-colors">GitHub</div>
              </div>
            </div>
            <div>
              <div className="font-bold mb-4 text-sm font-mono">POWERED BY</div>
              <div className="space-y-2 text-sm text-gray-500">
                <div>Azure Container Apps</div>
                <div>Docker & Kubernetes</div>
                <div>Wine Compatibility Layer</div>
              </div>
            </div>
          </div>
          <div className="border-t border-gray-800 pt-8 text-center">
            <div className="text-gray-600 text-sm font-mono">
              © 2025 HAOS.FM × WINE PLATFORM // BUILT FOR THE FUTURE
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
