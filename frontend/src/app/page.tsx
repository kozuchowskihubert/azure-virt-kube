'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import EmulatorView from '@/components/EmulatorView'
import ApplicationList from '@/components/ApplicationList'
import LowCodeBuilder from '@/components/LowCodeBuilder'
import HAOSLandingPage from '@/components/HAOSLandingPage'
import HAOSNavigation from '@/components/HAOSNavigation'

type ViewType = 'landing' | 'applications' | 'emulator' | 'lowcode'

export default function Home() {
  const [currentView, setCurrentView] = useState<ViewType>('landing')

  const pageVariants = {
    initial: { opacity: 0, y: 20 },
    animate: { opacity: 1, y: 0 },
    exit: { opacity: 0, y: -20 }
  }

  const renderView = () => {
    switch (currentView) {
      case 'landing':
        return <HAOSLandingPage onGetStarted={() => setCurrentView('applications')} />
      case 'applications':
        return (
          <div className="min-h-screen bg-black pt-20">
            <div className="max-w-7xl mx-auto px-4 py-12">
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="mb-12"
              >
                <div className="text-[#00ff88] font-mono text-sm tracking-wider mb-2">// APPLICATIONS</div>
                <h1 className="text-6xl font-black mb-4">MANAGE <span className="text-[#00ff88]">APPS</span></h1>
                <p className="text-gray-400 font-mono">Deploy and control your Windows applications</p>
              </motion.div>
              <ApplicationList />
            </div>
          </div>
        )
      case 'emulator':
        return (
          <div className="min-h-screen bg-black pt-20">
            <div className="max-w-7xl mx-auto px-4 py-12">
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="mb-12"
              >
                <div className="text-[#00ff88] font-mono text-sm tracking-wider mb-2">// EMULATOR</div>
                <h1 className="text-6xl font-black mb-4">WINE <span className="text-[#0088ff]">CONTROL</span></h1>
                <p className="text-gray-400 font-mono">Monitor and manage emulator instances</p>
              </motion.div>
              <EmulatorView />
            </div>
          </div>
        )
      case 'lowcode':
        return (
          <div className="min-h-screen bg-black pt-20">
            <div className="max-w-7xl mx-auto px-4 py-12">
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="mb-12"
              >
                <div className="text-[#00ff88] font-mono text-sm tracking-wider mb-2">// BUILDER</div>
                <h1 className="text-6xl font-black mb-4">UI <span className="text-[#00ff88]">BUILDER</span></h1>
                <p className="text-gray-400 font-mono">Create custom interfaces visually</p>
              </motion.div>
              <LowCodeBuilder />
            </div>
          </div>
        )
      default:
        return null
    }
  }

  return (
    <main className="min-h-screen bg-black">
      {currentView !== 'landing' && (
        <HAOSNavigation currentView={currentView} onNavigate={setCurrentView} />
      )}
      
      <AnimatePresence mode="wait">
        <motion.div
          key={currentView}
          variants={pageVariants}
          initial="initial"
          animate="animate"
          exit="exit"
          transition={{ duration: 0.3 }}
        >
          {renderView()}
        </motion.div>
      </AnimatePresence>
    </main>
  )
}
