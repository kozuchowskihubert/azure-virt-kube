'use client'

import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { fetchApplications, createApplication, deleteApplication } from '@/lib/api'
import toast from 'react-hot-toast'

interface Application {
  id: string
  name: string
  executable_path: string
  description?: string
  icon_url?: string
}

interface ApplicationFormData {
  name: string
  executable_path: string
  description: string
  icon_url: string
}

export default function ApplicationList() {
  const [showForm, setShowForm] = useState(false)
  const queryClient = useQueryClient()

  const { data: applications, isLoading } = useQuery({
    queryKey: ['applications'],
    queryFn: fetchApplications,
  })

  const createMutation = useMutation({
    mutationFn: createApplication,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['applications'] })
      setShowForm(false)
      toast.success('Application added successfully!')
    },
    onError: () => {
      toast.error('Failed to add application')
    },
  })

  const deleteMutation = useMutation({
    mutationFn: deleteApplication,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['applications'] })
      toast.success('Application deleted successfully!')
    },
  })

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-white">Windows Applications</h2>
          <button
            onClick={() => setShowForm(!showForm)}
            className="bg-wine-600 hover:bg-wine-700 text-white px-4 py-2 rounded-lg transition-colors"
          >
            {showForm ? '✕ Cancel' : '➕ Add Application'}
          </button>
        </div>

        {showForm && (
          <ApplicationForm
            onSubmit={(data: ApplicationFormData) => createMutation.mutate(data)}
            isLoading={createMutation.isPending}
          />
        )}

        {isLoading ? (
          <div className="text-gray-300">Loading applications...</div>
        ) : applications && applications.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {applications.map((app: any) => (
              <ApplicationCard
                key={app.id}
                application={app}
                onDelete={() => deleteMutation.mutate(app.id)}
              />
            ))}
          </div>
        ) : (
          <div className="text-center text-gray-400 py-12">
            <div className="text-6xl mb-4">📦</div>
            <p className="text-lg">No applications added yet.</p>
            <p className="text-sm mt-2">Click "Add Application" to get started.</p>
          </div>
        )}
      </div>
    </div>
  )
}

function ApplicationCard({ application, onDelete }: any) {
  return (
    <div className="bg-white/5 rounded-lg p-4 border border-white/10 hover:border-wine-500 transition-all">
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center gap-3">
          <div className="text-4xl">{application.icon_url || '🎮'}</div>
          <div>
            <h3 className="text-white font-bold">{application.name}</h3>
            <p className="text-gray-400 text-sm truncate max-w-[200px]">
              {application.executable_path}
            </p>
          </div>
        </div>
      </div>
      
      {application.description && (
        <p className="text-gray-300 text-sm mb-3">{application.description}</p>
      )}

      <div className="flex gap-2">
        <button className="flex-1 bg-green-600 hover:bg-green-700 text-white px-3 py-2 rounded text-sm transition-colors">
          ▶️ Run
        </button>
        <button
          onClick={onDelete}
          className="bg-red-600 hover:bg-red-700 text-white px-3 py-2 rounded text-sm transition-colors"
        >
          🗑️
        </button>
      </div>
    </div>
  )
}

interface ApplicationFormProps {
  onSubmit: (data: ApplicationFormData) => void
  isLoading: boolean
}

function ApplicationForm({ onSubmit, isLoading }: ApplicationFormProps) {
  const [formData, setFormData] = useState<ApplicationFormData>({
    name: '',
    executable_path: '',
    description: '',
    icon_url: '',
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onSubmit(formData)
  }

  return (
    <form onSubmit={handleSubmit} className="bg-white/5 rounded-lg p-6 mb-6 border border-white/10">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">
            Application Name
          </label>
          <input
            type="text"
            required
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-wine-500"
            placeholder="e.g., Notepad++"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">
            Executable Path
          </label>
          <input
            type="text"
            required
            value={formData.executable_path}
            onChange={(e) => setFormData({ ...formData, executable_path: e.target.value })}
            className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-wine-500"
            placeholder="C:\\Program Files\\app.exe"
          />
        </div>
      </div>

      <div className="mb-4">
        <label className="block text-sm font-medium text-gray-300 mb-2">
          Description (Optional)
        </label>
        <textarea
          value={formData.description}
          onChange={(e) => setFormData({ ...formData, description: e.target.value })}
          className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-wine-500"
          placeholder="Describe what this application does..."
          rows={3}
        />
      </div>

      <button
        type="submit"
        disabled={isLoading}
        className="w-full bg-wine-600 hover:bg-wine-700 disabled:bg-gray-600 text-white px-4 py-2 rounded-lg transition-colors"
      >
        {isLoading ? 'Adding...' : 'Add Application'}
      </button>
    </form>
  )
}
