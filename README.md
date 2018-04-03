# userfs [![Build Status](https://travis-ci.org/mwri/elixir-userfs.svg?branch=master)](https://travis-ci.org/mwri/elixir-userfs) [![Coverage Status](https://coveralls.io/repos/github/mwri/elixir-userfs/badge.svg?branch=master)](https://coveralls.io/github/mwri/elixir-userfs?branch=master)

This is an Elixir FUSE (Filesystem in Userspace) interface. You can use
it to create additional file structure in your filesystem, defined in
Elixir.

To do so, you must to write an implementation module (a module that
implements the 'Userfs.Fs' behaviour). All this really involves is
answering FUSE's questions about your files, for example fuse asks
you what files are in a given directory and you return a list of
names, or fuse asks you what a given file is, and you reply that
it is a file with N bytes of content, P permissions, etc.

## Example filesystems

Three example file system come with the `userfs` app for you to peruse.

### Userfs.Fs.Hello

More or less the simplest possible case, it has a file and a sym
link in the root directory.

### Userfs.Fs.Example

Not a lot more interesting than `Userfs.Fs.Hello` but with some more
objects.

### Userfs.Fs.Elixir

Much more interesting, more than just a static set of
objects, necessitating a more creative implementation. This
filesystem allows access to aspects of Elixir's run time state
via the filesystem (for example, in the "pids" directory you
will find a directory for every process currently running.

To try out the example 'Elixir FS' filesystem create a mount
point, "/tmp/elixirfs" say, start the `userfs` app, and mount the
FS like this:

```elixir
iex> userfs.mount("/tmp/elixirfs", Userfs.Fs.Elixir, [])
{:ok, #PID<0.40.0>}
```

Now, look inside the /tmp/elixirfs directory and you should find
it populated.

The best and cleanest way to unmount the filesystem is to run
the OS 'umount' shell command, but you can unmount the filesystem
like this:

```elixir
iex> Userfs.umount("/tmp/elixirfs")
{:ok, {:stopping, #PID<0.40.0>}}
```

Your filesystem experience should then be something like this:

```
$ cd /tmp/elixirfs/
$ ls -l
total 0
drwxr-xr-x 2 root root 0 Jan  1  1970 apps
drwxr-xr-x 2 root root 0 Jan  1  1970 code
drwxr-xr-x 2 root root 0 Jan  1  1970 names
drwxr-xr-x 2 root root 0 Jan  1  1970 nodes
drwxr-xr-x 2 root root 0 Jan  1  1970 pids
$ ls -l apps
total 0
drwxr-xr-x 2 root root 0 Jan  1  1970 userfs
drwxr-xr-x 2 root root 0 Jan  1  1970 kernel
drwxr-xr-x 2 root root 0 Jan  1  1970 stdlib
$ ls -l apps/userfs/
total 0
lrwxr-xr-x 1 root root  0 Jan  1  1970 app_proc -> /tmp/elixirfs/pids/<0.36.0>
-rw-r--r-- 1 root root 38 Jan  1  1970 descr
drwxr-xr-x 2 root root  0 Jan  1  1970 env
lrwxr-xr-x 1 root root  0 Jan  1  1970 top_sup -> /tmp/elixirfs/pids/<0.38.0>
-rw-r--r-- 1 root root  6 Jan  1  1970 vsn
$ cat apps/userfs/descr
Erlang FUSE (Filesystem in Userspace)
$ ls -l apps/userfs/app_proc/
total 0
drwxr-xr-x 2 root root 0 Jan  1  1970 linked
drwxr-xr-x 2 root root 0 Jan  1  1970 process_info
$ ls -l apps/userfs/app_proc/linked/
total 0
lrwxr-xr-x 1 root root 0 Jan  1  1970 <0.37.0> -> /tmp/elixirfs/pids/<0.37.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 <0.7.0> -> /tmp/elixirfs/pids/<0.7.0>
$ cat code/modules/userfs/file
/home/mjw/dev/erlang/userfs-1.0.0/ebin/userfs.beam
$ ls -l names/local/
total 0
lrwxr-xr-x 1 root root 0 Jan  1  1970 application_controller -> /tmp/elixirfs/pids/<0.7.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 code_server -> /tmp/elixirfs/pids/<0.20.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 userfs_mount_sup -> /tmp/elixirfs/pids/<0.39.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 userfs_sup -> /tmp/elixirfs/pids/<0.38.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 erl_prim_loader -> /tmp/elixirfs/pids/<0.3.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 error_logger -> /tmp/elixirfs/pids/<0.6.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 file_server_2 -> /tmp/elixirfs/pids/<0.19.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 global_group -> /tmp/elixirfs/pids/<0.18.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 global_name_server -> /tmp/elixirfs/pids/<0.13.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 inet_db -> /tmp/elixirfs/pids/<0.16.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 init -> /tmp/elixirfs/pids/<0.0.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 kernel_safe_sup -> /tmp/elixirfs/pids/<0.29.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 kernel_sup -> /tmp/elixirfs/pids/<0.11.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 rex -> /tmp/elixirfs/pids/<0.12.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 standard_error -> /tmp/elixirfs/pids/<0.22.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 standard_error_sup -> /tmp/elixirfs/pids/<0.21.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 user -> /tmp/elixirfs/pids/<0.25.0>
lrwxr-xr-x 1 root root 0 Jan  1  1970 user_drv -> /tmp/elixirfs/pids/<0.24.0>
$ ls -la pids/\<0.41.0\>/process_info/
total 0
drwxr-xr-x 2 root root  0 Jan  1  1970 .
drwxr-xr-x 2 root root  0 Jan  1  1970 ..
-rw-r--r-- 1 root root 33 Jan  1  1970 current_function
-rw-r--r-- 1 root root 74 Jan  1  1970 dictionary
-rw-r--r-- 1 root root 14 Jan  1  1970 error_handler
-rw-r--r-- 1 root root 93 Jan  1  1970 garbage_collection
-rw-r--r-- 1 root root  9 Jan  1  1970 group_leader
-rw-r--r-- 1 root root  4 Jan  1  1970 heap_size
-rw-r--r-- 1 root root 20 Jan  1  1970 initial_call
-rw-r--r-- 1 root root 19 Jan  1  1970 links
-rw-r--r-- 1 root root  2 Jan  1  1970 message_queue_len
-rw-r--r-- 1 root root  3 Jan  1  1970 messages
-rw-r--r-- 1 root root  7 Jan  1  1970 priority
-rw-r--r-- 1 root root  4 Jan  1  1970 reductions
-rw-r--r-- 1 root root  2 Jan  1  1970 stack_size
-rw-r--r-- 1 root root  8 Jan  1  1970 status
-rw-r--r-- 1 root root  3 Jan  1  1970 suspending
-rw-r--r-- 1 root root  4 Jan  1  1970 total_heap_size
-rw-r--r-- 1 root root  5 Jan  1  1970 trap_exit
$ cat pids/\<0.41.0\>/process_info/garbage_collection
[{min_bin_vheap_size,46422},
 {min_heap_size,233},
 {fullsweep_after,65535},
 {minor_gcs,1}]
$
```

## Supervision behaviour

Filesystems, once mounted, are supervised, so a crash should result in a
reinstatement. Since a filesystem can be terminated in a normal way though
you should be aware that this might not be true for every circumstance.

As you might expect, if you unmount the file system by calling `Userfs.umount/1`
the filesystem will be unmounted and not reinstated.

An OS umount call made by a system administrator, from the shell or by
other means, will also cause the filesystem to be unmounted and not reinstated.
This is less clear, but some cooperation is obviously necessary between `userfs`
and the OS, and it seems a bit unfair on the system administrator if the
execution of a perfectly normal and deliberate activity is frustrated.

More controversial, if you kill the port process from the system with a TERM
signal, the filesystem is also not reinstated. However a request to TERMinate
is still an administrative action ultimately.

If the port receives a signal which is not obviously administrative, or it
crashes, then the supervisor (userfs_fs_sup) will reinstate the filesystem.
You can kill the port with signal 9 to invoke this action.

## Writing your own userfs implementation module

Any filesystem callback implementation should `use` the `Userfs.Fs` module:

```elixir
use Userfs.Fs
```

This will require the filesystem behaviour and import the attributes.

Your module's `userfs_init/2` function will be called when the filesystem is
mounted, it receives the mount point and the options/config (the third
parameter passed to `Userfs.mount/3`) as parameters, and returns `{:ok, state}`
where `state` is passed subsequently to the other FS callbacks. None of the
example filesystems use this state but some filesystems wll require it.

Next, when you list the files in a directory in your filesystem
`userfs_readdir/2` will be called. Obviously the first call is likely to be
for the root of your filesystem, and `Userfs.Fs.Hello` handles this as follows:

```elixir
def userfs_readdir(state, "/") do
  {:ok, ["hello", "world"], state}
end
def userfs_readdir(state, _) do
  {:error, @error_noent, state}
end
```

Since there are no directories in this filesystem apart from the root, it's
quite simple, if it's the root it returns a list of two objects, and if
not it returns a `@error_noent` error (note this is really a soft error
for the end user, **noent** is POSIX speak for no entity). The return list, as
you can see, is a list of strings/binaries.

As soon as the user does something like `ls -l` instead of just `ls`, the
file system will suddenly have to answer details such as what type of
objects 'hello' and 'world' are, and for this your callback module will
receive a `userfs_getattr/2` call. Here is the `userfs_hellofs`
implementation:

```elixir
def userfs_getattr(state, "/") do
  {:ok, {0o0755, @attr_dir, 0}, state}
end
def userfs_getattr(state, "/hello") do
  {:ok, {0o0644, @attr_file, byte_size("Hello world!\n")}, state}
end
def userfs_getattr(state, "/world") do
  {:ok, {0o0755, @attr_symlink, String.length("hello")}, state}
end
def userfs_getattr(state, _) do
  {:error, @error_noent, state}
end
```

Our filesystem has three objects in it in total, the root directory, a
file and a symbolic link, and the `userfs_getattr` function matches
each individually and returns a response `{ok, {perms, type, size}}`.
The permissions is the octal value you can use with UNIX's chmod, the
type is directory, file or sym link (use the attributes, as above)
and the size, for files is the length of the content, and for sym
links is the length of the path.

Anything else gets the not found response.

When a file is read, the content must be provided. There is just
one file in this case and `userfs_getattr` is implementated like so:

```elixir
def userfs_read(state, "/hello") do
  {:ok, "Hello world!\n", state}
end
def userfs_read(state, _) do
  {:error, @error_noent, state}
end
```

So that the destination of the sym link can be found, the
`userfs_readlink/2` is implemented:

```elixir
def userfs_readlink(state, "/world") do
  {:ok, "hello", state}
end
def userfs_readlink(state, _) do
  {:error, @error_noent, state}
end
```

## Licensing

Copyright 2018 Michael Wright <mjw@methodanalysis.com>

'userfs' is free software, you can redistribute it and/or modify
it under the terms of the MIT license.
