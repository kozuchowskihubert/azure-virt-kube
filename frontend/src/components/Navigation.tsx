'use client'

import { motion } from 'framer-motion'
import { FaWindows, FaHome, FaDesktop, FaCode, FaCog } from 'react-icons/fa'

interface NavigationProps {
  currentView: 'landing' | 'applications' | 'emulator' | 'lowcode'
  onNavigate: (view: 'landing' | 'applications' | 'emulator' | 'lowcode') => void
}

export default function Navigation({ currentView, onNavigate }: NavigationProps) {
  const navItems = [
    { id: 'landing' as const, label: 'Home', icon: <FaHome className="w-5 h-5" /> },
    { id: 'applications' as const, label: 'Applications', icon: <FaDesktop className="w-5 h-5" /> },
    { id: 'emulator' as const, label: 'Emulator', icon: <FaWindows className="w-5 h-5" /> },
    { id: 'lowcode' as const, label: 'Builder', icon: <FaCode className="w-5 h-5" /> },
  ]

  return (
    <motion.nav
      initial={{ y: -100 }}
      animate={{ y: 0 }}
      className="fixed top-0 left-0 right-0 z-50 bg-gray-900/80 backdrop-blur-lg border-b border-white/10"
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <motion.div
            whileHover={{ scale: 1.05 }}
            className="flex items-center gap-3 cursor-pointer"
            onClick={() => onNavigate('landing')}
          >
            <div className="bg-gradient-to-r from-purple-600 to-pink-600 p-2 rounded-lg">
              <FaWindows className="w-6 h-6 text-white" />
            </div>
            <span className="text-xl font-bold text-white hidden sm:block">
              Wine Emulator
            </span>
          </motion.div>

          {/* Navigation Items */}
          <div className="flex items-center gap-2">
            {navItems.map((item) => (
              <motion.button
                key={item.id}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => onNavigate(item.id)}
                className={`
                  relative px-4 py-2 rounded-lg font-medium transition-all flex items-center gap-2
                  ${currentView === item.id
                    ? 'text-white bg-gradient-to-r from-purple-600 to-pink-600'
                    : 'text-gray-300 hover:text-white hover:bg-white/10'
                  }
                `}
              >
                <span className="hidden sm:inline">{item.icon}</span>
                <span>{item.label}</span>
                
                {currentView === item.id && (
                  <motion.div
                    layoutId="activeTab"
                    className="absolute inset-0 bg-gradient-to-r from-purple-600 to-pink-600 rounded-lg"
                    style={{ zIndex: -1 }}
                  />
                )}
              </motion.button>
            ))}
          </div>

          {/* Settings Button */}
          <motion.button
            whileHover={{ scale: 1.05, rotate: 90 }}
            whileTap={{ scale: 0.95 }}
            className="p-2 rounded-lg text-gray-300 hover:text-white hover:bg-white/10 transition-all"
          >
            <FaCog className="w-6 h-6" />
          </motion.button>
        </div>
      </div>
    </motion.nav>
  )
}
