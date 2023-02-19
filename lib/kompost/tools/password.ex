defmodule Kompost.Tools.Password do
  @moduledoc """
  Helpers to generate and verify passwords using `:crypto`.
  """

  @default_length 32

  @doc """
  Generates a random string to be used as password.
  """
  @spec random_string(length :: non_neg_integer()) :: binary()
  def random_string(length \\ @default_length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end

  @doc """
  Checks the given password against the given hash for the given algorithm and return true if they match,
  false otherwise.

  iex> Kompost.Tools.Password.verify_password("rabbit_password_hashing_sha256", "123123", "PuSRFCZ90wY8W/N4yIrv88MwxI8bftMEawWdciqRUf0WLzoV")
  true

  iex> Kompost.Tools.Password.verify_password("rabbit_password_hashing_sha256", "incorrect", "PuSRFCZ90wY8W/N4yIrv88MwxI8bftMEawWdciqRUf0WLzoV")
  false
  """
  @spec verify_password(binary(), binary(), binary()) :: bool()
  def verify_password("rabbit_password_hashing_sha256", password, password_hash64) do
    password_hash = password_hash64 |> Base.decode64!()
    salt = String.slice(password_hash, 0, 4)

    salted_pw = salt <> password
    hashed_password = :crypto.hash(:sha256, salted_pw)
    salt <> hashed_password == password_hash
  end
end
