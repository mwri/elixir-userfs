defmodule Userfs.ServerTest do

  use ExUnit.Case
  use Userfs.Fs, attribs: true
  import Mock

  describe "server" do

    setup do
      System.cmd("mkdir", ["-p", "/tmp/testfs"])
      pid = with_mocks([
        {TestFs, [], [
            userfs_init: fn(_mp, _opts) -> {:ok, :mock_state} end,
          ]}
      ]) do
        {:ok, pid} = Userfs.mount("/tmp/testfs", TestFs, this: 2, that: 3)
        pid
      end
      on_exit fn ->
        Userfs.umount("/tmp/testfs")
        System.cmd("rmdir", ["/tmp/testfs"])
      end
      {:ok, %{fs_pid: pid}}
    end

    test "status returns mp, mod, state and port PID", %{fs_pid: fs_pid} do
      assert {"/tmp/testfs", TestFs, :mock_state, port_os_pid} = Userfs.Server.status(fs_pid)
      assert is_integer(port_os_pid)
    end

    test "stops on demand and not respanwed", %{fs_pid: fs_pid} do
      assert length(Userfs.list()) == 1
      Userfs.Server.stop(fs_pid)
      assert length(Userfs.list()) == 0
      Process.sleep(50)
      assert length(Userfs.list()) == 0
    end

    test "tries system umount when stop requested", %{fs_pid: fs_pid} do
      {"/tmp/testfs", TestFs, :mock_state, port_os_pid} = Userfs.Server.status(fs_pid)
      with_mocks([
        {System, [:passthrough], [
            cmd: fn("umount", ["/tmp/testfs"], _opts) -> {"error message", 1}
            ("kill", [_pid], _opts) -> {"", 0} end,
          ]}
      ]) do
        Userfs.Server.stop(fs_pid)
        assert called System.cmd("umount", ["/tmp/testfs"], :_)
      end
      System.cmd("kill", ["#{port_os_pid}"], stderr_to_stdout: true)
    end

    test "kills port when umount fails", %{fs_pid: fs_pid} do
      {"/tmp/testfs", TestFs, :mock_state, port_os_pid} = Userfs.Server.status(fs_pid)
      with_mocks([
        {System, [:passthrough], [
            cmd: fn("umount", ["/tmp/testfs"], _opts) -> {"error message", 1}; ("kill", [_pid], _opts) -> {"", 0} end,
          ]}
      ]) do
        Userfs.Server.stop(fs_pid)
        Process.sleep(50)
        assert called System.cmd("kill", [:_], :_)
      end
      System.cmd("kill", ["#{port_os_pid}"], stderr_to_stdout: true)
    end

    test "does not kill port when umount succeeds", %{fs_pid: fs_pid} do
      {"/tmp/testfs", TestFs, :mock_state, port_os_pid} = Userfs.Server.status(fs_pid)
      with_mocks([
        {System, [:passthrough], [
            cmd: fn("umount", ["/tmp/testfs"], _opts) -> {"", 0}; ("kill", [_pid], _opts) -> {"", 0} end,
          ]}
      ]) do
        Userfs.Server.stop(fs_pid)
        Process.sleep(300)
        refute called System.cmd("kill", [port_os_pid], :_)
      end
      System.cmd("kill", ["#{port_os_pid}"], stderr_to_stdout: true)
    end

    test "stops on OS port kill (term) and not respanwed", %{fs_pid: fs_pid} do
      {"/tmp/testfs", TestFs, :mock_state, port_os_pid} = Userfs.Server.status(fs_pid)
      assert length(Userfs.list()) == 1
      System.cmd("kill", ["#{port_os_pid}"])
      Process.sleep(300)
      assert length(Userfs.list()) == 0
    end

    test "logs error when receiving unknown port requests" do
      with_mock :error_logger, [:unstick, :passthrough], [error_msg: fn(_msg) -> :ok end] do
        Userfs.Server.handle_info(
          {self(), {:data, <<@magiccookie::size(32), 1, 2, 3, 4, 5, 6, 7, 8, 9, 0>>}},
          %Userfs.Server{mount_point: "/tmp/testfs", fs_mod: TestFs, phase: :ready, port: self(), port_os_pid: 12345}
        )
        assert called :error_logger.error_msg(:_)
      end
    end

    test "does not die when receiving unknown port requests", %{fs_pid: fs_pid} do
      with_mock :error_logger, [:unstick, :passthrough], [error_msg: fn(_msg) -> :ok end] do
        Userfs.Server.handle_info(
          {self(), {:data, <<@magiccookie::size(32), 1, 2, 3, 4, 5, 6, 7, 8, 9, 0>>}},
          %Userfs.Server{mount_point: "/tmp/testfs", fs_mod: TestFs, phase: :ready, port: self(), port_os_pid: 12345}
        )
        Process.sleep(200)
        assert Process.alive?(fs_pid)
      end
    end

    test "logs error when receiving a bad port request (without correct magic cookie)" do
      with_mock :error_logger, [:unstick, :passthrough], [error_msg: fn(_msg) -> :ok end] do
        Userfs.Server.handle_info(
          {self(), {:data, <<123, @magiccookie::size(32), 1, 2, 3, 4, 5, 6, 7, 8, 9, 0>>}},
          %Userfs.Server{mount_point: "/tmp/testfs", fs_mod: TestFs, phase: :ready, port: self(), port_os_pid: 12345}
        )
        assert called :error_logger.error_msg(:_)
        Process.sleep(200)
      end
    end

    test "dies when receiving a bad port request (without correct magic cookie)", %{fs_pid: fs_pid} do
      with_mocks([
        {:error_logger, [:unstick, :passthrough], [error_msg: fn(_msg) -> :ok end]},
        {Port, [:passthrough], [open: fn(_port_info, _opts) -> self() end]},
      ]) do
        send(fs_pid, {self(), {:data, <<123, @magiccookie::size(32), 1, 2, 3, 4, 5, 6, 7, 8, 9, 0>>}})
        Process.sleep(300)
        refute Process.alive?(fs_pid)
      end
    end

    test "dies and respawns when receiving an unhandled message (normal crash)", %{fs_pid: fs_pid} do
      send(fs_pid, :evil_msg)
      Process.sleep(300)
      refute Process.alive?(fs_pid)
      [{next_fs_pid, {"/tmp/testfs", TestFs, {"/tmp/testfs", _fs_state}, _port_os_pid}}] = Userfs.list()
      assert Process.alive?(next_fs_pid)
    end

  end

end
