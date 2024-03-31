defmodule VisualGarden.Gardens do
  @moduledoc """
  The Gardens context.
  """

  import Ecto.Query, warn: false
  alias VisualGarden.Repo

  alias VisualGarden.Gardens.Garden

  @doc """
  Returns the list of gardens.

  ## Examples

      iex> list_gardens()
      [%Garden{}, ...]

  """
  def list_gardens do
    Repo.all(Garden)
  end

  @doc """
  Gets a single garden.

  Raises `Ecto.NoResultsError` if the Garden does not exist.

  ## Examples

      iex> get_garden!(123)
      %Garden{}

      iex> get_garden!(456)
      ** (Ecto.NoResultsError)

  """
  def get_garden!(id), do: Repo.get!(Garden, id)

  @doc """
  Creates a garden.

  ## Examples

      iex> create_garden(%{field: value})
      {:ok, %Garden{}}

      iex> create_garden(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_garden(attrs \\ %{}) do
    %Garden{}
    |> Garden.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a garden.

  ## Examples

      iex> update_garden(garden, %{field: new_value})
      {:ok, %Garden{}}

      iex> update_garden(garden, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_garden(%Garden{} = garden, attrs) do
    garden
    |> Garden.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a garden.

  ## Examples

      iex> delete_garden(garden)
      {:ok, %Garden{}}

      iex> delete_garden(garden)
      {:error, %Ecto.Changeset{}}

  """
  def delete_garden(%Garden{} = garden) do
    Repo.delete(garden)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking garden changes.

  ## Examples

      iex> change_garden(garden)
      %Ecto.Changeset{data: %Garden{}}

  """
  def change_garden(%Garden{} = garden, attrs \\ %{}) do
    Garden.changeset(garden, attrs)
  end

  alias VisualGarden.Gardens.Product

  @doc """
  Returns the list of products.

  ## Examples

      iex> list_products()
      [%Products{}, ...]

  """
  def list_products do
    Repo.all(Product)
  end

  @doc """
  Gets a single products.

  Raises `Ecto.NoResultsError` if the Products does not exist.

  ## Examples

      iex> get_products!(123)
      %Products{}

      iex> get_products!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product!(id), do: Repo.get!(Product, id)

  @doc """
  Creates a products.

  ## Examples

      iex> create_products(%{field: value})
      {:ok, %Products{}}

      iex> create_products(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a products.

  ## Examples

      iex> update_products(products, %{field: new_value})
      {:ok, %Products{}}

      iex> update_products(products, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a products.

  ## Examples

      iex> delete_products(products)
      {:ok, %Products{}}

      iex> delete_products(products)
      {:error, %Ecto.Changeset{}}

  """
  def delete_product(%Product{} = product) do
    Repo.delete(product)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking products changes.

  ## Examples

      iex> change_products(products)
      %Ecto.Changeset{data: %Products{}}

  """
  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end
end
