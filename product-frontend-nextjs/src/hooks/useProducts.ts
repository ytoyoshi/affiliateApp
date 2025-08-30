"use client"

import { useState, useEffect } from 'react';
import { Product } from '../types/Product';
import { productService } from '../services/api';

interface UseProductsReturn {
  products: Product[];
  loading: boolean;
  error: string | null;
  isSearching: boolean;
  fetchAllProducts: () => Promise<void>;
  searchProducts: (keyword: string) => Promise<void>;
}

export const useProducts = (): UseProductsReturn => {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [isSearching, setIsSearching] = useState<boolean>(false);

  const fetchAllProducts = async (): Promise<void> => {
    try {
      setLoading(true);
      setError(null);
      const response = await productService.getAllProducts();
      setProducts(response.data);
      setIsSearching(false);
    } catch (err) {
      setError('商品の取得に失敗しました。');
      console.error('Error fetching products:', err);
    } finally {
      setLoading(false);
    }
  };

  const searchProducts = async (keyword: string): Promise<void> => {
    if (!keyword.trim()) {
      await fetchAllProducts();
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const response = await productService.searchProducts(keyword);
      setProducts(response.data);
      setIsSearching(true);
    } catch (err) {
      setError('検索に失敗しました。');
      console.error('Error searching products:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAllProducts();
  }, []);

  return {
    products,
    loading,
    error,
    isSearching,
    fetchAllProducts,
    searchProducts,
  };
};