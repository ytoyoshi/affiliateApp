"use client"
import React, { useState, FormEvent } from 'react';

interface SearchBarProps {
  onSearch: (keyword: string) => void;
  onClear: () => void;
}

const SearchBar: React.FC<SearchBarProps> = ({ onSearch, onClear }) => {
  const [keyword, setKeyword] = useState<string>('');

  const handleSubmit = (e: FormEvent<HTMLFormElement>): void => {
    e.preventDefault();
    onSearch(keyword);
  };

  const handleClear = (): void => {
    setKeyword('');
    onClear();
  };

  return (
    <div className="row mb-4">
      <div className="col-md-8 mx-auto">
        <form onSubmit={handleSubmit}>
          <div className="input-group">
            <input
              type="text"
              className="form-control"
              placeholder="商品名または説明で検索..."
              value={keyword}
              onChange={(e) => setKeyword(e.target.value)}
            />
            <button className="btn btn-primary" type="submit">
              検索
            </button>
            <button 
              className="btn btn-outline-secondary" 
              type="button"
              onClick={handleClear}
            >
              クリア
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default SearchBar;