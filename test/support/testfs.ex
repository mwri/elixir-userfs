defmodule TestFs do

  use Userfs.Fs

  def userfs_init(mp, opts) do
    {:ok, {mp, opts}}
  end

  def userfs_readdir(state, _) do
    {:ok, [], state}
  end

  def userfs_getattr(state, _) do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end

  def userfs_read(state, _) do
    {:ok, "", state}
  end

  def userfs_readlink(state, _) do
    {:ok, ".", state}
  end

end
