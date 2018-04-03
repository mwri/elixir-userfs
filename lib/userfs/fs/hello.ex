defmodule Userfs.Fs.Hello do

  @moduledoc """
  A simple 'hello world' filesystem implementation.
  """

  use Userfs.Fs

  def userfs_init(_mount_point, _state) do
    {:ok, :ready}
  end

  def userfs_readdir(state, "/") do
    {:ok, ["hello", "world"], state}
  end
  def userfs_readdir(state, _) do
    {:error, @error_noent, state}
  end

  def userfs_getattr(state, "/") do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end

  def userfs_getattr(state, "/hello") do
    {:ok, {0o0644, @attr_file, byte_size("Hello world!\n")}, state}
  end

  def userfs_getattr(state, "/world") do
    {:ok, {0o0755, @attr_symlink, String.length("hello")}, state}
  end

  def userfs_getattr(state, _) do
    {:error, @error_noent, state}
  end

  def userfs_readlink(state, "/world") do
    {:ok, "hello", state}
  end

  def userfs_readlink(state, _) do
    {:error, @error_noent, state}
  end

  def userfs_read(state, "/hello") do
    {:ok, "Hello world!\n", state}
  end

  def userfs_read(state, _) do
    {:error, @error_noent, state}
  end

end
