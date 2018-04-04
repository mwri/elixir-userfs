defmodule Userfs.MountSup do

  @moduledoc """
  Mount supervisor.
  """

  use Supervisor

  @doc """
  Starts the supervisor and links to it.
  """

  @spec start_link() :: {:ok, pid} | {:error, term}

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    import Supervisor.Spec
    children = [
      {Userfs.Server, {Userfs.Server, :start_link, []}, :transient, 30, :worker, [Userfs.Server]}
    ]
    opts = [strategy: :simple_one_for_one]
    supervise(children, opts)
  end

  @doc """
  Start a child (a supervised filesystem). The arguments are the mount
  point, the implementation module and the options / config. See `Userfs.mount/3`
  for more details.
  """

  @spec start_child(String.t, module, term) :: {:ok, pid} | {:error, term}

  def start_child(mount_point, fs_mod, fs_state) do
    Supervisor.start_child(__MODULE__, [mount_point, fs_mod, fs_state])
  end

  @doc """
  Return the supervisors running children. See `Supervisor.which_children/1` for
  more details.
  """

  @spec which_children() :: [{:undefined, Supervisor.child, :worker, [Userfs.Server]}]

  def which_children() do
    Supervisor.which_children(__MODULE__)
  end

end
