'use client'

import { useEffect, useRef, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { fetchEmulatorStatus } from '@/lib/api'

export default function EmulatorView() {
  const canvasRef = useRef<HTMLDivElement>(null)
  const [isConnected, setIsConnected] = useState(false)

  const { data: status, isLoading } = useQuery({
    queryKey: ['emulator-status'],
    queryFn: fetchEmulatorStatus,
    refetchInterval: 5000,
  })

  useEffect(() => {
    // Initialize VNC connection
    if (canvasRef.current && process.env.NEXT_PUBLIC_WINE_VNC_URL) {
      setIsConnected(true)
    }
  }, [])

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20">
        <h2 className="text-2xl font-bold text-white mb-4">Wine Emulator Status</h2>
        
        {isLoading ? (
          <div className="text-gray-300">Loading status...</div>
        ) : (
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <StatusCard
              label="Status"
              value={status?.status || 'Unknown'}
              color={status?.status === 'running' ? 'green' : 'red'}
            />
            <StatusCard
              label="Wine Version"
              value={status?.wine_version || 'N/A'}
              color="blue"
            />
            <StatusCard
              label="Display"
              value={status?.display || 'N/A'}
              color="purple"
            />
            <StatusCard
              label="VNC"
              value={status?.vnc_available ? 'Available' : 'Unavailable'}
              color={status?.vnc_available ? 'green' : 'yellow'}
            />
          </div>
        )}
      </div>

      <div className="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold text-white">Remote Desktop (VNC)</h2>
          <div className="flex items-center gap-2">
            <div className={`w-3 h-3 rounded-full ${isConnected ? 'bg-green-500' : 'bg-red-500'} animate-pulse`} />
            <span className="text-gray-300 text-sm">
              {isConnected ? 'Connected' : 'Disconnected'}
            </span>
          </div>
        </div>

        <div 
          ref={canvasRef}
          className="bg-black rounded-lg overflow-hidden relative"
          style={{ height: '600px' }}
        >
          <iframe
            src={`${process.env.NEXT_PUBLIC_WINE_VNC_URL}/vnc.html`}
            className="w-full h-full border-0"
            title="Wine VNC Display"
          />
        </div>

        <div className="mt-4 flex gap-2">
          <button className="bg-wine-600 hover:bg-wine-700 text-white px-4 py-2 rounded-lg transition-colors">
            📁 Upload Application
          </button>
          <button className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition-colors">
            ▶️ Run Command
          </button>
          <button className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg transition-colors">
            📸 Screenshot
          </button>
          <button className="bg-yellow-600 hover:bg-yellow-700 text-white px-4 py-2 rounded-lg transition-colors">
            🔄 Restart
          </button>
        </div>
      </div>
    </div>
  )
}

function StatusCard({ label, value, color }: { label: string; value: string; color: string }) {
  const colorClasses = {
    green: 'bg-green-500/20 text-green-300 border-green-500/50',
    red: 'bg-red-500/20 text-red-300 border-red-500/50',
    blue: 'bg-blue-500/20 text-blue-300 border-blue-500/50',
    purple: 'bg-purple-500/20 text-purple-300 border-purple-500/50',
    yellow: 'bg-yellow-500/20 text-yellow-300 border-yellow-500/50',
  }

  return (
    <div className={`p-4 rounded-lg border ${colorClasses[color as keyof typeof colorClasses]}`}>
      <div className="text-sm opacity-75">{label}</div>
      <div className="text-lg font-bold mt-1">{value}</div>
    </div>
  )
}
