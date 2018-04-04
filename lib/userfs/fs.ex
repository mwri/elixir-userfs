defmodule Userfs.Fs do

  @moduledoc """
  To implement a filesystem a callback module must be created which implements
  five methods.

  The first method is called immediately before the filesystem becomes
  mounted. Two arguments are passed to it, the mount point and the options, or
  configuration, which was passed as argument three to `Userfs.mount/3`. The
  return value should be `{:ok, state}`, where `state` is the state of the FS
  which will be passed to all subsequent callbacks. If `{:error, reason}` is
  returned instead then this is considered an error.

  The remaining four callbacks are the interesting ones, and by their responses
  the FS is implemented.

  First `userfs_readdir/2` determines the contents of a directory. It is called
  with two arguments, the FS state (as returned by `init`) and the path of the
  directory to be read. The response should either be `{:error, @error_noent}`
  if the directory to be read does not exist, or `{:ok, ents, state}`
  where `ents` is a list of filenames.

  For example, in the `Userfs.Fs.Hello` hello world filesystem, the
  `userfs_readdir/2` callback is implemented like this:

      def userfs_readdir(state, "/") do
        {:ok, ["hello", "world"], state}
      end
      def userfs_readdir(state, _path) do
        {:error, @error_noent, state}
      end

  This means this FS has two entities "hello" and "world" in the root.

  These two entities could be files, directories or symlinks at this point.
  For the OS to determine which, the `userfs_getattr/2` callback must be
  implemented. Again the two arguments are the FS state and the path of the
  entity being queried. The response, if not an error, should either be
  `{:ok, {mode, type, size}, state}`, where `mode` is the permissions mode
  of the entity (UNIX octal representation of global, group and owner
  access, frequently 0755 or 0644), `type` is one of `@attr_dir`, `@attr_file`
  or `@attr_symlink`, and `size` is the data size of the entity (the number
  of bytes of data if it is a file, or the length of the destination filename
  if it is a symbolic link.

  The `Userfs.Fs.Hello` filesystem implements the `userfs_getattr/2` callback
  like this:

      def userfs_getattr(state, "/") do
        {:ok, {0o0755, @attr_dir, 0}, state}
      end
      def userfs_getattr(state, "/hello") do
        {:ok, {0o0644, @attr_file, byte_size("Hello world!\\n")}, state}
      end
      def userfs_getattr(state, "/world") do
        {:ok, {0o0755, @attr_symlink, byte_size("hello")}, state}
      end

  Clearly the root directory is a directory, the only one in this FS, there
  is one file, and one symlink pointing to it.

  Between `userfs_readdir/2` and `userfs_getattr/2` the filesystem hierachy
  is entirely established.

  Two callbacks remain, `userfs_readlink/2` is for reading the destination
  filename of a symbolic link, and simply returns the destination, like this
  in the `Userfs.Fs.Hello` hello world filesystem:

      def userfs_readlink(state, "/world") do
        {:ok, "hello", state}
      end
      def userfs_readlink(state, _) do
        {:error, @error_noent, state}
      end

  And finally `userfs_read/2` returns the contents of a file, like this in
  the `Userfs.Fs.Hello` hello world filesystem:

      def userfs_read(state, "/hello") do
        {:ok, "Hello world!\\n", state}
      end
      def userfs_read(state, _) do
        {:error, @error_noent, state}
      end
  """

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      is_fs = opts[:is_fs]
      import_attribs = opts[:attribs]
      if (is_fs === nil and import_attribs === nil) or is_fs do
        @behaviour Userfs.Fs
      end
      if import_attribs === nil or import_attribs do
        @error_noent  :userfs_defs.error_noent()
        @status_data    :userfs_defs.status_data()
        @request_readdir :userfs_defs.request_readdir()
        @request_getattr  :userfs_defs.request_getattr()
        @request_readlink :userfs_defs.request_readlink()
        @request_read     :userfs_defs.request_read()
        @attr_dir        :userfs_defs.attr_dir()
        @attr_file      :userfs_defs.attr_file()
        @attr_symlink  :userfs_defs.attr_symlink()
        @magiccookie :userfs_defs.magiccookie()
      end
    end
  end

  @callback userfs_init(String.t, term) :: {:ok, term} | {:error, term}
  @callback userfs_readdir(term, String.t) :: {:ok, [binary], term} | {:error, integer}
  @callback userfs_getattr(term, String.t) :: {:ok, {Userfs.mode, Userfs.type, integer}, term} | {:error, integer}
  @callback userfs_readlink(term, String.t) :: {:ok, binary, term} | {:error, integer}
  @callback userfs_read(term, String.t) :: {:ok, binary, term} | {:error, integer}

end
