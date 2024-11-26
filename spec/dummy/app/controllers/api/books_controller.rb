class Api::BooksController < ApplicationController
  def index
    render json: Book.all
  end

  def create
    head :no_content
  end

  def update
    @book = Book.find(params[:id])
    @book.update!(title: nil)
    head :no_content
  end
end
