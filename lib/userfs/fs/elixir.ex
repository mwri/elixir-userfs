defmodule Userfs.Fs.Elixir do

  @moduledoc """
  A UserFs filesystem implementation callback module which makes
  available common data from the Elixir run time.

  The actual implementation of a callback module can of course be achieved
  in a variety of ways. Here the callbacks break down the file path into
  leaves and the traverse/4 function works through them to find the end
  of the path. If the traversal is succesful, a function to deal with the
  request is invoked (for example, the get attributes filesystem function
  is resolved by a call to userfs_getattr/2.

  The traverse/4 function verifies each element of the path as it is
  called. This is necessary because it is no use continuing past the
  pids/&lt;0.63.0> point if PID &lt;0.63.0> does not exist! The first two
  parameters to traverse/4 are passed on and through so they are
  available when the traversal finishes, the third parameter is the
  context in which to evaluate the next path element (for example
  traversing the "pids" directory results in the context being
  'all_pids', and the element after that is {pid, Pid}, enabling, for
  example, the read directory callback, if it is invoked at that
  point, to enumerate all objects that are inside a PID.

  See 'Userfs.Fs.Example' for a simpler example of a filesystem, or the
  most simple 'hello world' 'Userfs.Fs.Hello' that shows the callbacks
  and how they must be implemented most simply of all.
  """

  use Userfs.Fs

  defstruct mount_point: nil

  def userfs_init(mount_point, _opts) do
    {:ok, %__MODULE__{mount_point: mount_point}}
  end

  def userfs_readdir(state, "/"<>path) do
    path_leaves = String.split(path, "/", parts: :infinity)
    traverse(state, :elixirfs_readdir, :root, path_leaves)
  end

  def userfs_getattr(state, "/"<>path) do
    path_leaves = String.split(path, "/", parts: :infinity)
    traverse(state, :elixirfs_getattr, :root, path_leaves)
  end

  def userfs_readlink(state, "/"<>path) do
    path_leaves = String.split(path, "/", parts: :infinity)
    traverse(state, :elixirfs_readlink, :root, path_leaves)
  end

  def userfs_read(state, "/"<>path) do
    path_leaves = String.split(path, "/", parts: :infinity)
    traverse(state, :elixirfs_read, :root, path_leaves)
  end

  defp traverse(state, request, :root, [""]) do
    apply(__MODULE__, request, [state, :root])
  end
  defp traverse(state, request, :root, ["pids"|more]) do
    traverse(state, request, :all_pids, more)
  end
  defp traverse(state, request, :all_pids, []) do
    apply(__MODULE__, request, [state, :all_pids])
  end
  defp traverse(state, request, :all_pids, ["#PID"<>pid|more]) do
    traverse(state, request, {:pid, :erlang.list_to_pid(String.to_charlist(pid))}, more)
  end
  defp traverse(state, request, {:pid, pid}, []) do
    apply(__MODULE__, request, [state, {:pid, pid}])
  end
  defp traverse(state, request, :root, ["names"|more]) do
    traverse(state, request, :names, more)
  end
  defp traverse(state, request, :names, []) do
    apply(__MODULE__, request, [state, :names])
  end
  defp traverse(state, request, :names, ["local"|more]) do
    traverse(state, request, :local_names, more)
  end
  defp traverse(state, request, :local_names, []) do
    apply(__MODULE__, request, [state, :local_names])
  end
  defp traverse(state, request, :local_names, [name|more]) do
    traverse(state, request, {:local_name, String.to_atom(name)}, more)
  end
  defp traverse(state, request, {:local_name, name}, []) do
    apply(__MODULE__, request, [state, {:local_name, name}])
  end
  defp traverse(state, request, :names, ["global"|more]) do
    traverse(state, request, :global_names, more)
  end
  defp traverse(state, request, :global_names, []) do
    apply(__MODULE__, request, [state, :global_names])
  end
  defp traverse(state, request, :global_names, [name|more]) do
    traverse(state, request, {:global_name, String.to_atom(name)}, more)
  end
  defp traverse(state, request, {:global_name, name}, []) do
    apply(__MODULE__, request, [state, {:global_name, name}])
  end
  defp traverse(state, request, {:pid, pid}, ["process_info"|more]) do
    traverse(state, request, {:proc_info, pid}, more)
  end
  defp traverse(state, request, {:proc_info, pid}, []) do
    apply(__MODULE__, request, [state, {:proc_info, pid}])
  end
  defp traverse(state, request, {:proc_info, pid}, [item_spec]) do
    apply(__MODULE__, request, [state, {:proc_info, pid, String.to_atom(item_spec)}])
  end
  defp traverse(state, request, {:pid, pid}, ["linked"|more]) do
    traverse(state, request, {:link_from, pid}, more)
  end
  defp traverse(state, request, {:link_from, pid}, []) do
    apply(__MODULE__, request, [state, {:link_from, pid}])
  end
  defp traverse(state, request, {:link_from, _pid}, ["#PID"<>linked_pid]) do
    apply(__MODULE__, request, [state, {:link_to, :erlang.list_to_pid(String.to_charlist(linked_pid))}])
  end
  defp traverse(state, request, :root, ["nodes"|more]) do
    traverse(state, request, :nodes, more)
  end
  defp traverse(state, request, :nodes, []) do
    apply(__MODULE__, request, [state, :nodes])
  end
  defp traverse(state, request, :nodes, [node]) do
    apply(__MODULE__, request, [state, {:node, String.to_atom(node)}])
  end
  defp traverse(state, request, :root, ["apps"|more]) do
    traverse(state, request, :apps, more)
  end
  defp traverse(state, request, :apps, []) do
    apply(__MODULE__, request, [state, :apps])
  end
  defp traverse(state, request, :apps, [name|more]) do
    traverse(state, request, {:app, String.to_atom(name)}, more)
  end
  defp traverse(state, request, {:app, app}, []) do
    apply(__MODULE__, request, [state, {:app, app}])
  end
  defp traverse(state, request, {:app, app}, [app_sub_dir|more]) do
    traverse(state, request, {:app, app, app_sub_dir}, more)
  end
  defp traverse(state, request, {:app, app, app_sub_dir}, []) do
    apply(__MODULE__, request, [state, {:app, app, app_sub_dir}])
  end
  defp traverse(state, request, {:app, app, "env"}, [opt]) do
    apply(__MODULE__, request, [state, {:app_env, app, String.to_atom(opt)}])
  end
  defp traverse(state, request, :root, ["code"|more]) do
    traverse(state, request, :code, more)
  end
  defp traverse(state, request, :code, []) do
    apply(__MODULE__, request, [state, :code])
  end
  defp traverse(state, request, :code, ["modules"|more]) do
    traverse(state, request, {:code, :modules}, more)
  end
  defp traverse(state, request, {:code, :modules}, []) do
    apply(__MODULE__, request, [state, {:code, :modules}])
  end
  defp traverse(state, request, {:code, :modules}, [module|more]) do
    traverse(state, request, {:code, :module, String.to_atom(module)}, more)
  end
  defp traverse(state, request, {code, :module, module}, []) do
    apply(__MODULE__, request, [state, {code, :module, module}])
  end
  defp traverse(state, request, {code, :module, module}, ["file"]) do
    apply(__MODULE__, request, [state, {code, :module, module, :file}])
  end
  defp traverse(state, _, _, _) do
    {:error, @error_noent, state}
  end

  def elixirfs_readdir(state, :root) do
    {:ok, ["pids", "names", "nodes", "apps", "code"], state}
  end
  def elixirfs_readdir(state, :all_pids) do
    readdir = for p when is_pid(p) <- Process.list(), do: "#PID"<>:erlang.list_to_binary(:erlang.pid_to_list(p))
    {:ok, readdir, state}
  end
  def elixirfs_readdir(state, :names) do
    {:ok, ["local", "global"], state}
  end
  def elixirfs_readdir(state, :local_names) do
    local_names = for n <- Process.registered(), do: "#{n}"
    {:ok, local_names, state}
  end
  def elixirfs_readdir(state, :global_names) do
    global_names = for n <- :global.registered_names(), do: "#{n}"
    {:ok, global_names, state}
  end
  def elixirfs_readdir(state, {:pid, _pid}) do
    {:ok, ["process_info", "linked"], state}
  end
  def elixirfs_readdir(state, {:proc_info, pid}) do
    proc_info = for {k, _} <- Process.info(pid), do: "#{k}"
    {:ok, proc_info, state}
  end
  def elixirfs_readdir(state, {:link_from, pid}) do
    {:links, linked} = Process.info(pid, :links)
    readdir = for p when is_pid(p) <- linked, do: "#PID" <> :erlang.list_to_binary(:erlang.pid_to_list(p))
    {:ok, readdir, state}
  end
  def elixirfs_readdir(state, :nodes) do
    readdir = for n <- [node()|Node.list()], do: "#{n}"
    {:ok, readdir, state}
  end
  def elixirfs_readdir(state, {:node, _node}) do
    {:ok, [], state}
  end
  def elixirfs_readdir(state, :apps) do
    {:ok, (for {n,_} <- running_apps(), do: "#{n}"), state}
  end
  def elixirfs_readdir(state, {:app, app}) do
    [app_pid] = for {n, p} when n == app <- running_apps(), do: p
    if app_pid === :undefined do
      {:ok, ["descr", "vsn", "env"], state}
    else
      {:ok, ["app_proc", "top_sup", "descr", "vsn", "env"], state}
    end
  end
  def elixirfs_readdir(state, {:app, app, "env"}) do
    {:ok, (for {opt, _val} <- Application.get_all_env(app), do: "#{opt}"), state}
  end
  def elixirfs_readdir(state, :code) do
    {:ok, ["modules"], state}
  end
  def elixirfs_readdir(state, {:code, :modules}) do
    {:ok, (for {m, _file} <- :code.all_loaded(), do: "#{m}"), state}
  end
  def elixirfs_readdir(state, {:code, :module, _module}) do
    {:ok, ["file"], state}
  end

  def elixirfs_getattr(state, :root) do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def elixirfs_getattr(state, :all_pids) do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def elixirfs_getattr(state, :names) do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def elixirfs_getattr(state, :local_names) do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def elixirfs_getattr(state, :global_names) do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def elixirfs_getattr(state, {:local_name, _name}) do
    {:ok, {0o0755, @attr_symlink, 0}, state}
  end
  def elixirfs_getattr(state, {:global_name, _name}) do
    {:ok, {0o0755, @attr_symlink, 0}, state}
  end
  def elixirfs_getattr(state, {:pid, _pid}) do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def elixirfs_getattr(state, {:proc_info, _pid}) do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def elixirfs_getattr(state, {:proc_info, pid, item_spec}) do
    {:ok, {0o0644, @attr_file, file_size(state, {:proc_info, pid, item_spec})}, state}
  end
  def elixirfs_getattr(state, :nodes) do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def elixirfs_getattr(state, {:node, _Node}) do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def elixirfs_getattr(state, :apps) do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def elixirfs_getattr(state, {:app, _name}) do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def elixirfs_getattr(state, {:app, app, app_sub_dir}) do
    attrs = case app_sub_dir do
      "app_proc" -> {0o0755, @attr_symlink, 0}
      "top_sup" -> {0o0755, @attr_symlink, 0}
      "descr" -> {0o0644, @attr_file, file_size(state, {:app, app, app_sub_dir})}
      "vsn" -> {0o0644, @attr_file, file_size(state, {:app, app, app_sub_dir})}
      "env" -> {0o0755, @attr_dir, 0}
    end
    {:ok, attrs, state}
  end
  def elixirfs_getattr(state, {:app_env, app, opt}) do
    {:ok, {0o0644, @attr_file, file_size(state, {:app_env, app, opt})}, state}
  end
  def elixirfs_getattr(state, {:link_from, _pid}) do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def elixirfs_getattr(state, {:link_to, _linked_pid}) do
    {:ok, {0o0755, @attr_symlink, 0}, state}
  end
  def elixirfs_getattr(state, :code) do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def elixirfs_getattr(state, {:code, :modules}) do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def elixirfs_getattr(state, {:code, :module, _Module}) do
    {:ok, {0o0755, @attr_dir, 0}, state}
  end
  def elixirfs_getattr(state, {:code, :module, module, :file}) do
    {:ok, {0o0644, @attr_file, file_size(state, {:code, :module, module, :file})}, state}
  end

  def elixirfs_readlink(state, {:local_name, name}) do
    pid = Process.whereis(name)
    dest = state.mount_point <> "/pids/#PID" <> :erlang.list_to_binary(:erlang.pid_to_list(pid))
    {:ok, dest, state}
  end
  def elixirfs_readlink(state, {:app, app, "app_proc"}) do
    [app_pid] = for {n, p} when n == app <- running_apps(), do: p
    dest = state.mount_point <> "/pids/#PID" <> :erlang.list_to_binary(:erlang.pid_to_list(app_pid))
    {:ok, dest, state}
  end
  def elixirfs_readlink(state, {:app, app, "top_sup"}) do
    [app_pid] = for {n, p} when n == app <- running_apps(), do: p
    {sup_pid, _mod} = :application_master.get_child(app_pid)
    dest = state.mount_point <> "/pids/#PID" <> :erlang.list_to_binary(:erlang.pid_to_list(sup_pid))
    {:ok, dest, state}
  end
  def elixirfs_readlink(state, {:link_to, linked_pid}) do
    dest = state.mount_point <> "/pids/#PID" <> :erlang.list_to_binary(:erlang.pid_to_list(linked_pid))
    {:ok, dest, state}
  end

  def elixirfs_read(state, {:proc_info, pid, item_spec}) do
    {^item_spec, item_data} = Process.info(pid, item_spec)
    content = inspect(item_data, pretty: true) <> "\n"
    {:ok, content, state}
  end
  def elixirfs_read(state, {:app, app, "descr"}) do
    [descr] = for {n, d, _vsn} when n == app <- loaded_apps(), do: d
    content = "#{descr}\n"
    {:ok, content, state}
  end
  def elixirfs_read(state, {:app, app, "vsn"}) do
    [vsn] = for {n, _descr, v} when n === app <- loaded_apps(), do: v
    content = "#{vsn}\n"
    {:ok, content, state}
  end
  def elixirfs_read(state, {:app_env, app, opt}) do
    val = Application.get_env(app, opt)
    content = inspect(val, pretty: true) <> "\n"
    {:ok, content, state}
  end
  def elixirfs_read(state, {:code, :module, module, :file}) do
    {:ok, "#{:code.which(module)}\n", state}
  end

  defp file_size(state, context) do
    {:ok, content, _state} = elixirfs_read(state, context)
    byte_size(content)
  end

  defp loaded_apps() do
    :application_controller.info()[:loaded]
  end

  defp running_apps() do
    :application_controller.info()[:running]
  end

end
