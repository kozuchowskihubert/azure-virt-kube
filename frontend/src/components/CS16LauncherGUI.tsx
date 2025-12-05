import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

export default function CS16LauncherGUI() {
  const [containerStatus, setContainerStatus] = useState<'checking' | 'running' | 'stopped' | 'error'>('checking');
  const [vncConnected, setVncConnected] = useState(false);
  const [gameStatus, setGameStatus] = useState<'idle' | 'launching' | 'running'>('idle');
  const [showInstructions, setShowInstructions] = useState(false);

  useEffect(() => {
    // Check container status
    checkContainerStatus();
    const interval = setInterval(checkContainerStatus, 5000);
    return () => clearInterval(interval);
  }, []);

  const checkContainerStatus = async () => {
    try {
      const response = await fetch('/api/docker/status?container=wine-dev-gaming');
      const data = await response.json();
      setContainerStatus(data.running ? 'running' : 'stopped');
    } catch (error) {
      setContainerStatus('error');
    }
  };

  const launchCS16 = async () => {
    setGameStatus('launching');
    try {
      await fetch('/api/games/launch-cs16', { method: 'POST' });
      setGameStatus('running');
      // Open VNC in new window
      window.open('vnc://localhost:5900', '_blank');
    } catch (error) {
      setGameStatus('idle');
      alert('Failed to launch CS 1.6. Check console for details.');
    }
  };

  return (
    <div className="min-h-screen bg-black text-white p-8">
      {/* HEADER */}
      <div className="max-w-6xl mx-auto">
        <div className="border-b border-[#00ff88]/30 pb-6 mb-8">
          <h1 className="text-6xl font-black haos-heading mb-4">
            // COUNTER-STRIKE <span className="text-[#00ff88]">1.6</span>
          </h1>
          <p className="text-gray-400 haos-mono text-sm">
            Wine Emulator Platform • VNC Port 5900 • Password: haosplatform
          </p>
        </div>

        {/* STATUS DASHBOARD */}
        <div className="grid grid-cols-3 gap-4 mb-8">
          {/* Container Status */}
          <div className="border border-gray-800 p-6 bg-black">
            <div className="flex items-center justify-between mb-2">
              <span className="haos-mono text-xs text-gray-500">CONTAINER</span>
              <div className={`w-3 h-3 rounded-full ${
                containerStatus === 'running' ? 'bg-[#00ff88] animate-pulse-glow' :
                containerStatus === 'stopped' ? 'bg-red-500' :
                'bg-yellow-500 animate-pulse'
              }`} />
            </div>
            <div className="text-2xl font-black haos-heading">
              {containerStatus === 'running' && '● RUNNING'}
              {containerStatus === 'stopped' && '○ STOPPED'}
              {containerStatus === 'checking' && '◐ CHECKING'}
              {containerStatus === 'error' && '✕ ERROR'}
            </div>
          </div>

          {/* VNC Status */}
          <div className="border border-gray-800 p-6 bg-black">
            <div className="flex items-center justify-between mb-2">
              <span className="haos-mono text-xs text-gray-500">VNC SERVER</span>
              <div className={`w-3 h-3 rounded-full ${
                containerStatus === 'running' ? 'bg-[#0088ff]' : 'bg-gray-700'
              }`} />
            </div>
            <div className="text-2xl font-black haos-heading">
              {containerStatus === 'running' ? 'PORT 5900' : 'OFFLINE'}
            </div>
          </div>

          {/* Game Status */}
          <div className="border border-gray-800 p-6 bg-black">
            <div className="flex items-center justify-between mb-2">
              <span className="haos-mono text-xs text-gray-500">GAME</span>
              <div className={`w-3 h-3 rounded-full ${
                gameStatus === 'running' ? 'bg-[#00ff88] animate-pulse-glow' :
                gameStatus === 'launching' ? 'bg-yellow-500 animate-pulse' :
                'bg-gray-700'
              }`} />
            </div>
            <div className="text-2xl font-black haos-heading">
              {gameStatus === 'idle' && 'READY'}
              {gameStatus === 'launching' && 'LAUNCHING'}
              {gameStatus === 'running' && 'ACTIVE'}
            </div>
          </div>
        </div>

        {/* MAIN CONTROL PANEL */}
        <div className="grid grid-cols-2 gap-8 mb-8">
          {/* LEFT: Game Info */}
          <div className="border border-[#00ff88]/30 bg-black p-8">
            <div className="mb-6">
              <img
                src="https://upload.wikimedia.org/wikipedia/en/6/6e/Counter-Strike_box.jpg"
                alt="CS 1.6"
                className="w-full h-64 object-cover mb-4 border border-gray-800"
              />
              <h2 className="text-3xl font-black haos-heading mb-2">Counter-Strike 1.6</h2>
              <p className="text-gray-400 leading-relaxed mb-4">
                The legendary tactical FPS. Join Counter-Terrorists or Terrorists in classic maps
                like de_dust2, de_inferno, and cs_office.
              </p>
              <div className="space-y-2 haos-mono text-xs">
                <div className="flex justify-between">
                  <span className="text-gray-500">Engine:</span>
                  <span className="text-white">GoldSrc (Half-Life)</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Players:</span>
                  <span className="text-white">1-32</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Year:</span>
                  <span className="text-white">2000</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Executable:</span>
                  <span className="text-[#00ff88]">hl.exe</span>
                </div>
              </div>
            </div>

            {/* LAUNCH BUTTON */}
            <button
              onClick={launchCS16}
              disabled={containerStatus !== 'running' || gameStatus === 'launching'}
              className={`w-full py-4 haos-mono font-bold text-lg transition-all ${
                containerStatus === 'running' && gameStatus === 'idle'
                  ? 'bg-[#00ff88] text-black hover:bg-[#00ff88]/80 hover:shadow-[0_0_30px_rgba(0,255,136,0.5)]'
                  : 'bg-gray-800 text-gray-600 cursor-not-allowed'
              }`}
            >
              {gameStatus === 'idle' && '▶ LAUNCH COUNTER-STRIKE 1.6'}
              {gameStatus === 'launching' && '⏳ LAUNCHING...'}
              {gameStatus === 'running' && '✓ GAME RUNNING'}
            </button>
          </div>

          {/* RIGHT: Instructions */}
          <div className="border border-[#0088ff]/30 bg-black p-8">
            <h3 className="text-2xl font-black haos-heading mb-6 text-[#0088ff]">
              // QUICK START
            </h3>

            <div className="space-y-6">
              {/* Step 1 */}
              <div className="border-l-2 border-[#00ff88] pl-4">
                <div className="haos-mono text-xs text-[#00ff88] mb-2">STEP 1</div>
                <h4 className="font-bold mb-2">Ensure Container is Running</h4>
                <p className="text-sm text-gray-400">
                  Check the status dashboard above. Container must show "RUNNING" (green dot).
                </p>
              </div>

              {/* Step 2 */}
              <div className="border-l-2 border-[#0088ff] pl-4">
                <div className="haos-mono text-xs text-[#0088ff] mb-2">STEP 2</div>
                <h4 className="font-bold mb-2">Click Launch Button</h4>
                <p className="text-sm text-gray-400">
                  Click the green "LAUNCH" button above. This will start CS 1.6 and open VNC viewer.
                </p>
              </div>

              {/* Step 3 */}
              <div className="border-l-2 border-[#00ff88] pl-4">
                <div className="haos-mono text-xs text-[#00ff88] mb-2">STEP 3</div>
                <h4 className="font-bold mb-2">Connect via VNC</h4>
                <p className="text-sm text-gray-400 mb-2">
                  When prompted, enter password:
                </p>
                <div className="bg-gray-900 border border-gray-800 p-3 haos-mono text-sm text-[#00ff88]">
                  haosplatform
                </div>
              </div>

              {/* Step 4 */}
              <div className="border-l-2 border-[#0088ff] pl-4">
                <div className="haos-mono text-xs text-[#0088ff] mb-2">STEP 4</div>
                <h4 className="font-bold mb-2">Play!</h4>
                <p className="text-sm text-gray-400">
                  CS 1.6 menu should appear in VNC window. Select "New Game" or "Create Server".
                </p>
              </div>
            </div>

            <button
              onClick={() => setShowInstructions(true)}
              className="w-full mt-6 py-3 border border-[#0088ff]/50 text-[#0088ff] haos-mono text-sm hover:bg-[#0088ff]/10 transition-all"
            >
              📖 VIEW DETAILED GUIDE
            </button>
          </div>
        </div>

        {/* QUICK ACTIONS */}
        <div className="grid grid-cols-4 gap-4 mb-8">
          <button
            onClick={() => window.open('vnc://localhost:5900')}
            className="border border-gray-800 bg-black p-4 hover:border-[#00ff88] transition-all group"
          >
            <div className="text-3xl mb-2">🖥️</div>
            <div className="haos-mono text-xs">OPEN VNC</div>
          </button>

          <button
            onClick={() => navigator.clipboard.writeText('haosplatform')}
            className="border border-gray-800 bg-black p-4 hover:border-[#0088ff] transition-all group"
          >
            <div className="text-3xl mb-2">🔑</div>
            <div className="haos-mono text-xs">COPY PASSWORD</div>
          </button>

          <button
            onClick={() => setShowInstructions(true)}
            className="border border-gray-800 bg-black p-4 hover:border-[#00ff88] transition-all group"
          >
            <div className="text-3xl mb-2">📚</div>
            <div className="haos-mono text-xs">INSTRUCTIONS</div>
          </button>

          <button
            onClick={checkContainerStatus}
            className="border border-gray-800 bg-black p-4 hover:border-[#0088ff] transition-all group"
          >
            <div className="text-3xl mb-2">🔄</div>
            <div className="haos-mono text-xs">REFRESH STATUS</div>
          </button>
        </div>

        {/* MAPS */}
        <div className="border border-gray-800 bg-black p-6">
          <h3 className="text-xl font-black haos-heading mb-4">// AVAILABLE MAPS</h3>
          <div className="grid grid-cols-5 gap-2 haos-mono text-xs">
            {['de_dust2', 'de_inferno', 'de_nuke', 'de_train', 'de_aztec', 
              'cs_office', 'cs_italy', 'cs_assault', 'as_oilrig', 'de_cbble'].map((map) => (
              <div key={map} className="border border-gray-800 p-2 text-center hover:border-[#00ff88] transition-all cursor-pointer">
                {map}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* DETAILED INSTRUCTIONS MODAL */}
      <AnimatePresence>
        {showInstructions && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/95 backdrop-blur-sm z-50 flex items-center justify-center p-8"
            onClick={() => setShowInstructions(false)}
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="bg-black border border-[#00ff88] max-w-4xl w-full max-h-[90vh] overflow-y-auto p-8"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-3xl font-black haos-heading">// COMPLETE GUIDE</h2>
                <button
                  onClick={() => setShowInstructions(false)}
                  className="text-gray-400 hover:text-white text-2xl"
                >
                  ✕
                </button>
              </div>

              <div className="space-y-6 text-gray-300">
                <section>
                  <h3 className="text-xl font-bold text-[#00ff88] mb-3">VNC Connection</h3>
                  <div className="bg-gray-900 border border-gray-800 p-4 haos-mono text-sm space-y-2">
                    <div>URL: <span className="text-[#00ff88]">vnc://localhost:5900</span></div>
                    <div>Password: <span className="text-[#0088ff]">haosplatform</span></div>
                  </div>
                </section>

                <section>
                  <h3 className="text-xl font-bold text-[#00ff88] mb-3">Game Controls</h3>
                  <div className="grid grid-cols-2 gap-4 haos-mono text-sm">
                    <div>
                      <div className="text-gray-500 mb-2">Movement:</div>
                      <div>W/A/S/D - Move</div>
                      <div>Mouse - Aim</div>
                      <div>Space - Jump</div>
                      <div>Ctrl - Duck</div>
                    </div>
                    <div>
                      <div className="text-gray-500 mb-2">Actions:</div>
                      <div>Left Click - Fire</div>
                      <div>R - Reload</div>
                      <div>B - Buy menu</div>
                      <div>~ - Console</div>
                    </div>
                  </div>
                </section>

                <section>
                  <h3 className="text-xl font-bold text-[#00ff88] mb-3">Console Commands</h3>
                  <div className="bg-gray-900 border border-gray-800 p-4 haos-mono text-xs space-y-1">
                    <div><span className="text-[#0088ff]">map de_dust2</span> - Change map</div>
                    <div><span className="text-[#0088ff]">bot_add</span> - Add bot</div>
                    <div><span className="text-[#0088ff]">fps_max 100</span> - Increase FPS</div>
                    <div><span className="text-[#0088ff]">sv_cheats 1</span> - Enable cheats</div>
                  </div>
                </section>

                <section>
                  <h3 className="text-xl font-bold text-[#00ff88] mb-3">Troubleshooting</h3>
                  <div className="space-y-2 text-sm">
                    <div>
                      <span className="text-[#0088ff]">Black screen:</span> Wait 10 seconds for Xvfb to initialize
                    </div>
                    <div>
                      <span className="text-[#0088ff]">Password wrong:</span> Use "haosplatform" not "haos"
                    </div>
                    <div>
                      <span className="text-[#0088ff]">No game files:</span> Copy CS 1.6 to container first
                    </div>
                  </div>
                </section>
              </div>

              <button
                onClick={() => setShowInstructions(false)}
                className="w-full mt-6 py-3 bg-[#00ff88] text-black font-bold haos-mono hover:bg-[#00ff88]/80 transition-all"
              >
                GOT IT!
              </button>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
