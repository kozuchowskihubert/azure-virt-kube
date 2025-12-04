'use client'

import { useState } from 'react'
import { useQuery, useMutation } from '@tanstack/react-query'
import { fetchComponentTemplates, executeWorkflow } from '@/lib/api'
import toast from 'react-hot-toast'

export default function LowCodeBuilder() {
  const [components, setComponents] = useState<any[]>([])
  const [selectedComponent, setSelectedComponent] = useState<any>(null)

  const { data: templates } = useQuery({
    queryKey: ['component-templates'],
    queryFn: fetchComponentTemplates,
  })

  const executeMutation = useMutation({
    mutationFn: executeWorkflow,
    onSuccess: () => {
      toast.success('Workflow executed successfully!')
    },
    onError: () => {
      toast.error('Workflow execution failed')
    },
  })

  const addComponent = (template: any) => {
    const newComponent = {
      id: Date.now(),
      ...template,
      config: {},
      position: { x: 100, y: 100 },
    }
    setComponents([...components, newComponent])
    toast.success(`Added ${template.name}`)
  }

  const removeComponent = (id: number) => {
    setComponents(components.filter(c => c.id !== id))
  }

  const executeWorkflowHandler = () => {
    executeMutation.mutate({
      components,
      connections: [],
    })
  }

  return (
    <div className="grid grid-cols-12 gap-6 animate-fade-in">
      {/* Component Palette */}
      <div className="col-span-3 space-y-4">
        <div className="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20">
          <h2 className="text-xl font-bold text-white mb-4">Components</h2>
          
          {templates && (
            <>
              <ComponentSection
                title="UI Components"
                components={templates.ui_components}
                onAdd={addComponent}
              />
              <ComponentSection
                title="Logic"
                components={templates.logic_components}
                onAdd={addComponent}
              />
              <ComponentSection
                title="Wine Actions"
                components={templates.wine_components}
                onAdd={addComponent}
              />
            </>
          )}
        </div>
      </div>

      {/* Canvas */}
      <div className="col-span-6">
        <div className="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20 min-h-[600px]">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-bold text-white">Workflow Canvas</h2>
            <div className="flex gap-2">
              <button
                onClick={executeWorkflowHandler}
                disabled={components.length === 0 || executeMutation.isPending}
                className="bg-green-600 hover:bg-green-700 disabled:bg-gray-600 text-white px-4 py-2 rounded-lg text-sm transition-colors"
              >
                ▶️ Execute
              </button>
              <button
                onClick={() => setComponents([])}
                className="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-lg text-sm transition-colors"
              >
                🗑️ Clear
              </button>
            </div>
          </div>

          {components.length === 0 ? (
            <div className="text-center text-gray-400 py-24">
              <div className="text-6xl mb-4">🎨</div>
              <p className="text-lg">Drag components here to build your workflow</p>
            </div>
          ) : (
            <div className="space-y-3">
              {components.map((component) => (
                <div
                  key={component.id}
                  onClick={() => setSelectedComponent(component)}
                  className={`bg-white/5 rounded-lg p-4 border cursor-pointer transition-all ${
                    selectedComponent?.id === component.id
                      ? 'border-wine-500 bg-white/10'
                      : 'border-white/10 hover:border-white/30'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <span className="text-2xl">{component.icon}</span>
                      <div>
                        <h3 className="text-white font-medium">{component.name}</h3>
                        <p className="text-gray-400 text-sm">{component.type}</p>
                      </div>
                    </div>
                    <button
                      onClick={(e) => {
                        e.stopPropagation()
                        removeComponent(component.id)
                      }}
                      className="text-red-400 hover:text-red-300"
                    >
                      ✕
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Properties Panel */}
      <div className="col-span-3">
        <div className="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20">
          <h2 className="text-xl font-bold text-white mb-4">Properties</h2>
          
          {selectedComponent ? (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Component Name
                </label>
                <input
                  type="text"
                  value={selectedComponent.name}
                  onChange={(e) => {
                    const updated = components.map(c =>
                      c.id === selectedComponent.id
                        ? { ...c, name: e.target.value }
                        : c
                    )
                    setComponents(updated)
                    setSelectedComponent({ ...selectedComponent, name: e.target.value })
                  }}
                  className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded-lg text-white"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Type
                </label>
                <div className="px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-gray-400">
                  {selectedComponent.type}
                </div>
              </div>

              <div className="pt-4 border-t border-white/10">
                <button
                  onClick={() => removeComponent(selectedComponent.id)}
                  className="w-full bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-lg text-sm transition-colors"
                >
                  Remove Component
                </button>
              </div>
            </div>
          ) : (
            <div className="text-center text-gray-400 py-12">
              <div className="text-4xl mb-2">👆</div>
              <p className="text-sm">Select a component to edit properties</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

function ComponentSection({ title, components, onAdd }: any) {
  return (
    <div className="mb-6">
      <h3 className="text-sm font-semibold text-gray-400 mb-2">{title}</h3>
      <div className="space-y-2">
        {components?.map((comp: any, idx: number) => (
          <button
            key={idx}
            onClick={() => onAdd(comp)}
            className="w-full bg-white/5 hover:bg-white/10 border border-white/10 rounded-lg p-3 text-left transition-all flex items-center gap-2"
          >
            <span className="text-xl">{comp.icon}</span>
            <span className="text-white text-sm">{comp.name}</span>
          </button>
        ))}
      </div>
    </div>
  )
}
