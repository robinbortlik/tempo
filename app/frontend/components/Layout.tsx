import { Head } from '@inertiajs/react'
import { ReactNode } from 'react'

interface LayoutProps {
  children: ReactNode
  title?: string
}

export default function Layout({ children, title }: LayoutProps) {
  const pageTitle = title ? `${title} - Tempo` : 'Tempo'

  return (
    <>
      <Head title={pageTitle} />
      {/* Navigation placeholder - will be implemented in Phase 12 */}
      <main>{children}</main>
    </>
  )
}
