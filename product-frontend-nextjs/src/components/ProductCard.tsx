import React from 'react';
import Link from 'next/link';
import { Product } from '../types/Product';

interface ProductCardProps {
  product: Product;
}

const ProductCard: React.FC<ProductCardProps> = ({ product }) => {
  return (
    <div className="col-md-4 mb-4">
      <div className="card h-100">
        <img 
          src={product.imageUrl} 
          className="card-img-top" 
          alt={product.name}
          style={{ height: '200px', objectFit: 'cover' }}
        />
        <div className="card-body d-flex flex-column">
          <h5 className="card-title">{product.name}</h5>
          <p className="card-text flex-grow-1">{product.description}</p>
          <div className="mt-auto">
            <h4 className="text-primary">¥{product.price.toLocaleString()}</h4>
            <Link 
              href={`/products/${product.id}`}
              className="btn btn-primary btn-sm mt-2"
            >
              詳細を見る
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProductCard;