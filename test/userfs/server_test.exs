defmodule Userfs.ServerTest do

  use ExUnit.Case
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
        Process.sleep(50)
        pid
      end
      on_exit fn ->
        Userfs.umount("/tmp/testfs")
        System.cmd("rmdir", ["/tmp/testfs"])
      end
      {:ok, %{fs_pid: pid}}
    end

    test "status returns mp, mod, state and port PID", %{fs_pid: fs_pid} do
      assert {"/tmp/testfs", TestFs, :mock_state, os_port_pid} = Userfs.Server.status(fs_pid)
      assert is_integer(os_port_pid)
    end

    test "stops on demand and not respanwed", %{fs_pid: fs_pid} do
      assert length(Userfs.list()) == 1
      Userfs.Server.stop(fs_pid)
      assert length(Userfs.list()) == 0
      Process.sleep(200)
      assert length(Userfs.list()) == 0
    end

    test "stops on OS port kill (term) and not respanwed", %{fs_pid: fs_pid} do
      {"/tmp/testfs", TestFs, :mock_state, os_port_pid} = Userfs.Server.status(fs_pid)
      assert length(Userfs.list()) == 1
      System.cmd("kill", ["#{os_port_pid}"])
      Process.sleep(200)
      assert length(Userfs.list()) == 0
    end

  end

end
