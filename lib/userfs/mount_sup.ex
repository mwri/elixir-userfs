defmodule Userfs.MountSup do

  @moduledoc """
  Mount supervisor.
  """

  use Supervisor

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

  @spec start_child(String.t, module, term) :: {:ok, pid} | {:error, term}

  def start_child(mount_point, fs_mod, fs_state) do
    Supervisor.start_child(__MODULE__, [mount_point, fs_mod, fs_state])
  end

  @spec which_children() :: [{:undefined, Supervisor.child, :worker, [Userfs.Server]}]

  def which_children() do
    Supervisor.which_children(__MODULE__)
  end

end
