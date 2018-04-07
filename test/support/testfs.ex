defmodule TestFs do

  def userfs_init(mp, opts) do
    {:ok, {mp, opts}}
  end

  def userfs_readdir(_, {_mp, _opts} = state) do
    {:ok, [], state}
  end

  def userfs_getattr(_, {_mp, _opts} = state) do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end

  def userfs_read(_, {_mp, _opts} = state) do
    {:ok, "", state}
  end

  def userfs_readlink(_, {_mp, _opts} = state) do
    {:ok, ".", state}
  end

end
