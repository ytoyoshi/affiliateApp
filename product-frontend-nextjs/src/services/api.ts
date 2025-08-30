import axios, { AxiosResponse } from 'axios';
import { Product, CreateProductRequest, UpdateProductRequest } from '../types/Product';

const API_BASE_URL = 'http://localhost:8080/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const productService = {
  getAllProducts: (): Promise<AxiosResponse<Product[]>> => 
    api.get<Product[]>('/products'),
  
  searchProducts: (keyword: string): Promise<AxiosResponse<Product[]>> => 
    api.get<Product[]>(`/products/search?keyword=${encodeURIComponent(keyword)}`),
  
  getProductById: (id: number): Promise<AxiosResponse<Product>> => 
    api.get<Product>(`/products/${id}`),
  
  createProduct: (product: CreateProductRequest): Promise<AxiosResponse<Product>> => 
    api.post<Product>('/products', product),
  
  updateProduct: (id: number, product: UpdateProductRequest): Promise<AxiosResponse<Product>> => 
    api.put<Product>(`/products/${id}`, product),
  
  deleteProduct: (id: number): Promise<AxiosResponse<void>> => 
    api.delete<void>(`/products/${id}`),
};

export default api;