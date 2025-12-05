import React, { useState } from 'react';
import { motion } from 'framer-motion';

interface Game {
  id: number;
  name: string;
  executable: string;
  description: string;
  boxArt: string;
  status: 'ready' | 'running' | 'stopped';
  category: string;
  releaseYear: number;
  players: string;
}

export default function HAOSGameLibrary() {
  const [selectedGame, setSelectedGame] = useState<Game | null>(null);
  const [filter, setFilter] = useState('all');

  const games: Game[] = [
    {
      id: 1,
      name: 'Counter-Strike 1.6',
      executable: '/app/games/cs16/hl.exe',
      description: 'The legendary tactical FPS that defined competitive gaming. Join Counter-Terrorists or Terrorists in classic maps.',
      boxArt: 'https://upload.wikimedia.org/wikipedia/en/6/6e/Counter-Strike_box.jpg',
      status: 'ready',
      category: 'FPS',
      releaseYear: 2000,
      players: '1-32',
    },
    {
      id: 2,
      name: 'Half-Life',
      executable: '/app/games/hl/hl.exe',
      description: 'Gordon Freeman fights alien invasion at Black Mesa Research Facility in this revolutionary FPS.',
      boxArt: 'https://upload.wikimedia.org/wikipedia/en/f/fa/Half-Life_Cover_Art.jpg',
      status: 'ready',
      category: 'FPS',
      releaseYear: 1998,
      players: '1',
    },
    {
      id: 3,
      name: 'Age of Empires II',
      executable: '/app/games/aoe2/empires2.exe',
      description: 'Build your empire, command your army, and conquer civilizations in this classic RTS masterpiece.',
      boxArt: 'https://upload.wikimedia.org/wikipedia/en/d/d3/Age_II_-_The_Age_of_Kings_Coverart.png',
      status: 'ready',
      category: 'RTS',
      releaseYear: 1999,
      players: '1-8',
    },
  ];

  const categories = ['all', 'FPS', 'RTS', 'RPG', 'Strategy'];

  const filteredGames = filter === 'all' 
    ? games 
    : games.filter(g => g.category === filter);

  return (
    <div className="min-h-screen bg-black text-white">
      {/* HEADER */}
      <div className="border-b border-gray-800 bg-black/90 backdrop-blur">
        <div className="max-w-7xl mx-auto px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-4xl font-black haos-heading">
                // GAME <span className="text-[#00ff88]">LIBRARY</span>
              </h1>
              <p className="text-gray-400 haos-mono text-sm mt-2">
                {filteredGames.length} GAMES AVAILABLE
              </p>
            </div>
            <div className="flex gap-4">
              <div className="px-4 py-2 bg-[#00ff88]/10 border border-[#00ff88]/30 rounded-none">
                <span className="haos-mono text-xs text-[#00ff88]">● WINE 8.0.2</span>
              </div>
              <div className="px-4 py-2 bg-[#0088ff]/10 border border-[#0088ff]/30 rounded-none">
                <span className="haos-mono text-xs text-[#0088ff]">CPU: 24%</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* CATEGORY FILTER */}
      <div className="border-b border-gray-900 bg-black">
        <div className="max-w-7xl mx-auto px-8 py-4">
          <div className="flex gap-2">
            {categories.map((cat) => (
              <button
                key={cat}
                onClick={() => setFilter(cat)}
                className={`px-4 py-2 haos-mono text-xs font-bold uppercase transition-all ${
                  filter === cat
                    ? 'bg-[#00ff88] text-black'
                    : 'bg-gray-900 text-gray-400 hover:bg-gray-800 hover:text-white'
                }`}
              >
                {cat}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* GAME GRID */}
      <div className="max-w-7xl mx-auto px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredGames.map((game, index) => (
            <motion.div
              key={game.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              className="group cursor-pointer"
              onClick={() => setSelectedGame(game)}
            >
              <div className="relative border border-gray-800 hover:border-[#00ff88] transition-all bg-black overflow-hidden">
                {/* CORNER ACCENTS */}
                <div className="absolute top-0 left-0 w-4 h-4 border-t-2 border-l-2 border-[#00ff88] opacity-0 group-hover:opacity-100 transition-opacity" />
                <div className="absolute bottom-0 right-0 w-4 h-4 border-b-2 border-r-2 border-[#0088ff] opacity-0 group-hover:opacity-100 transition-opacity" />

                {/* BOX ART */}
                <div className="relative h-64 bg-gray-900 overflow-hidden">
                  <img
                    src={game.boxArt}
                    alt={game.name}
                    className="w-full h-full object-cover opacity-80 group-hover:opacity-100 group-hover:scale-110 transition-all duration-500"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black via-transparent to-transparent" />
                  
                  {/* STATUS INDICATOR */}
                  <div className="absolute top-4 right-4">
                    <div className={`px-3 py-1 haos-mono text-xs font-bold ${
                      game.status === 'ready'
                        ? 'bg-[#00ff88]/20 text-[#00ff88] border border-[#00ff88]/50'
                        : 'bg-gray-800 text-gray-400 border border-gray-700'
                    }`}>
                      {game.status === 'ready' && '● '}
                      {game.status.toUpperCase()}
                    </div>
                  </div>

                  {/* CATEGORY BADGE */}
                  <div className="absolute top-4 left-4">
                    <div className="px-3 py-1 bg-black/80 border border-[#0088ff]/50 haos-mono text-xs text-[#0088ff]">
                      {game.category}
                    </div>
                  </div>
                </div>

                {/* GAME INFO */}
                <div className="p-6 space-y-4">
                  <div>
                    <h3 className="text-2xl font-black haos-heading mb-2">
                      {game.name}
                    </h3>
                    <p className="text-gray-400 text-sm leading-relaxed">
                      {game.description}
                    </p>
                  </div>

                  <div className="flex items-center justify-between text-xs haos-mono text-gray-500">
                    <span>{game.releaseYear}</span>
                    <span>{game.players} PLAYERS</span>
                  </div>

                  {/* PLAY BUTTON */}
                  <button className="w-full py-3 bg-[#00ff88] text-black font-black haos-mono text-sm hover:bg-[#00ff88]/80 transition-all flex items-center justify-center gap-2 group-hover:shadow-[0_0_20px_rgba(0,255,136,0.5)]">
                    <span>▶</span>
                    <span>LAUNCH GAME</span>
                  </button>

                  {/* TECHNICAL INFO */}
                  <div className="pt-4 border-t border-gray-900 space-y-1">
                    <div className="flex justify-between text-xs haos-mono text-gray-600">
                      <span>EXECUTABLE:</span>
                      <span className="text-[#00ff88]">{game.executable.split('/').pop()}</span>
                    </div>
                    <div className="flex justify-between text-xs haos-mono text-gray-600">
                      <span>WINE PREFIX:</span>
                      <span className="text-[#0088ff]">/root/.wine</span>
                    </div>
                  </div>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* GAME DETAIL MODAL */}
      {selectedGame && (
        <div
          className="fixed inset-0 bg-black/95 backdrop-blur-sm z-50 flex items-center justify-center p-8"
          onClick={() => setSelectedGame(null)}
        >
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="bg-black border border-[#00ff88] max-w-4xl w-full max-h-[90vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            {/* MODAL HEADER */}
            <div className="border-b border-[#00ff88]/30 p-6 flex items-center justify-between">
              <div>
                <h2 className="text-3xl font-black haos-heading">{selectedGame.name}</h2>
                <p className="text-gray-400 haos-mono text-sm mt-1">{selectedGame.category} • {selectedGame.releaseYear}</p>
              </div>
              <button
                onClick={() => setSelectedGame(null)}
                className="text-gray-400 hover:text-white text-2xl"
              >
                ✕
              </button>
            </div>

            {/* MODAL CONTENT */}
            <div className="grid grid-cols-2 gap-6 p-6">
              <div>
                <img
                  src={selectedGame.boxArt}
                  alt={selectedGame.name}
                  className="w-full border border-gray-800"
                />
              </div>
              <div className="space-y-6">
                <div>
                  <h3 className="text-sm font-bold haos-mono text-[#00ff88] mb-2">DESCRIPTION</h3>
                  <p className="text-gray-300 leading-relaxed">{selectedGame.description}</p>
                </div>

                <div>
                  <h3 className="text-sm font-bold haos-mono text-[#00ff88] mb-2">SPECIFICATIONS</h3>
                  <div className="space-y-2 haos-mono text-xs">
                    <div className="flex justify-between">
                      <span className="text-gray-500">Executable:</span>
                      <span className="text-white">{selectedGame.executable}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Players:</span>
                      <span className="text-white">{selectedGame.players}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">Wine Arch:</span>
                      <span className="text-white">win32</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">VNC Port:</span>
                      <span className="text-white">5900</span>
                    </div>
                  </div>
                </div>

                <div>
                  <h3 className="text-sm font-bold haos-mono text-[#00ff88] mb-2">LAUNCH OPTIONS</h3>
                  <div className="space-y-2">
                    <label className="flex items-center gap-2 text-sm">
                      <input type="checkbox" className="accent-[#00ff88]" defaultChecked />
                      <span>Enable console</span>
                    </label>
                    <label className="flex items-center gap-2 text-sm">
                      <input type="checkbox" className="accent-[#00ff88]" />
                      <span>OpenGL mode</span>
                    </label>
                    <label className="flex items-center gap-2 text-sm">
                      <input type="checkbox" className="accent-[#00ff88]" defaultChecked />
                      <span>Full screen</span>
                    </label>
                  </div>
                </div>

                <button className="w-full py-4 bg-[#00ff88] text-black font-black haos-mono hover:bg-[#00ff88]/80 transition-all">
                  ▶ LAUNCH {selectedGame.name.toUpperCase()}
                </button>
              </div>
            </div>
          </motion.div>
        </div>
      )}
    </div>
  );
}
