defmodule UserfsTest do

  use Userfs.Fs, attribs: true
  use ExUnit.Case
  import Mock

  describe "mount" do

    setup do
      System.cmd("mkdir", ["-p", "/tmp/testfs"])
      on_exit fn ->
        Userfs.umount("/tmp/testfs")
        System.cmd("rmdir", ["/tmp/testfs"])
      end
    end

    test "returns PID of FS" do
      with_mocks([
        {TestFs, [:passthrough], [
            userfs_init: fn(_mp, _opts) -> {:ok, :mock_state} end,
          ]}
      ]) do
        {:ok, pid} = Userfs.mount("/tmp/testfs", TestFs, this: 2, that: 3)
        assert is_pid(pid)
      end
    end

    test "FS init is called" do
      with_mocks([
        {TestFs, [:passthrough], [
            userfs_init: fn(_mp, _opts) -> {:ok, :mock_state} end,
          ]}
      ]) do
        Userfs.mount("/tmp/testfs", TestFs, this: 2, that: 3)
        assert called TestFs.userfs_init("/tmp/testfs", this: 2, that: 3)
      end
    end

  end

  describe "umount" do

    setup do
      System.cmd("mkdir", ["-p", "/tmp/testfs"])
      on_exit fn ->
        System.cmd("rmdir", ["/tmp/testfs"])
      end
    end

    test "returns successful unmount for mounted FS" do
      with_mocks([
        {TestFs, [:passthrough], [
            userfs_init: fn(_mp, _opts) -> {:ok, :mock_state} end,
          ]}
      ]) do
        {:ok, pid} = Userfs.mount("/tmp/testfs", TestFs, this: 2, that: 3)
        assert {:ok, ^pid} = Userfs.umount("/tmp/testfs")
      end
    end

    test "returns error for not mounted FS" do
      assert {:error, :not_mounted} = Userfs.umount("/tmp/testfs")
    end

  end

  describe "list" do

    setup do
      System.cmd("mkdir", ["-p", "/tmp/testfs1", "/tmp/testfs2"])
      on_exit fn ->
        Userfs.umount("/tmp/testfs1")
        Userfs.umount("/tmp/testfs2")
        System.cmd("rmdir", ["/tmp/testfs1", "/tmp/testfs2"])
      end
    end

    test "returns a list of mounted filesystems" do
      with_mocks([
        {TestFs, [:passthrough], [
            userfs_init: fn(_mp, _opts) -> {:ok, :mock_state} end,
          ]}
      ]) do
        {:ok, pid1} = Userfs.mount("/tmp/testfs1", TestFs, this: 2, that: 3)
        assert Userfs.list |> Enum.map(fn({pid,_}) -> pid end) |> Enum.member?(pid1)
        {:ok, pid2} = Userfs.mount("/tmp/testfs2", TestFs, this: 2, that: 3)
        assert Userfs.list |> Enum.map(fn({pid,_}) -> pid end) |> Enum.member?(pid1)
        assert Userfs.list |> Enum.map(fn({pid,_}) -> pid end) |> Enum.member?(pid2)
      end
    end

  end

  describe "readdir" do

    setup do
      System.cmd("mkdir", ["-p", "/tmp/testfs"])
      with_mocks([
        {TestFs, [:passthrough], [
            userfs_init: fn(_mp, _opts) -> {:ok, :mock_state} end,
          ]}
      ]) do
        {:ok, _pid} = Userfs.mount("/tmp/testfs", TestFs, this: 2, that: 3)
      end
      on_exit fn ->
        Userfs.umount("/tmp/testfs")
        System.cmd("rmdir", ["/tmp/testfs"])
      end
    end

    test "FS implementation represented to OS (files returned)" do
      mock_files = ["aaa", "bbb"]
      with_mocks([
        {TestFs, [:passthrough], [
            userfs_getattr: fn(:mock_state, "/") -> {:ok, {0o0755, @attr_dir, 0}, :mock_state} end,
            userfs_readdir: fn(:mock_state, "/") -> {:ok, mock_files, :mock_state} end,
          ]}
      ]) do
        {:ok, ls_files} = File.ls("/tmp/testfs")
        assert called TestFs.userfs_readdir(:mock_state, "/")
        assert mock_files === ls_files
      end
    end

  end

  describe "getattr" do

    setup do
      System.cmd("mkdir", ["-p", "/tmp/testfs"])
      with_mocks([
        {TestFs, [:passthrough], [
            userfs_init: fn(_mp, _opts) -> {:ok, :mock_state} end,
          ]}
      ]) do
        {:ok, _pid} = Userfs.mount("/tmp/testfs", TestFs, this: 2, that: 3)
      end
      on_exit fn ->
        Userfs.umount("/tmp/testfs")
        System.cmd("rmdir", ["/tmp/testfs"])
      end
    end

    test "FS implementation represented to OS (file)" do
      with_mocks([
        {TestFs, [:passthrough], [
            userfs_getattr: fn(:mock_state, "/f") -> {:ok, {0o0644, @attr_file, 10}, :mock_state} end,
          ]}
      ]) do
        {:ok, {mode, size, type}} = os_stat("/tmp/testfs/f")
        assert called TestFs.userfs_getattr(:mock_state, "/f")
        assert mode === 0o0644
        assert type === :file
        assert size === 10
      end
    end

    test "FS implementation represented to OS (directory)" do
      with_mocks([
        {TestFs, [:passthrough], [
            userfs_getattr: fn(:mock_state, "/d") -> {:ok, {0o0755, @attr_dir, 0}, :mock_state} end,
          ]}
      ]) do
        {:ok, {mode, _size, type}} = os_stat("/tmp/testfs/d")
        assert called TestFs.userfs_getattr(:mock_state, "/d")
        assert mode === 0o0755
        assert type === :dir
      end
    end

    test "FS implementation represented to OS (symlink)" do
      with_mocks([
        {TestFs, [:passthrough], [
            userfs_getattr: fn(:mock_state, "/s") -> {:ok, {0o0555, @attr_symlink, 20}, :mock_state} end,
          ]}
      ]) do
        {:ok, {mode, size, type}} = os_stat("/tmp/testfs/s")
        assert called TestFs.userfs_getattr(:mock_state, "/s")
        assert mode === 0o0555
        assert size === 20
        assert type === :symlink
      end
    end

    test "FS implementation represented to OS (noent error)" do
      with_mocks([
        {TestFs, [:passthrough], [
            userfs_getattr: fn(:mock_state, "/e") -> {:error, @error_noent, :mock_state} end,
          ]}
      ]) do
        {:error, :enoent} = os_stat("/tmp/testfs/e")
        assert called TestFs.userfs_getattr(:mock_state, "/e")
      end
    end

  end

  describe "read" do

    setup do
      System.cmd("mkdir", ["-p", "/tmp/testfs"])
      with_mocks([
        {TestFs, [:passthrough], [
            userfs_init: fn(_mp, _opts) -> {:ok, :mock_state} end,
          ]}
      ]) do
        {:ok, _pid} = Userfs.mount("/tmp/testfs", TestFs, this: 2, that: 3)
      end
      on_exit fn ->
        Userfs.umount("/tmp/testfs")
        System.cmd("rmdir", ["/tmp/testfs"])
      end
    end

    test "FS implementation represented to OS" do
      mock_content = "abcdefghijklmnopqrstuvwxyz0123456789"
      with_mocks([
        {TestFs, [:passthrough], [
            userfs_getattr: fn(:mock_state, "/f") -> {:ok, {0o0644, @attr_file, byte_size(mock_content)}, :mock_state} end,
            userfs_read: fn(:mock_state, "/f") -> {:ok, mock_content, :mock_state} end,
          ]}
      ]) do
        {:ok, ^mock_content} = File.read("/tmp/testfs/f")
        assert called TestFs.userfs_read(:mock_state, "/f")
      end
    end

  end

  describe "linkread" do

    setup do
      System.cmd("mkdir", ["-p", "/tmp/testfs"])
      with_mocks([
        {TestFs, [:passthrough], [
            userfs_init: fn(_mp, _opts) -> {:ok, :mock_state} end,
          ]}
      ]) do
        {:ok, _pid} = Userfs.mount("/tmp/testfs", TestFs, this: 2, that: 3)
      end
      on_exit fn ->
        Userfs.umount("/tmp/testfs")
        System.cmd("rmdir", ["/tmp/testfs"])
      end
    end

    test "FS implementation represented to OS" do
      mock_linkcontent = "/tmp/testfs/f"
      with_mocks([
        {TestFs, [:passthrough], [
            userfs_getattr: fn(:mock_state, "/s") -> {:ok, {0o0644, @attr_symlink, byte_size(mock_linkcontent)}, :mock_state} end,
            userfs_readlink: fn(:mock_state, "/s") -> {:ok, mock_linkcontent, :mock_state} end,
          ]}
      ]) do
        {:ok, ^mock_linkcontent} = File.read_link("/tmp/testfs/s")
        assert called TestFs.userfs_readlink(:mock_state, "/s")
      end
    end

  end

  # File.stat is not very good; hides sylinks, no proper access

  def os_stat (path) do
    case System.cmd("stat", ["-c", "%a %s %F", path], stderr_to_stdout: true) do
      {_out, 1} ->
        {:error, :enoent}
      {out, 0} ->
        out = String.trim(out, "\n")
        [txt_mode, txt_size, txt_type] = String.split(out, " ", parts: 3)
        mode = String.to_integer(txt_mode, 8)
        size = String.to_integer(txt_size)
        type = case txt_type do
          "regular file" -> :file
          "regular empty file" -> :file
          "directory" -> :dir
          "symbolic link" -> :symlink
        end
        {:ok, {mode, size, type}}
    end
  end

end
