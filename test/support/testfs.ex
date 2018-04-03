defmodule TestFs do

  def userfs_init(_, _) do
    throw {:error, :unimplemented, :userfs_init}
  end

  def userfs_readdir(_, _) do
    throw {:error, :unimplemented, :userfs_readdir}
  end

  def userfs_getattr(_, _) do
    throw {:error, :unimplemented, :userfs_getattr}
  end

  def userfs_read(_, _) do
    throw {:error, :unimplemented, :userfs_read}
  end

  def userfs_readlink(_, _) do
    throw {:error, :unimplemented, :userfs_readlink}
  end

end
