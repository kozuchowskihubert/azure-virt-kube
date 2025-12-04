'use client'

import { useState } from 'react'
import Link from 'next/link'
import EmulatorView from '@/components/EmulatorView'
import ApplicationList from '@/components/ApplicationList'
import LowCodeBuilder from '@/components/LowCodeBuilder'

export default function Home() {
  const [activeTab, setActiveTab] = useState('emulator')

  return (
    <main className="min-h-screen bg-gradient-to-br from-gray-900 via-purple-900 to-violet-900">
      <nav className="bg-black/30 backdrop-blur-md border-b border-white/10">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <h1 className="text-2xl font-bold text-white flex items-center gap-2">
              <span className="text-4xl">🍷</span>
              Wine Emulator Platform
            </h1>
            <div className="flex gap-2">
              <button
                onClick={() => setActiveTab('emulator')}
                className={`px-4 py-2 rounded-lg transition-all ${
                  activeTab === 'emulator'
                    ? 'bg-wine-600 text-white'
                    : 'bg-white/10 text-gray-300 hover:bg-white/20'
                }`}
              >
                Emulator
              </button>
              <button
                onClick={() => setActiveTab('applications')}
                className={`px-4 py-2 rounded-lg transition-all ${
                  activeTab === 'applications'
                    ? 'bg-wine-600 text-white'
                    : 'bg-white/10 text-gray-300 hover:bg-white/20'
                }`}
              >
                Applications
              </button>
              <button
                onClick={() => setActiveTab('builder')}
                className={`px-4 py-2 rounded-lg transition-all ${
                  activeTab === 'builder'
                    ? 'bg-wine-600 text-white'
                    : 'bg-white/10 text-gray-300 hover:bg-white/20'
                }`}
              >
                Low-Code Builder
              </button>
            </div>
          </div>
        </div>
      </nav>

      <div className="container mx-auto px-4 py-8">
        {activeTab === 'emulator' && <EmulatorView />}
        {activeTab === 'applications' && <ApplicationList />}
        {activeTab === 'builder' && <LowCodeBuilder />}
      </div>

      <footer className="bg-black/30 backdrop-blur-md border-t border-white/10 mt-16">
        <div className="container mx-auto px-4 py-6 text-center text-gray-400">
          <p>Wine Emulator Platform - x86 to x64 Translation | Built with Next.js & FastAPI</p>
        </div>
      </footer>
    </main>
  )
}
