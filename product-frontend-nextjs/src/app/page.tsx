import ProductList from '@/components/ProductList'

export const metadata = {
  title: '商品一覧 - 商品管理システム',
  description: 'おすすめ商品の一覧ページです。検索機能付きで商品を探せます。',
}

export default function HomePage() {
  return (
    <div className="App">
      <ProductList />
    </div>
  )
}
