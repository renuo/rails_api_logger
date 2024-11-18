class Api::BooksController < ApplicationController
  def index
    render json: Book.all
  end

  def create
    head :no_content
  end
end
