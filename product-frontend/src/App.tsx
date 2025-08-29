import React from 'react';
import ProductList from './components/ProductList';
import 'bootstrap/dist/css/bootstrap.min.css';
import './App.css';

const App: React.FC = () => {
  return (
    <div className="App">
      <nav className="navbar navbar-dark bg-dark">
        <div className="container">
          <span className="navbar-brand mb-0 h1">商品管理システム</span>
        </div>
      </nav>
      <ProductList />
    </div>
  );
};

export default App;