import { Button } from '@/components/ui/button'

interface HomeProps {
  message?: string
}

export default function Home({ message = 'Welcome to Tempo!' }: HomeProps) {
  return (
    <div className="min-h-screen bg-stone-50 flex items-center justify-center p-4">
      <div className="text-center">
        <div className="inline-flex items-center justify-center w-16 h-16 bg-stone-900 rounded-xl mb-6">
          <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <h1 className="text-3xl font-semibold text-stone-900 mb-2">Tempo</h1>
        <p className="text-stone-500 mb-6">{message}</p>
        <div className="flex items-center justify-center gap-3">
          <Button variant="default">Get Started</Button>
          <Button variant="outline">Learn More</Button>
        </div>
      </div>
    </div>
  )
}
