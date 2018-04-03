defmodule Userfs do

  @moduledoc """
  API calls to mount, and manage filesystems.
  """

  defstruct mount_point: nil, fs_data: nil

  @efuse_attr_dir         :userfs_defs.attr_dir()
  @efuse_attr_file        :userfs_defs.attr_file()
  @efuse_attr_symlink     :userfs_defs.attr_symlink()

  @type type :: unquote(@efuse_attr_dir) | unquote(@efuse_attr_file) | unquote(@efuse_attr_symlink)
  @type mode :: unquote(0o755) | unquote(0o644)

  @doc """
  Mount a filesystem. The three parameters are the mount point, the callback
  module which implements the filesystem, and a term, which can be anything, and
  is passed to the filesystem implementation initialisation.

  See `Userfs.Fs` for information on how to implement a filesystem callback
  module.

      iex> Userfs.mount("/tmp/my_elixir_fs", MyApp.Filesystem, my_fs_opts)
      {:ok, #PID<0.194.0>}

  Some example filesystems are provided which you can experiment with, and also
  inspect for improved undestanding of how a filesystem is implemented.
  """

  @spec mount(String.t, module, term) :: {:ok, pid}

  def mount(mount_point, fs_mod, fs_state) do
    Userfs.MountSup.start_child(mount_point, fs_mod, fs_state)
  end

  @doc """
  Unmount a filesystem.

      iex> Userfs.mount("/tmp/my_elixir_fs")
      {:ok, {:stopping, #PID<0.194.0>}}
  """

  @spec umount(String.t) :: {:ok, {:stopping, pid}} | {:error, :not_mounted}

  def umount(mount_point) do
    case Enum.filter(
          list(),
          fn({_pid, {this_mount_point, _fs_mod, _fs_state, _os_pid}}) ->
            this_mount_point == mount_point
          end
        ) do
      [] ->
        {:error, :not_mounted};
      [{pid, _status}] ->
        try do
          :ok = Userfs.Server.stop(pid)
        catch
          :exit,{:noproc,_} -> :ok
          :exit,:normal -> :ok
        end
        {:ok, pid}
    end
  end

  @doc """
  Enumerate the mounted filesystems. Returns a list of tuples, each
  tuple having two elements, the first being the PID of the Elixir process
  managing the FS, and the second being the status of the FS reported by it.
  The status is a tuple with four elements, the mount point of the FS, the
  callback module implementing the FS, the state of the FS (specific to the
  implementation module) and the OS PID of the port process which links the
  implementation module to the kernel of the OS.

      iex> Userfs.list()
      [{#PID<0.194.0>, {"/tmp/foo", Userfs.Fs.Hello, :ready, 29177}}]
  """

  @spec list() :: [{pid, {String.t, atom, term, integer}}]

  def list() do
    Enum.filter(
      Enum.map(
        Userfs.MountSup.which_children(),
        fn({:undefined, pid, :worker, [Userfs.Server]}) ->
          status = try do
            Userfs.Server.status(pid)
          catch
            :exit,{:noproc,_} -> :stopped
            :exit,{:normal,_} -> :stopped
          end
          {pid, status}
        end
      ),
      fn({_pid, status}) -> status !== :stopped end
    )
  end

end
