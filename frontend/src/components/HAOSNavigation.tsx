'use client'

import { motion } from 'framer-motion'
import { FaWindows, FaHome, FaDesktop, FaCode, FaBars, FaTimes } from 'react-icons/fa'
import { useState } from 'react'

interface NavigationProps {
  currentView: 'landing' | 'applications' | 'emulator' | 'lowcode'
  onNavigate: (view: 'landing' | 'applications' | 'emulator' | 'lowcode') => void
}

export default function HAOSNavigation({ currentView, onNavigate }: NavigationProps) {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  const navItems = [
    { id: 'landing' as const, label: 'HOME', icon: <FaHome /> },
    { id: 'applications' as const, label: 'APPS', icon: <FaDesktop /> },
    { id: 'emulator' as const, label: 'EMULATOR', icon: <FaWindows /> },
    { id: 'lowcode' as const, label: 'BUILDER', icon: <FaCode /> },
  ]

  return (
    <>
      <motion.nav
        initial={{ y: -100 }}
        animate={{ y: 0 }}
        className="fixed top-0 left-0 right-0 z-50 bg-black/90 backdrop-blur-xl border-b border-gray-800"
      >
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex items-center justify-between h-16">
            {/* Logo */}
            <motion.div
              whileHover={{ scale: 1.05 }}
              className="flex items-center gap-3 cursor-pointer group"
              onClick={() => onNavigate('landing')}
            >
              <div className="relative">
                <div className="absolute inset-0 bg-[#00ff88] blur-lg opacity-50 group-hover:opacity-100 transition-opacity"></div>
                <div className="relative bg-black border-2 border-[#00ff88] p-2 rounded-sm">
                  <FaWindows className="w-5 h-5 text-[#00ff88]" />
                </div>
              </div>
              <span className="text-xl font-black tracking-tighter font-mono hidden sm:block">
                WINE<span className="text-[#00ff88]">.HAOS</span>
              </span>
            </motion.div>

            {/* Desktop Navigation */}
            <div className="hidden md:flex items-center gap-1">
              {navItems.map((item) => (
                <button
                  key={item.id}
                  onClick={() => onNavigate(item.id)}
                  className={`
                    relative px-6 py-2 font-mono font-bold text-sm tracking-wider transition-all
                    ${currentView === item.id
                      ? 'text-black bg-[#00ff88]'
                      : 'text-gray-400 hover:text-[#00ff88]'
                    }
                  `}
                >
                  <span className="flex items-center gap-2">
                    {item.icon}
                    {item.label}
                  </span>
                  
                  {currentView === item.id && (
                    <motion.div
                      layoutId="activeIndicator"
                      className="absolute bottom-0 left-0 right-0 h-0.5 bg-[#0088ff]"
                    />
                  )}
                </button>
              ))}
            </div>

            {/* Status Indicator */}
            <div className="hidden md:flex items-center gap-3">
              <div className="flex items-center gap-2 px-3 py-1 border border-gray-800 rounded-full">
                <div className="w-2 h-2 bg-[#00ff88] rounded-full animate-pulse"></div>
                <span className="text-xs font-mono text-gray-400">ONLINE</span>
              </div>
            </div>

            {/* Mobile Menu Button */}
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="md:hidden text-[#00ff88] p-2"
            >
              {mobileMenuOpen ? <FaTimes size={24} /> : <FaBars size={24} />}
            </button>
          </div>
        </div>
      </motion.nav>

      {/* Mobile Menu */}
      <motion.div
        initial={{ opacity: 0, x: '100%' }}
        animate={{ 
          opacity: mobileMenuOpen ? 1 : 0,
          x: mobileMenuOpen ? 0 : '100%'
        }}
        className="fixed inset-0 z-40 bg-black md:hidden"
        style={{ top: '64px' }}
      >
        <div className="flex flex-col p-8 space-y-4">
          {navItems.map((item, index) => (
            <motion.button
              key={item.id}
              initial={{ opacity: 0, x: 50 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.1 }}
              onClick={() => {
                onNavigate(item.id)
                setMobileMenuOpen(false)
              }}
              className={`
                text-left px-6 py-4 font-mono font-bold text-xl border-l-4 transition-all
                ${currentView === item.id
                  ? 'border-[#00ff88] text-[#00ff88] bg-gray-900'
                  : 'border-transparent text-gray-400 hover:border-gray-700 hover:text-white'
                }
              `}
            >
              <span className="flex items-center gap-3">
                {item.icon}
                {item.label}
              </span>
            </motion.button>
          ))}
        </div>
      </motion.div>
    </>
  )
}
