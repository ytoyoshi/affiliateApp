import type { Metadata } from 'next'
import 'bootstrap/dist/css/bootstrap.min.css'
import './globals.css'

export const metadata: Metadata = {
  title: '商品管理システム',
  description: 'アフィリエイト対応商品管理システム',
  keywords: ['商品', 'アフィリエイト', 'レビュー'],
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ja">
      <body>
        <nav className="navbar navbar-dark bg-dark">
          <div className="container">
            <span className="navbar-brand mb-0 h1">商品管理システム</span>
          </div>
        </nav>
        {children}
      </body>
    </html>
  )
}