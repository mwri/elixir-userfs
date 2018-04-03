defmodule Userfs.App do

  use Application

  @moduledoc """
  """

  def start(_type, _args) do
    {:ok, _port_path} = find_port!()
    import Supervisor.Spec
    children = [
      supervisor(Userfs.MountSup, [])
    ]
    opts = [strategy: :one_for_one, name: Userfs.Sup]
    Supervisor.start_link(children, opts)
  end

  def find_port!() do
    port_path = Application.app_dir(:efuse) <> "/priv/efuse"
    {true, port_path} = {:filelib.is_file(port_path), port_path}
    {:ok, port_path}
  end

end
