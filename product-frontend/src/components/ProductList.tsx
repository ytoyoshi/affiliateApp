import React from 'react';
import ProductCard from './ProductCard';
import SearchBar from './SearchBar';
import { useProducts } from '../hooks/useProducts';

const ProductList: React.FC = () => {
  const { 
    products, 
    loading, 
    error, 
    isSearching, 
    fetchAllProducts, 
    searchProducts 
  } = useProducts();

  const handleSearch = async (keyword: string): Promise<void> => {
    await searchProducts(keyword);
  };

  const handleClear = (): void => {
    fetchAllProducts();
  };

  if (loading) {
    return (
      <div className="container mt-4">
        <div className="text-center">
          <div className="spinner-border" role="status">
            <span className="visually-hidden">読み込み中...</span>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="container mt-4">
        <div className="alert alert-danger" role="alert">
          {error}
          <button 
            className="btn btn-outline-danger ms-3"
            onClick={fetchAllProducts}
          >
            再試行
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="container mt-4">
      <h1 className="text-center mb-4">商品一覧</h1>
      
      <SearchBar onSearch={handleSearch} onClear={handleClear} />
      
      {isSearching && (
        <div className="alert alert-info">
          検索結果: {products.length}件
        </div>
      )}
      
      {products.length === 0 ? (
        <div className="text-center">
          <p>商品が見つかりませんでした。</p>
        </div>
      ) : (
        <div className="row">
          {products.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>
      )}
    </div>
  );
};

export default ProductList;