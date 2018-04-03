defmodule Userfs.Fs.Example do

  @moduledoc """
  A simple example filesystem implementation with a few arbitrary
  files, directories and symbolic links.
  """

  use Userfs.Fs

  def userfs_init(_mount_point, _state) do
    {:ok, nil}
  end
  def userfs_readdir(state, "/") do
    {:ok, ["dir1", "dir2", "file1", "file2", "link1", "link2"], state}
  end
  def userfs_readdir(state, "/dir1") do
    {:ok, ["file1"], state}
  end
  def userfs_readdir(state, "/dir2") do
    {:ok, ["file3", "link2"], state}
  end
  def userfs_readdir(state, _) do
    {:error, @error_noent, state}
  end

  def userfs_getattr(state, "/") do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def userfs_getattr(state, "/dir1") do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def userfs_getattr(state, "/dir2") do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def userfs_getattr(state, "/file1") do
    {:ok, {0o0644, @attr_file, file_size(state, "/file1")}, state}
  end
  def userfs_getattr(state, "/file2") do
    {:ok, {0o0644, @attr_file, file_size(state, "/file2")}, state}
  end
  def userfs_getattr(state, "/link1") do
    {:ok, {0o0755, @attr_symlink, 0}, state}
  end
  def userfs_getattr(state, "/link2") do
    {:ok, {0o0755, @attr_symlink, 0}, state}
  end
  def userfs_getattr(state, "/dir1/file1") do
    {:ok, {0o0644, @attr_file, file_size(state, "/dir1/file1")}, state}
  end
  def userfs_getattr(state, "/dir2/file3") do
    {:ok, {0o0644, @attr_file, file_size(state, "/dir2/file3")}, state}
  end
  def userfs_getattr(state, "/dir2/link2") do
    {:ok, {0o0755, @attr_symlink, 0}, state}
  end
  def userfs_getattr(state, _) do
    {:error, @error_noent, state}
  end

  def userfs_readlink(state, "/link1") do
    {:ok, "file1", state}
  end
  def userfs_readlink(state, "/link2") do
    {:ok, "dir1/file1", state}
  end
  def userfs_readlink(state, "/dir2/link2") do
    {:ok, "../file2", state}
  end
  def userfs_readlink(state, _) do
    {:error, @error_noent, state}
  end

  def userfs_read(state, "/file1") do
    {:ok, "This is file one in the root directory.", state}
  end
  def userfs_read(state, "/file2") do
    {:ok, "This is file two in the root directory.", state}
  end
  def userfs_read(state, "/dir1/file1") do
    {:ok, "This is file one in directory one.", state}
  end
  def userfs_read(state, "/dir2/file3") do
    {:ok, "This is file three in directory two.", state}
  end
  def userfs_read(state, _) do
    {:error, @error_noent, state}
  end

  def file_size(state, path) do
    {:ok, content, _state} = userfs_read(state, path)
    byte_size(content)
  end

end
