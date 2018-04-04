defmodule Userfs.Server do

  @moduledoc """
  The server joins the FS implementation (the `Userfs.Fs` callback module) to the
  port (which joins the Elixir run time to the OS / kernel).
  """

  use GenServer
  use Userfs.Fs, attribs: true

  defstruct mount_point: nil, fs_mod: nil, fs_state: nil, phase: :init, port: nil, port_os_pid: nil

  @doc """
  Called by the `Userfs.MountSup` supervisor, `start_link` starts an FS
  as a `GenServer`. The three arguments are the same as for `Userfs.mount/3`.
  """

  @spec start_link(String.t, module, term) :: {:ok, pid} | {:error, term}

  def start_link(mount_point, fs_mod, fs_opts) do
    GenServer.start_link(__MODULE__, [mount_point, fs_mod, fs_opts], [])
  end

  @doc """
  Called to stop an FS. A single argument, the PID of the server, is given.
  This is the same as `Userfs.umount/1` except it requires the PID of the
  `GenServer` process, instead of the mount point.
  """

  @spec stop(pid) :: :ok

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  @doc """
  Return a tuple representing the state of the FS. This PID of the `GenServer`
  process must be passed as an argument.

  The tuple elements are the mount point, callback module, the internal
  state of the callback module and the OS PID of the port process.
  """

  @spec status(pid) :: {String.t, atom, term, integer}

  def status(pid) do
    {:ok, status} = GenServer.call(pid, :status)
    status
  end

  @doc false
  def init([mount_point, fs_mod, fs_opts]) do
    {:ok, port_path} = Userfs.App.find_port!()
    port = Port.open(
      {:spawn, port_path <> " -f " <> mount_point},
      [{:packet, 4}, :nouse_stdio, :exit_status, :binary]
    )
    {:ok, fs_state} = fs_mod.userfs_init(mount_point, fs_opts)
    state = %__MODULE__{
      mount_point: mount_point,
      fs_mod:      fs_mod,
      fs_state:    fs_state,
      port:        port
    }
    {:ok, state}
  end

  def terminate(
    _reason,
    %__MODULE__{
      port_os_pid: nil
    } = _state
  ) do
    :undefined
  end
  def terminate(_reason, state) do
    server_stop_port(state)
    :undefined
  end

  defp port_tx(data, %__MODULE__{port: port} = state) do
    true = Port.command(port, <<@magiccookie::size(32), data::binary>>)
    state
  end

  @spec handle_fusereq(%__MODULE__{}, integer, atom, list, fun) :: %__MODULE__{}

  defp handle_fusereq(
    %__MODULE__{fs_mod: fs_mod, fs_state: fs_state} = state,
    req_code,
    cb_fun,
    cb_args,
    reply_fun
  ) do
    {port_reply, new_fs_state} = case apply(fs_mod, cb_fun, [fs_state|cb_args]) do
      {:ok, reply, new_fs_state} ->
        {<<req_code::size(32), 0::size(32), (reply_fun.(reply))::binary>>, new_fs_state}
      {:error, err_code, new_fs_state} ->
        {<<req_code::size(32), err_code::size(32)>>, new_fs_state}
    end
    port_tx(port_reply, %__MODULE__{state | fs_state: new_fs_state})
  end

  def handle_info(
    {port, {:data, <<@magiccookie::size(32), @request_readdir::size(32), path::binary>>}},
    %__MODULE__{port: port} = state
  ) do
    new_state = handle_fusereq(
      state,
      @request_readdir,
      :userfs_readdir,
      [path],
      fn(reply) ->
        List.foldl(
          reply,
          <<>>,
          fn(e, a) when is_binary(e) -> <<a::binary, e::binary, 0::size(8)>> end
        )
      end
    )
    {:noreply, new_state}
  end

  def handle_info(
    {port, {:data, <<@magiccookie::size(32), @request_getattr::size(32), path::binary>>}},
    %__MODULE__{port: port} = state
  ) do
    new_state = handle_fusereq(
      state, @request_getattr, :userfs_getattr, [path],
      fn({mode, type, size}) when is_integer(mode) and is_integer(type) and is_integer(size) ->
        <<mode::size(32), type::size(32), size::size(32)>>
      end
    )
    {:noreply, new_state}
  end

  def handle_info(
    {port, {:data, <<@magiccookie::size(32), @request_readlink::size(32), path::binary>>}},
    %__MODULE__{port: port} = state
  ) do
    new_state = handle_fusereq(
      state, @request_readlink, :userfs_readlink, [path],
      fn(link_dest) when is_binary(link_dest) -> <<link_dest::binary, 0::size(8)>> end
    )
    {:noreply, new_state}
  end

  def handle_info(
    {port, {:data, <<@magiccookie::size(32), @request_read::size(32), path::binary>>}},
    %__MODULE__{port: port} = state
  ) do
    new_state = handle_fusereq(
      state, @request_read, :userfs_read, [path],
      fn(content) when is_binary(content) -> <<content::binary>> end
    )
    {:noreply, new_state}
  end

  def handle_info(
    {port, {:data, <<@magiccookie::size(32), @status_data::size(32), port_os_pid::size(32)>>}},
    %__MODULE__{phase: :init, port: port} = state
  ) do
    {:noreply, %__MODULE__{state | phase: :ready, port_os_pid: port_os_pid}}
  end

  def handle_info(
    {port, {:data, <<@magiccookie::size(32), @status_data::size(32), port_os_pid::size(32)>>}},
    %__MODULE__{phase: :stopping, port: port} = state
  ) do
    server_stop_port(%{state | port_os_pid: port_os_pid})
    {:noreply, %{state | port_os_pid: nil}}
  end

  def handle_info(
    {port, {:exit_status, 0}},
    %__MODULE__{port: port} = state
  ) do
    {:noreply, server_slow_stop(%{state | port_os_pid: nil}, :normal)}
  end

  def handle_info(
    {port, {:exit_status, 143}},
    %__MODULE__{phase: :stopping, port: port} = state
  ) do
    {:noreply, %{state | port_os_pid: nil}}
  end

  def handle_info(
    {port, {:data, <<@magiccookie::size(32), data::binary>>}},
    %__MODULE__{port: port, port_os_pid: port_os_pid} = state
  ) do
    log_error("ignoring port (PID #{port_os_pid}) unrecognised data #{data} to userfs #{:erlang.pid_to_list(self())}")
    {:noreply, state}
  end

  def handle_info({port, {:data, data}}, %__MODULE__{port: port, port_os_pid: port_os_pid} = state) do
    log_error("port (PID #{port_os_pid}) data #{data} to userfs #{:erlang.pid_to_list(self())} received without correct cookie")
    server_stop_port(state)
    {:noreply, server_slow_stop(state, {:error, "communication with port fatally compromised (bad cookie)"})}
  end

  def handle_info({:stop, {reason, client}}, %__MODULE__{phase: :stopping} = state) do
    GenServer.reply(client, :ok)
    {:stop, reason, state}
  end

  def handle_info({:stop, reason}, %__MODULE__{phase: :stopping} = state) do
    {:stop, reason, state}
  end

  def handle_call(:stop, from, %__MODULE__{phase: :ready} = state) do
    case server_stop_port(state) do
      :unmounted ->
        {:reply, :ok, server_slow_stop(state, :normal)}
      :killed ->
        {:noreply, server_slow_stop(state, {:normal, from})}
    end
  end

  def handle_call(:stop, from, %__MODULE__{phase: :init} = state) do
    {:noreply, server_slow_stop(state, {:normal, from})}
  end

  def handle_call(:status, _from, %__MODULE__{port_os_pid: port_os_pid} = state) do
    status = {
      state.mount_point,
      state.fs_mod,
      state.fs_state,
      port_os_pid
    }
    {:reply, {:ok, status}, state}
  end

  defp server_stop_port(%__MODULE__{mount_point: mount_point, port_os_pid: port_os_pid}) do
    case System.cmd("umount", [mount_point], stderr_to_stdout: true) do
      {_out, 0} ->
        :unmounted
      {_out, _err} ->
        Process.sleep(50)
        System.cmd("kill", ["#{port_os_pid}"], stderr_to_stdout: true)
        Process.sleep(50)
        :killed
    end
  end

  defp server_slow_stop(%__MODULE{phase: phase} = state, _info) when phase === :stopping do
    state
  end
  defp server_slow_stop(state, info) do
    Process.send_after(self(), {:stop, info}, 100 )
    %{state | phase: :stopping}
  end

  defp log_error(msg) do
    :ok = :error_logger.error_msg(String.to_charlist(msg))
  end

end
